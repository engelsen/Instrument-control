function initRt(this)
this.base_dir='M:\Measurement Campaigns\';

if this.enable_gui
    set(this.Gui.InstrumentMenu,'String',{'Select the device',...
        'RT Oscilloscope 1 (Tektronix DPO 4034)',...
        'UHF Lock-in Amplifier (Zurich Instrument)',...
        'RT Spectrum Analyzer (RSA)',...
        'Oscilloscope 2 (Agilent DSO7034A)',...
        'Network Analyzer (Agilent E5061B)'});
    set(this.Gui.BaseDir,'String',this.base_dir);
end

end