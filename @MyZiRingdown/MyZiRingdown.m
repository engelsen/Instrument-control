% Class for performing ringdown measurements of mechanical oscillators
% using Zurich Instruments UHF or MF lock-in.
%
% Operation: sweep the driving tone (drive_osc) using the sweep module 
% in LabOne web user interface, when the magnitude of the demodulator 
% signal exceeds trig_threshold the driving tone is switched off and 
% the recording of demodulated signal is started, the signal is recorded 
% for the duration of record_time.
% 
% Features:
%
% Adaptive measurement oscillator frequency
%
% Averaging
%
% Auto saving
%
% Auxiliary output signal: If enable_aux_out=true 
% then after a ringdown is started a sequence of pulses is applied
% to the output consisting of itermittent on and off periods
% starting from on. 

classdef MyZiRingdown < MyZiLockIn & MyDataSource
    
    properties (Access = public, SetObservable = true)
        
        % Ringdown is recorded if the signal in the triggering demodulation 
        % channel exceeds this value
        trig_threshold = 1e-3 % V  
        
        % Duration of the recorded ringdown
        record_time = 1 % (s)
        
        % If enable_acq is true, then the drive is on and the acquisition 
        % of record is triggered when signal exceeds trig_threshold
        enable_acq = false
        
        % Auxiliary output signal during ringdown. 
        enable_aux_out = false % If auxiliary output is applied
        
        % time during which the output is in aux_out_on_lev state
        aux_out_on_t = 1 % (s)
        
        % time during which the output is in aux_out_off_lev state
        aux_out_off_t = 1 % (s)
        
        aux_out_on_lev = 1 % (V), output trigger on level
        aux_out_off_lev = 0 % (V), output trigger off level
        
        % Average the trace over n points to reduce amount of stored data
        % while keeping the demodulator bandwidth large
        downsample_n = 1 
        
        fft_length = 128
        
        auto_save = false % if all ringdowns should be automatically saved
        
        % In adaptive measurement oscillator mode the oscillator frequency
        % is continuously changed to follow the signal frequency during
        % ringdown acquisition. This helps against the oscillator frequency
        % drift.
        adaptive_meas_osc = false   
    end
    
    % The properties which are read or set only once during the class
    % initialization
    properties (GetAccess = public, SetAccess = {?MyClassParser}, ...
            SetObservable = true)
        
        % enumeration for demodulators, oscillators and output starts from 1
        demod = 1 % demodulator used for both triggering and measurement
        
        % Enumeration in the node structure starts from 0, so, for example,
        % the default path to the trigger demodulator refers to the
        % demodulator #1
        demod_path = '/dev4090/demods/0'
        
        drive_osc = 1
        meas_osc = 2
        
        % Signal input, integers above 1 correspond to main inputs, aux 
        % input etc. (see the user interface for device-specific details)
        signal_in = 1 
        
        drive_out = 1 % signal output used for driving
        
        % Number of an auxiliary channel used for the output of triggering 
        % signal, primarily intended to switch the measurement apparatus 
        % off during a part of the ringdown and thus allow for free  
        % evolution of the oscillator during that period.
        aux_out = 1 
        
        % Poll duration of 1 ms practically means that ziDAQ('poll', ...
        % returns immediately with the data accumulated since the
        % previous function call. 
        poll_duration = 0.001 % s
        poll_timeout = 50 % ms
        
        % Margin for adaptive oscillator frequency adjustment - oscillator
        % follows the signal if the dispersion of frequency in the
        % demodulator band is below ad_osc_margin times the demodulation 
        % bandwidth (under the condition that adaptive_meas_osc=true) 
        ad_osc_margin = 0.1
    end
    
    % Internal variables
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        
        recording = false % true if a ringdown is being recorded
        
        % true if adaptive measurement oscillator mode is on and if the
        % measurement oscillator is actually actively following.
        ad_osc_following = false  
        
        % Reference timestamp at the beginning of measurement record. 
        % Stored as uint64.
        t0
        
        elapsed_t = 0 % Time elapsed since the last recording was started

        DemodSpectrum % MyTrace object to store FFT of the demodulator data
    end
    
    % Other dependent variables that are not device properties
    properties (Dependent = true) 
        
        % Downsample the measurement record to reduce the amount of data
        % while keeping the large demodulation bandwidth.
        % (samples/s), sampling rate of the trace after avraging
        downsampled_rate  
        
        % Provides public access to properties of private AvgTrace
        n_avg % number of ringdowns to be averaged
        avg_count % the average counter
        
        fft_rbw % resolution bandwidth of fft
        
        poll_period % (s)
    end
    
    % Keeping handle objects fully private is the only way to restrict set
    % access to their properties
    properties (Access = private)
        PollTimer 
        
        AuxOutOffTimer   % Timer responsible for switching the aux out off
        AuxOutOnTimer    % Timer responsible for switching the aux out on
        
        % Demodulator samples z(t) stored to continuously calculate
        % spectrum, the values of z are complex here, z=x+iy. 
        % osc_freq is the demodulation frequency
        DemodRecord = struct('t',[],'z',[],'osc_freq',[])
        
        AvgTrace % MyAvgTrace object used for averaging ringdowns
    end
    
    events
        NewDemodSample      % New demodulator samples received 
        RecordingStarted    % Acquisition of a new trace triggered
    end
    
    methods (Access = public)
        
        %% Constructor and destructor
        function this = MyZiRingdown(varargin)
            
            % Extract poll period from varargin
            p = inputParser();
            p.KeepUnmatched = true;
            addParameter(p, 'poll_period', 0.05, @isnumeric);
            parse(p, varargin{:});
            varargin = struct2namevalue(p.Unmatched);
            
            this = this@MyZiLockIn(varargin{:});
            
            % Create and configure trace objects
            % Trace is inherited from the superclass
            this.Trace = MyTrace(...
                'name_x','Time',...
                'unit_x','s',...
                'name_y','Magnitude r',...
                'unit_y','V');
            
            this.DemodSpectrum = MyTrace(...
                'name_x','Frequency',...
                'unit_x','Hz',...
                'name_y','PSD',...
                'unit_y','V^2/Hz');
            
            this.AvgTrace = MyAvgTrace();
            
            % Set up the poll timer. Using a timer for anyncronous
            % data readout allows to use the wait time for execution 
            % of other programs.
            % Fixed spacing is preferred as it is the most robust mode of 
            % operation when keeping the intervals between callbacks 
            % precisely defined is not the biggest concern. 
            % Busy mode is 'drop' - there is no need to accumulate timer
            % callbacks as the data is stored in the buffer of zi data
            % server since the previous poll.
            this.PollTimer = timer(...
                'BusyMode',         'drop',...
                'ExecutionMode',    'fixedSpacing',...
                'Period',           p.Results.poll_period,...
                'TimerFcn',         @this.pollTimerCallback);
            
            % Aux out timers use fixedRate mode for more precise timing.
            % The two timers are executed periodically with a time lag.
            % The first timer switches the auxiliary output off 
            this.AuxOutOffTimer = timer(...
                'ExecutionMode',    'fixedRate',...
                'TimerFcn',         @this.auxOutOffTimerCallback);
            
            % The second timer switches the auxiliary output on
            this.AuxOutOnTimer = timer(...
                'ExecutionMode',    'fixedRate',...
                'TimerFcn',         @this.auxOutOnTimerCallback);
           
            this.demod_path = sprintf('/%s/demods/%i', this.dev_id, ...
                this.demod-1);
            
            createCommandList(this);
        end
        
        function delete(this)
            
            % delete function should never throw errors, so protect
            % statements with try-catch
            try
                stopPoll(this)
            catch
                warning(['Could not usubscribe from the demodulator ', ...
                    'or stop the poll timer.'])
            end
            
            % Delete timers to prevent them from running indefinitely in
            % the case of program crash
            try
                delete(this.PollTimer)
            catch
                warning('Could not delete the poll timer.')
            end
            
            try
                stop(this.AuxOutOffTimer);
                delete(this.AuxOutOffTimer);
            catch
                warning('Could not stop and delete AuxOutOff timer.')
            end
            
            try
                stop(this.AuxOutOnTimer);
                delete(this.AuxOutOnTimer);
            catch
                warning('Could not stop and delete AuxOutOn timer.')
            end
        end
        
        %% Other methods
        
        function startPoll(this)
            sync(this);
            
            % Configure the oscillators, demodulator and driving output
            % -1 accounts for the difference in enumeration conventions 
            % in the software names (starting from 1) and node numbers 
            % (starting from 0).
            % First, update the demodulator path
            this.demod_path = sprintf('/%s/demods/%i', ...
                this.dev_id, this.demod-1);
            
            % Set the data transfer rate so that it satisfies the Nyquist
            % criterion (>x2 the bandwidth of interest)
            this.demod_rate = 4*this.lowpass_bw;
            
            % Configure the demodulator. Signal input:
            ziDAQ('setInt', ...
                [this.demod_path,'/adcselect'], this.signal_in-1);
            
            % Oscillator:
            ziDAQ('setInt', ...
                [this.demod_path,'/oscselect'], this.drive_osc-1);
            
            % Enable data transfer from the demodulator to the computer
            ziDAQ('setInt', [this.demod_path,'/enable'], 1);
            
            % Configure the signal output - disable all the oscillator 
            % contributions excluding the driving tone
            path = sprintf('/%s/sigouts/%i/enables/*', ...
                this.dev_id, this.drive_out-1);
            ziDAQ('setInt', path, 0);
            
            path = sprintf('/%s/sigouts/%i/enables/%i', ...
                this.dev_id, this.drive_out-1, this.drive_osc-1);
            ziDAQ('setInt', path, 1);
            
            % Enable output 
            this.drive_on = true;
             
            % By convention, we start form 'enable_acq=false' state
            this.enable_acq = false;
            
            % Configure the auxiliary trigger output - put it in the manual
            % mode so it does not output demodulator readings
            path = sprintf('/%s/auxouts/%i/outputselect', ...
                this.dev_id, this.aux_out-1);
            ziDAQ('setInt', path, -1);
            
            % The convention is that aux out is on by default
            this.aux_out_on = true;
            
            % Subscribe to continuously receive samples from the 
            % demodulator. Samples accumulated between timer callbacks 
            % will be read out using ziDAQ('poll', ... 
            ziDAQ('subscribe', [this.demod_path,'/sample']);
            
            % Start continuous polling
            start(this.PollTimer)
        end
        
        function stopPoll(this)
            stop(this.PollTimer)
            ziDAQ('unsubscribe', [this.demod_path,'/sample']);
        end
        
        % Main function that polls data from the device demodulator
        function pollTimerCallback(this, ~, ~)
            
            % Switch off the hedged mode to reduce latency
            this.auto_sync = false;
            
            % ziDAQ('poll', ... with short poll_duration returns 
            % immediately with the data accumulated since the last timer 
            % callback 
            Data = ziDAQ('poll', this.poll_duration, this.poll_timeout);
            
            try
                
                % Get the new demodulator data
                DemodSample = Data.(this.dev_id).demods(this.demod).sample;
            catch
                this.auto_sync = true;
                return
            end
                
            % Append new samples to the record and recalculate spectrum
            appendSamplesToBuff(this, DemodSample);
            calcfft(this);

            if this.recording

                % If the recording has just started, save the start time
                if isempty(this.Trace.x)
                    this.t0 = DemodSample.timestamp(1);
                end
                
                % If recording is under way, append the new samples to
                % the trace
                rec_finished = appendSamplesToTrace(this, DemodSample);

                % Recording can be manually stopped by setting
                % enable_acq=false
                if ~this.enable_acq
                    rec_finished = true;
                end

                % Update elapsed time
                this.elapsed_t = this.Trace.x(end);

                % If the adaptive measurement frequency mode is on,
                % update the measurement oscillator frequency.
                % Make sure that the demodulator record actually
                % contains a signal by comparing the dispersion of 
                % frequency to the demodulator bandwidth.
                if this.adaptive_meas_osc
                    [df_avg, df_dev] = calcfreq(this);
                    if df_dev < this.ad_osc_margin*this.lowpass_bw
                        this.meas_osc_freq = df_avg;

                        % Change indicator
                        this.ad_osc_following = true;
                    else
                        this.ad_osc_following = false;
                    end
                else
                    this.ad_osc_following = false;
                end
            else
                r = sqrt(DemodSample.x.^2+DemodSample.y.^2);
                if this.enable_acq && max(r)>this.trig_threshold

                    % Start acquisition of a new trace if the maximum
                    % of the signal exceeds threshold
                    this.recording = true;
                    this.elapsed_t = 0;

                    % Switch the drive off
                    this.drive_on = false;

                    % Set the measurement oscillator frequency to be
                    % the frequency at which triggering occurred
                    this.meas_osc_freq = this.drive_osc_freq;

                    % Switch the oscillator
                    this.current_osc = this.meas_osc;

                    % Clear the buffer on ZI data server from existing   
                    % demodulator samples, as these samples were 
                    % recorded with drive on 
                    ziDAQ('poll', this.poll_duration, this.poll_timeout);

                    % Optionally start the auxiliary output timers
                    if this.enable_aux_out

                        % Configure measurement periods and delays
                        T = this.aux_out_on_t + this.aux_out_off_t;
                        this.AuxOutOffTimer.Period = T;
                        this.AuxOutOnTimer.Period = T;

                        this.AuxOutOffTimer.startDelay =...
                            this.aux_out_on_t;
                        this.AuxOutOnTimer.startDelay = T;

                        % Start timers
                        start(this.AuxOutOffTimer)
                        start(this.AuxOutOnTimer)
                    end

                    % Clear trace 
                    clearData(this.Trace);

                    notify(this, 'RecordingStarted');
                end

                rec_finished = false;

                % Indicator for adaptive measurement is off, since
                % recording is not under way
                this.ad_osc_following = false;
            end

            notify(this,'NewDemodSample');

            % Stop recording if a record was completed
            if rec_finished

                % stop recording
                this.recording = false;
                this.ad_osc_following = false;

                % Stop auxiliary timers
                stop(this.AuxOutOffTimer);
                stop(this.AuxOutOnTimer);

                % Return the drive and aux out to the default state
                this.aux_out_on = true;
                this.current_osc = this.drive_osc;
                this.drive_on = true;

                % Do trace averaging. If the new data length is not of 
                % the same size as the length of the existing data 
                % (which should happen only when the record period was
                % changed during recording or when recording was 
                % manually stopped), truncate to the minimum length
                if ~isempty(this.AvgTrace.x) && ...
                        (length(this.AvgTrace.y)~=length(this.Trace.y))

                    l = min(length(this.AvgTrace.y), ...
                        length(this.Trace.y));

                    this.AvgTrace.y = this.AvgTrace.y(1:l);
                    this.AvgTrace.x = this.AvgTrace.x(1:l);
                    this.Trace.y = this.Trace.y(1:l);
                    this.Trace.x = this.Trace.x(1:l);

                    disp('Ringdown record was truncated')
                end
                avg_compl = addAverage(this.AvgTrace, this.Trace);

                % Trigger NewData
                if this.n_avg>1
                    end_str = sprintf('_%i', this.AvgTrace.avg_count);
                else
                    end_str = '';
                end
                triggerNewData(this, 'save', this.auto_save, ...
                    'filename_ending', end_str);

                % If the ringdown averaging is complete, disable
                % further triggering to exclude data overwriting 
                if avg_compl
                    this.enable_acq = false;

                    if this.n_avg>1
                        end_str = '_avg';

                        % Trigger one more time to transfer the average
                        % trace.
                        % A new measurement header is not necessary 
                        % as the delay since the last triggering is  
                        % minimum.
                        triggerNewData(this, ...
                            'Trace', copy(this.AvgTrace), ...
                            'save', this.auto_save, ...
                            'filename_ending', end_str);
                    end
                end
            end
            
            this.auto_sync = true;
        end
        
        % Append timestamps vs r=sqrt(x^2+y^2) to the measurement record.
        % Starting index can be supplied as varargin.
        % The output variable tells if the record is finished.
        function isfin = appendSamplesToTrace(this, DemodSample)
            persistent ts_buff r_sq_buff
            
            r_sq = DemodSample.x.^2 + DemodSample.y.^2;
            
            % Subtract the reference time, convert timestamps to seconds
            ts = double(DemodSample.timestamp - this.t0)/this.clockbase;
            
            % Check if recording should be stopped
            isfin = (ts(end) >= this.record_time);
            if isfin
                
                % Remove excess data points from the new data
                ind = (ts<this.record_time);
                ts = ts(ind);
                r_sq = r_sq(ind);
            end
            
            % Add new data to the averaging buffer
            r_sq_buff = [r_sq_buff; r_sq(:)];
            ts_buff = [ts_buff; ts(:)];
            
            n = floor(length(r_sq_buff)/this.downsample_n);
            
            % Average over downsample_n consecutive points
            new_r_sq = mean(reshape(r_sq_buff(1:n*this.downsample_n), ...
                [this.downsample_n, n]));
            new_ts = mean(reshape(ts_buff(1:n*this.downsample_n), ...
                [this.downsample_n, n]));
            
            % Append the new downsampled data to the trace
            this.Trace.x = [this.Trace.x; new_ts(:)];
            this.Trace.y = [this.Trace.y; sqrt(new_r_sq(:))];
            
            % Reset the averaging buffers
            r_sq_buff = r_sq_buff(n*this.downsample_n+1:end);
            ts_buff = ts_buff(n*this.downsample_n+1:end);
            
            if isfin
                r_sq_buff = [];
                ts_buff = [];
            end
        end
        
        % Append timestamps vs z=x+iy to the shift register for fft
        % calculation
        function appendSamplesToBuff(this, DemodSample)
            z = complex(DemodSample.x, DemodSample.y);
            t = double(DemodSample.timestamp)/this.clockbase;
            
            % Convert the new data to column format and append
            this.DemodRecord.t = [this.DemodRecord.t; t(:)];
            this.DemodRecord.z = [this.DemodRecord.z; z(:)];
            this.DemodRecord.osc_freq = [this.DemodRecord.osc_freq; ...
                DemodSample.frequency(:)];
            
            % Only store the latest data points required to calculate fft
            flen = this.fft_length;
            if length(this.DemodRecord.t)>flen
                this.DemodRecord.t = this.DemodRecord.t(end-flen+1:end);
                this.DemodRecord.z = this.DemodRecord.z(end-flen+1:end);
                this.DemodRecord.osc_freq = ...
                    this.DemodRecord.osc_freq(end-flen+1:end);
            end
        end
        
        function calcfft(this)
            flen = min(this.fft_length, length(this.DemodRecord.t));
            [freq, spectr] = xyFourier( ...
                this.DemodRecord.t(end-flen+1:end), ...
                this.DemodRecord.z(end-flen+1:end));
            this.DemodSpectrum.x = freq;
            this.DemodSpectrum.y = abs(spectr).^2;
        end
        
        % Calculate the average frequency and dispersion of the demodulator 
        % signal 
        function [f_avg, f_dev] = calcfreq(this)
            if ~isempty(this.DemodSpectrum.x)
                norm = sum(this.DemodSpectrum.y);
                
                % Calculate the center frequency of the spectrum
                f_avg = dot(this.DemodSpectrum.x, ...
                    this.DemodSpectrum.y)/norm;
                
                f_dev = sqrt(dot(this.DemodSpectrum.x.^2, ...
                    this.DemodSpectrum.y)/norm-f_avg^2);
                
                % Shift the FFT center by the demodulation frequency to
                % output absolute value
                f_avg = f_avg + mean(this.DemodRecord.osc_freq);
            else
                f_avg = [];
                f_dev = [];
            end
        end
        
        % Provide restricted access to private AvgTrace
        function resetAveraging(this)
            
            % Clear data and reset the counter
            clearData(this.AvgTrace);
        end
        
        function auxOutOffTimerCallback(this, ~, ~)
            this.aux_out_on = false;
        end
        
        function auxOutOnTimerCallback(this, ~, ~)
            this.aux_out_on = true;
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            addCommand(this, 'drive_osc_freq', ...
                'readFcn',      @this.readDriveOscFreq, ...
                'writeFcn',     @this.writeDriveOscFreq);
            
            addCommand(this, 'meas_osc_freq', ...
                'readFcn',      @this.readMeasOscFreq, ...
                'writeFcn',     @this.writeMeasOscFreq);
            
            addCommand(this, 'drive_on', ...
                'readFcn',      @this.readDriveOn, ...
                'writeFcn',     @this.writeDriveOn);
            
            addCommand(this, 'current_osc', ...
                'readFcn',      @this.readCurrentOsc, ...
                'writeFcn',     @this.writeCurrentOsc);
            
            addCommand(this, 'drive_amp', ...
                'readFcn',      @this.readDriveAmp, ...
                'writeFcn',     @this.writeDriveAmp);
            
            addCommand(this, 'lowpass_order', ...
                'readFcn',      @this.readLowpassOrder, ...
                'writeFcn',     @this.writeLowpassOrder, ...
                'default',      1);
                
            addCommand(this, 'lowpass_bw', ...
                'readFcn',      @this.readLowpassBw, ...
                'writeFcn',     @this.writeLowpassBw);
            
            addCommand(this, 'demod_rate', ...
                'readFcn',      @this.readDemodRate, ...
                'writeFcn',     @this.writeDemodRate);
            
            addCommand(this, 'aux_out_on', ...
                'readFcn',      @this.readAuxOutOn, ...
                'writeFcn',     @this.writeAuxOutOn);
        end
        
        
        function val = readDriveOscFreq(this)
            path = sprintf('/%s/oscs/%i/freq', this.dev_id, ...
                this.drive_osc-1);
            val = ziDAQ('getDouble', path);
        end
        
        function writeDriveOscFreq(this, val)
            path = sprintf('/%s/oscs/%i/freq', this.dev_id, ...
                this.drive_osc-1);
            ziDAQ('setDouble', path, val);
        end
        
        function val = readMeasOscFreq(this)
            path = sprintf('/%s/oscs/%i/freq', this.dev_id, ...
                this.meas_osc-1);
            val = ziDAQ('getDouble', path);
        end
        
        function writeMeasOscFreq(this, val)
            path = sprintf('/%s/oscs/%i/freq', this.dev_id, ...
                this.meas_osc-1);
            ziDAQ('setDouble', path, val);
        end
        
        function val = readDriveOn(this)
            path = sprintf('/%s/sigouts/%i/on', this.dev_id, ...
                this.drive_out-1);
            val = logical(ziDAQ('getInt', path));
        end
        
        function writeDriveOn(this, val)
            path = sprintf('/%s/sigouts/%i/on', this.dev_id, ...
                this.drive_out-1);
            % Use double() to convert from logical
            ziDAQ('setInt', path, double(val));
        end
        
        function val = readCurrentOsc(this)
            val = double(ziDAQ('getInt', ...
                [this.demod_path,'/oscselect']))+1;
        end
        
        function writeCurrentOsc(this, val)
            assert((val==this.drive_osc) || (val==this.meas_osc), ...
                ['The number of current oscillator must be that of ', ...
                'the drive or measurement oscillator, not ', num2str(val)])
            ziDAQ('setInt', [this.demod_path,'/oscselect'], val-1);
        end
        
        function val = readDriveAmp(this)
            path = sprintf('/%s/sigouts/%i/amplitudes/%i', ...
                this.dev_id, this.drive_out-1, this.drive_osc-1);
            val = ziDAQ('getDouble', path);
        end
        
        function writeDriveAmp(this, val)
            path=sprintf('/%s/sigouts/%i/amplitudes/%i', ...
                this.dev_id, this.drive_out-1, this.drive_osc-1);
            ziDAQ('setDouble', path, val);
        end
        
        function n = readLowpassOrder(this)
            n = ziDAQ('getInt', [this.demod_path,'/order']);
        end
        
        function writeLowpassOrder(this, val)
            assert(any(val==[1,2,3,4,5,6,7,8]), ['Low-pass filter ', ...
                'order must be an integer between 1 and 8'])
            ziDAQ('setInt', [this.demod_path,'/order'], val);
        end
        
        function bw = readLowpassBw(this)
            tc = ziDAQ('getDouble', [this.demod_path,'/timeconstant']);
            bw = ziTC2BW(tc, this.lowpass_order);
        end
        
        function writeLowpassBw(this, val)
            tc = ziBW2TC(val, this.lowpass_order);
            ziDAQ('setDouble', [this.demod_path,'/timeconstant'], tc);
        end
        
        function val = readDemodRate(this)
            val = ziDAQ('getDouble', [this.demod_path,'/rate']);
        end
        
        function writeDemodRate(this, val)
            ziDAQ('setDouble', [this.demod_path,'/rate'], val);
        end
        
        function bool = readAuxOutOn(this)
            path = sprintf('/%s/auxouts/%i/offset', ...
                this.dev_id, this.aux_out-1);
            val = ziDAQ('getDouble', path);
            
            % Signal from the auxiliary output is continuous, we make the
            % binary decision about the output state depending on if 
            % the signal is closer to the ON or OFF level
            bool = (abs(val-this.aux_out_on_lev) < ...
                abs(val-this.aux_out_off_lev));
        end
        
        function writeAuxOutOn(this, bool)
            path = sprintf('/%s/auxouts/%i/offset', ...
                this.dev_id, this.aux_out-1);
            if bool
                out_offset = this.aux_out_on_lev;
            else
                out_offset = this.aux_out_off_lev;
            end
            ziDAQ('setDouble', path, out_offset);
        end
        
        function createMetadata(this)
            createMetadata@MyZiLockIn(this);

            % Demodulator parameters
            addObjProp(this.Metadata, this, 'demod', 'comment', ...
                'Number of the demodulator in use (starting from 1)');
            addObjProp(this.Metadata, this, 'meas_osc', 'comment', ...
                'Measurement oscillator number');
            
            % Signal input
            addObjProp(this.Metadata, this, 'signal_in', 'comment', ...
                'Singnal input number');
            
            % Drive parameters
            addObjProp(this.Metadata, this, 'drive_out', 'comment', ...
                'Driving output number');
            addObjProp(this.Metadata, this, 'drive_osc', 'comment', ...
                'Swept oscillator number');
            
            % Parameters of the auxiliary output
            addObjProp(this.Metadata, this, 'aux_out', 'comment', ...
                'Auxiliary output number');
            addObjProp(this.Metadata, this, 'enable_aux_out', 'comment',...
                'Auxiliary output is applied during ringdown');
            addObjProp(this.Metadata, this, 'aux_out_on_lev', ...
                'comment', '(V)');
            addObjProp(this.Metadata, this, 'aux_out_off_lev', ...
                'comment', '(V)');
            addObjProp(this.Metadata, this, 'aux_out_on_t', ...
                'comment', '(s)');
            addObjProp(this.Metadata, this, 'aux_out_off_t', ...
                'comment', '(s)');
            
            % Software parameters
            addObjProp(this.Metadata, this, 'trig_threshold', 'comment',...
                '(V), threshold for starting a ringdown record');
            addObjProp(this.Metadata, this, 'record_time', ...
                'comment', '(s)');
            addObjProp(this.Metadata, this, 'downsampled_rate', ...
                'comment', ['(samples/s), rate to which a ringown ', ...
                'trace is downsampled with averaging after acquisition']);
            addObjProp(this.Metadata, this, 'auto_save', 'comment', '(s)');
            
            % Adaptive measurement oscillator
            addObjProp(this.Metadata, this, 'adaptive_meas_osc', ...
                'comment', ['If true the measurement oscillator ', ...
                'frequency is adjusted during ringdown']);
            addObjProp(this.Metadata, this, 'ad_osc_margin');
            addObjProp(this.Metadata, this, 'fft_length', ...
                'comment', '(points)');
            
            % Timer poll parameters
            addParam(this.Metadata, 'poll_period', [],...
                'comment', '(s)');
            addObjProp(this.Metadata, this, 'poll_duration', ...
                'comment', '(s)');
            addObjProp(this.Metadata, this, 'poll_timeout', ...
                'comment', '(ms)');
        end
    end
    
    %% Set and get methods.
    methods
        function set.downsample_n(this, val)
            n = round(val);
            assert(n>=1, ['Number of points for trace averaging must ', ...
                'be greater than 1'])
            this.downsample_n = n;
        end
        
        function set.downsampled_rate(this, val)
            dr = this.demod_rate;
            
            % Downsampled rate should not exceed the data transfer rate
            val = min(val, dr);
            
            % Round so that the averaging is done over an integer number of
            % points
            this.downsample_n = round(dr/val);
        end
        
        function val = get.downsampled_rate(this)
            val = this.demod_rate/this.downsample_n;
        end
        
        function set.fft_length(this, val)
            
            % Round val to the nearest 2^n to make the calculation of
            % Fourier transform efficient
            n = round(log2(max(val, 1)));
            this.fft_length = 2^n;
        end
        
        function val = get.fft_rbw(this)
            val = this.demod_rate/this.fft_length;
        end
        
        function set.fft_rbw(this, val)
            assert(val>0,'FFT resolution bandwidth must be greater than 0')
            % Rounding of fft_length to the nearest integer is handled by 
            % its own set method
            
            this.fft_length = this.demod_rate/val;
        end
        
        function set.n_avg(this, val)
            this.AvgTrace.n_avg = val;
        end
        
        function val = get.n_avg(this)
            val = this.AvgTrace.n_avg;
        end
        
        function val = get.avg_count(this)
            val = this.AvgTrace.avg_count;
        end
        
        function set.aux_out_on_t(this, val)
            assert(val>0.001, ...
                'Aux out on time must be greater than 0.001 s.')
            this.aux_out_on_t = val;
        end
        
        function set.aux_out_off_t(this, val)
            assert(val>0.001, ...
                'Aux out off time must be greater than 0.001 s.')
            this.aux_out_off_t = val;
        end
        
        function set.enable_acq(this, val)
            this.enable_acq = logical(val);
        end
        
        function val = get.poll_period(this)
            val = this.PollTimer.Period;
        end
    end
end

