% Class for performing ringdown measurements of mechanical oscillators
% using Zurich Instruments UHF or MF lock-in.
%
% Operation: sweep the driving tone (drive_osc) using the sweep module 
% in LabOne web user interface, when the magnitude of the demodulator 
% signal exceeds trig_threshold switch off the driving tone and start 
% recording the demodulated signal for the duration of record_time.   

classdef MyZiRingdown < handle
    
    properties (Access=public)
        % Ringdown is recorded if the signal in the triggering demodulation 
        % channel exceeds this value
        trig_threshold=1e-3 % V  
        
        % Duration of the recorded ringdown
        record_time=1 % s
        
        % If enable_acq is true, then the drive is on andthe acquisition 
        % of record is triggered when signal exceeds trig_threshold
        enable_acq=false
        
        % Average the trace over n points to reduce amount of stored data
        % while keeping the demodulator bandwidth large
        downsample_n=1 
        
        fft_length=256
    end
    
    % The properties which are read or set only once during the class
    % initialization
    properties (GetAccess=public, SetAccess={?MyClassParser,?MyZiRingdown})
        name='ziRingdown'
        
        dev_serial='dev4090'
        
        % enumeration for demodulators, oscillators and output starts from 1
        demod=1 % demodulator used for both triggering and measurement
        
        % Enumeration in the node structure starts from 0, so, for example,
        % the default path to the trigger demodulator refers to the
        % demodulator #1
        demod_path='/dev4090/demods/0'
        
        drive_osc=1
        meas_osc=2
        
        % Signal input, integers above 1 correspond to main inputs, aux 
        % input etc. (see the user interface for device-specific details)
        signal_in=1 
        
        drive_out=1 % signal output used for driving
        
        % Device clock frequency, i.e. the number of timestamps per second
        clockbase
        
        % The string that specifies the device name as appears 
        % in the server's node tree. Can be the same as dev_serial.
        dev_id
        
        % Device information string containing the data returned by  
        % ziDAQ('discoveryGet', ... 
        idn_str
        
        % Poll duration of 1 ms practically means that ziDAQ('poll', ...
        % returns immediately with the data accumulated since the
        % previous function call. 
        poll_duration = 0.001; % s
        poll_timeout = 50; % ms
    end
    
    % Internal variables
    properties (GetAccess=public, SetAccess=protected)
        recording=false % true if a ringdown is being recorded
        
        % Reference timestamp at the beginning of measurement record. 
        % Stored as uint64.
        t0
        
        elapsed_t=0 % Time elapsed since the last recording was started
        
        Trace % MyTrace object storing the ringdown
        DemodSpectrum % MyTrace object to store FFT of the demodulator data
    end
    
    % Setting or reading the properties below automatically invokes
    % communication with the device
    properties (Dependent=true)
        drive_osc_freq
        meas_osc_freq
        drive_on % true when the dirive output is on
        current_osc
        
        % demodulator sampling rate (as transferred to the computer)
        demod_rate   
        
        % The properties below are only used within the program to display
        % the information about device state.
        drive_amp % (V), peak-to-peak amplitude of the driving tone
        lowpass_order % low-pass filter order
        lowpass_bw % low-pass filter bandwidth
    end
    
    % Other dependent variables that are dont device properties
    properties (Dependent=true) 
        % Downsample the measurement record to reduce the amount of data
        % while keeping the large demodulation bandwidth.
        % (samples/s), sampling rate of the trace after avraging
        downsampled_rate  
        
        fft_rbw % resolution bandwidth of fft
    end
    
    properties (Access=public)
        PollTimer
        
        % Samples stored to continuously calculate spectrum
        % values of z are complex here, z=x+iy
        DemodRecord=struct('t',[],'z',[])
    end
    
    events
        % Event for communication with Daq that signals the acquisition of 
        % a new ringdown
        NewData
        NewDemodSample % New demodulator samples received
        NewSetting % Device settings changed
    end
    
    methods (Access=public)
        
        %% Constructor and destructor
        function this = MyZiRingdown(dev_serial, varargin)
            P=MyClassParser(this);
            % Poll timer period
            addParameter(P,'poll_period',0.1,@isnumeric);
            processInputs(P, varargin{:});
            
            % Create and configure trace objects
            this.Trace=MyTrace(...
                'name_x','Time',...
                'unit_x','s',...
                'name_y','Magnitude r',...
                'unit_y','V');
            this.DemodSpectrum=MyTrace(...
                'name_x','Frequency',...
                'unit_x','Hz',...
                'name_y','PSD',...
                'unit_y','V^2/Hz');
            
            % Set up the poll timer. Using a timer for anyncronous
            % data readout allows to use the wait time for execution 
            % of other programs.
            % Fixed spacing is preferred as it is the most robust mode of 
            % operation when keeping the intervals between callbacks 
            % precisely defined is not the biggest concern. 
            this.PollTimer=timer(...
                'ExecutionMode','fixedSpacing',...
                'Period',P.Results.poll_period,...
                'TimerFcn',@(~,~)pollTimerCallback(this));
            
            % Check the ziDAQ MEX (DLL) and Utility functions can be found in Matlab's path.
            if ~(exist('ziDAQ', 'file') == 3) && ~(exist('ziCreateAPISession', 'file') == 2)
                fprintf('Failed to either find the ziDAQ mex file or ziDevices() utility.\n')
                fprintf('Please configure your path using the ziDAQ function ziAddPath().\n')
                fprintf('This can be found in the API subfolder of your LabOne installation.\n');
                fprintf('On Windows this is typically:\n');
                fprintf('C:\\Program Files\\Zurich Instruments\\LabOne\\API\\MATLAB2012\\\n');
                return
            end
            
            % Create an API session and connect to the correct Data Server. 
            % This is a high level function that uses ziDAQ('connect',.. 
            % and ziDAQ('connectDevice', ... when necessary
            apilevel=6;
            [this.dev_id,~]=ziCreateAPISession(dev_serial, apilevel);
            
            % Read the divice clock frequency
            this.clockbase = ...
                double(ziDAQ('getInt',['/',this.dev_id,'/clockbase']));
     
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
            try
                delete(this.PollTimer)
            catch
                warning('Could not delete the poll timer.')
            end
        end
        
        %% Other methods
        
        function startPoll(this)
            % Configure the oscillators, demodulator and driving output
            % -1 accounts for the difference in enumeration conventions 
            % in the software names (starting from 1) and node numbers 
            % (starting from 0)
            this.demod_path = sprintf('/%s/demods/%i', ...
                this.dev_id, this.demod-1);
            
            % Set the data transfer rate so that it satisfies the Nyquist
            % criterion (>x2 the bandwidth of interest)
            this.demod_rate=3*this.lowpass_bw;
            
            % Configure the demodulator. Signal input:
            ziDAQ('setInt', ...
                [this.demod_path,'/adcselect'], this.signal_in-1);
            % Oscillator:
            ziDAQ('setInt', ...
                [this.demod_path,'/oscselect'], this.drive_osc-1);
            % Enable data transfer from the demodulator to the computer
            ziDAQ('setInt', [this.demod_path,'/enable'], 1);
            
            % Configure the signal output - disable all the oscillator 
            % contributions including the driving tone since we start 
            % form 'enable_acq=false' state
            path = sprintf('/%s/sigouts/%i/enables/*', ...
                this.dev_id, this.drive_out-1);
            ziDAQ('setInt', path, 0);
            
            % Subscribe to continuously receive samples from the 
            % demodulator. Samples accumulated between timer callbacks 
            % will be read out using ziDAQ('poll', ... 
            ziDAQ('subscribe',[this.demod_path,'/sample']);
            
            % Start continuous polling
            start(this.PollTimer)
        end
        
        function stopPoll(this)
            stop(this.PollTimer)
            ziDAQ('unsubscribe',[this.demod_path,'/sample']);
        end
        
        % Main function that polls data drom the device demodulator
        function pollTimerCallback(this)
            
            % ziDAQ('poll', ... with short poll_duration returns 
            % immediately with the data accumulated since the last timer 
            % callback 
            Data = ziDAQ('poll', this.poll_duration, this.poll_timeout);
                
            if ziCheckPathInData(Data, [this.demod_path,'/sample'])
                % Demodulator returns data
                DemodSample= ...
                    Data.(this.dev_id).demods(this.demod).sample;
                
                % Append new samples to the record and recalculate spectrum
                appendSamplesToBuff(this, DemodSample);
                calcfft(this);
                
                if this.recording
                    % If recording is under way, append the new samples to
                    % the trace
                    appendSamplesToTrace(this, DemodSample)
                    
                    % Check if recording should be stopped 
                    if this.Trace.x(end)>=this.record_time
                        % stop recording
                        this.recording=false;
                        % Switch the oscillator
                        this.current_osc=this.drive_osc;
                        % Do not enable acquisition after a ringdown is
                        % recorded to prevent possible overwriting
                        this.enable_acq=false;
                        
                        % Downsample the trace to reduce the amount of data
                        downsample(this.Trace, this.downsample_n, 'avg');
                        
                        triggerNewData(this);
                    else
                        % Update elapsed time
                        this.elapsed_t=this.Trace.x(end);
                    end
                else
                    rmax=max(sqrt(DemodSample.x.^2+DemodSample.y.^2));
                    if this.enable_acq && rmax>this.threshold
                        % Start acquisition of a new trace if the maximum
                        % of the signal exceeds threshold
                        clearData(this.Trace);
                        this.recording=true;

                        this.t0=DemodSample.timestamp(1);
                        this.elapsed_t=0;

                        % Switch the drive off
                        this.drive_on=false;

                        % Set the measurement oscillator frequency to be
                        % the frequency at which triggering occurred
                        this.meas_osc_freq=this.drive_osc_freq;

                        % Switch the oscillator
                        this.current_osc=this.meas_osc;
                    end
                end
                notify(this,'NewDemodSample')
            end
        end
        
        % Append timestamps vs r=sqrt(x^2+y^2) to the measurement record
        function appendSamplesToTrace(this, DemodSample)
            r=sqrt(DemodSample.x.^2+DemodSample.y.^2);
            % Subtract the reference time, convert timestamps to seconds
            % and append the new data to the trace.
            this.Trace.x=[this.Trace.x, ...
                double(DemodSample.timestamp-this.t0)/this.clockbase];
            this.Trace.y=[this.Trace.y, r];
        end
        
        % Append timestamps vs z=x+iy to the shift register for fft
        % calculation
        function appendSamplesToBuff(this, DemodSample)
            z=complex(DemodSample.x, DemodSample.y);
            t=double(DemodSample.timestamp)/this.clockbase;
            
            this.DemodRecord.t=[this.DemodRecord.t, t];
            this.DemodRecord.z=[this.DemodRecord.z, z];
            
            assert(length(this.DemodRecord.t)==length(this.DemodRecord.z), ...
                't and z=x+iy array lengths of DemodRecord are not equal.')
            
            % Only store the latest data points required to calculate fft
            flen=this.fft_length;
            if length(this.DemodRecord.t)>flen
                this.DemodRecord.t = this.DemodRecord.t(end-flen+1:end);
                this.DemodRecord.z = this.DemodRecord.z(end-flen+1:end);
            end
        end
        
        function calcfft(this)
            flen=min(this.fft_length, length(this.DemodRecord.t));
            [freq, spectr]=xyFourier( ...
                this.DemodRecord.t(end-flen+1:end), ...
                this.DemodRecord.z(end-flen+1:end));
            this.DemodSpectrum.x=freq;
            this.DemodSpectrum.y=abs(spectr).^2;
        end
        
        function str=idn(this)
            DevProp=ziDAQ('discoveryGet', this.dev_id);
            str=this.dev_id;
            if isfield(DevProp, 'devicetype')
                str=[str,'; device type: ', DevProp.devicetype];
            end
            if isfield(DevProp, 'options')
                % Print options from the list as comma-separated values and
                % discard the last comma.
                opt_str=sprintf('%s,',DevProp.options{:});
                str=[str,'; options: ', opt_str(1:end-1)];
            end
            if isfield(DevProp, 'serverversion')
                str=[str,'; server version: ', DevProp.serverversion];
            end
            this.idn_str=str;
        end
        
        function triggerNewData(this)
            notify(this,'NewData')
        end
        
        function Hdr=readHeader(this)
            Hdr=MyMetadata();
            % Generate valid field name from instrument name if present and
            % class name otherwise
            if ~isempty(this.name)
                field_name=genvarname(this.name);
            else
                field_name=class(this);
            end
            addField(Hdr, field_name);
            % Add identification string 
            addParam(Hdr, field_name, 'idn', this.idn_str);
            % Add the measurement configuration
            addParam(Hdr, field_name, 'demod', this.demod, ...
                'comment', 'Demodulator number (starting from 1)');
            addParam(Hdr, field_name, 'drive_osc', this.drive_osc, ...
                'comment', 'Swept oscillator number');
            addParam(Hdr, field_name, 'meas_osc', this.meas_osc, ...
                'comment', 'Measurement oscillator number');
            addParam(Hdr, field_name, 'signal_in', this.signal_in, ...
                'comment', 'Singnal input number');
            addParam(Hdr, field_name, 'drive_out', this.drive_out, ...
                'comment', 'Driving output number');
            addParam(Hdr, field_name, 'clockbase', this.clockbase, ...
                'comment', ['Device clock frequency, i.e. the number ', ...
                'of timestamps per second']);
            addParam(Hdr, field_name, 'drive_amp', this.drive_amp, ...
                'comment', '(V) peak to peak');
            addParam(Hdr, field_name, 'meas_osc_freq', ...
                this.meas_osc_freq, 'comment', '(Hz)');
            addParam(Hdr, field_name, 'trig_threshold', ...
                this.drive_threshold, 'comment', '(V)');
            addParam(Hdr, field_name, 'record_time', ...
                this.record_time, 'comment', '(s)');
            addParam(Hdr, field_name, 'lowpass_order', ...
                this.lowpass_order, 'comment', ...
                'Order of the demodulator low-pass filter');
            addParam(Hdr, field_name, 'lowpass_bw', this.lowpass_bw, ...
                'comment', ['(Hz), 3 dB bandwidth of the demodulator ', ...
                'low-pass filter']);
            addParam(Hdr, field_name, 'demod_rate', this.demod_rate, ...
                'comment', '(samples/s), demodulator data transfer rate');
            addParam(Hdr, field_name, 'downsampled_rate', ...
                this.downsampled_rate, 'comment', ...
                '(samples/s), downsampling with averaging');
            addParam(Hdr, field_name, 'poll_duration', ...
                this.poll_duration, 'comment', '(s)');
            addParam(Hdr, field_name, 'poll_timeout', ...
                this.poll_timeout, 'comment', '(ms)');
        end
    end
    
    %% Set and get methods
    methods
        
        function freq=get.drive_osc_freq(this)
            path=sprintf('/%s/oscs/%i/freq', this.dev_id, this.drive_osc-1);
            freq=ziDAQ('getDouble', path);
        end
        
        function set.drive_osc_freq(this, val)
            assert(isfloat(val), ...
                'Oscillator frequency must be a floating point number')
            path=sprintf('/%s/oscs/%i/freq', this.dev_id, this.drive_osc-1);
            ziDAQ('setDouble', path, val);
            notify(this,'NewSetting');
        end
        
        function freq=get.meas_osc_freq(this)
            path=sprintf('/%s/oscs/%i/freq', this.dev_id, this.meas_osc-1);
            freq=ziDAQ('getDouble', path);
        end
        
        function set.meas_osc_freq(this, val)
            assert(isfloat(val), ...
                'Oscillator frequency must be a floating point number')
            path=sprintf('/%s/oscs/%i/freq', this.dev_id, this.meas_osc-1);
            ziDAQ('setDouble', path, val);
            notify(this,'NewSetting');
        end
        
        function set.drive_on(this, val)
            path=sprintf('/%s/sigouts/%i/on',this.dev_id,this.drive_out-1);
            % Use double() to convert from logical type
            ziDAQ('setInt', path, double(val));
            notify(this,'NewSetting');
        end
        
        function bool=get.drive_on(this)
            path=sprintf('/%s/sigouts/%i/on',this.dev_id,this.drive_out-1);
            bool=logical(ziDAQ('getInt', path));
        end
        
        function set.current_osc(this, val)
            assert((val==this.drive_osc) && (val==this.meas_osc), ...
                ['The number of current oscillator must be that of ', ...
                'the drive or measurement oscillator'])
            ziDAQ('setInt', [this.demod_path,'/oscselect'], val-1);
            notify(this,'NewSetting')
        end
        
        function osc_num=get.current_osc(this)
            osc_num=ziDAQ('getInt', [this.demod_path,'/oscselect']);
        end
        
        function amp=get.drive_amp(this)
            path=sprintf('/%s/sigouts/%i/amplitudes/%i', ...
                this.dev_id, this.drive_out-1, this.drive_osc-1);
            amp=ziDAQ('getDouble', path);
        end
        
        function set.drive_amp(this, val)
            path=sprintf('/%s/sigouts/%i/amplitudes/%i', ...
                this.dev_id, this.drive_out-1, this.drive_osc-1);
            ziDAQ('setDouble', path, val);
            notify(this,'NewSetting');
        end
        
        function set.lowpass_order(this, val)
            assert(any(val==[1,2,3,4,5,6,7,8]), ['Low-pass filter ', ...
                'order must be an integer between 1 and 8'])
            ziDAQ('setInt', [this.demod_path,'/order'], val);
            notify(this,'NewSetting');
        end
        
        function n=get.lowpass_order(this)
            n=ziDAQ('getInt', [this.demod_path,'/order']);
        end
        
        function bw=get.lowpass_bw(this)
            tc=ziDAQ('getDouble', [this.demod_path,'/timeconstant']);
            bw=ziBW2TC(tc, this.lowpass_order);
        end
        
        function set.lowpass_bw(this, val)
            tc=ziBW2TC(val, this.lowpass_order);
            ziDAQ('setDouble', [this.demod_path,'/timeconstant'], tc);
            notify(this,'NewSetting');
        end
        
        function rate=get.demod_rate(this)
            rate=ziDAQ('getDouble', [this.demod_path,'/rate']);
        end
        
        function set.demod_rate(this, val)
            ziDAQ('setDouble', [this.demod_path,'/rate'], val);
            notify(this,'NewSetting');
        end
        
        function set.downsample_n(this, val)
            n=round(val);
            assert(n>=1, ['Number of points for trace averaging must ', ...
                'be greater than 1'])
            this.downsample_n=n;
            notify(this,'NewSetting');
        end
        
        function set.downsampled_rate(this, val)
            dr=this.demod_rate;
            if val>dr
                % Downsampled rate should not exceed the data transfer rate
                val=dr;
            end
            % Round so that the averaging is done over an integer number of
            % points
            this.downsample_n=round(dr/val);
            notify(this,'NewSetting');
        end
        
        function val=get.downsampled_rate(this)
            val=this.demod_rate/this.downsample_n;
        end
        
        function set.fft_length(this, val)
            if val<1
                val=1;
            end
            % Round val to the nearest 2^n to make the calculation of
            % Fourier transform efficient
            n=round(log2(val));
            this.fft_length=2^n;
            notify(this,'NewSetting');
        end
        
        function val=get.fft_rbw(this)
            val=this.demod_rate/this.fft_length;
        end
        
        function set.fft_rbw(this, val)
            assert(val>0,'FFT resolution bandwidth must be greater than 0')
            % Rounding of fft_length to the nearest integer is handled by 
            % its own set method
            this.fft_length=this.demod_rate/val;
            notify(this,'NewSetting');
        end
    end
end

