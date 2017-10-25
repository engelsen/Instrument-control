function initRt(this)
this.base_dir='M:\Measurement Campaigns\';

addInstr(this,'RtOsc1','RT Oscilloscope 1 (Tektronix DPO 4034)',...
    'Scope','USB','0x0699::0x0413::C013397');
addInstr(this,'RtRsa','RSA 5103','RSA','192.168.1.3');
addInstr(this,'HeRsa','RSA 5106','RSA','192.168.1.5');

if this.enable_gui
    set(this.Gui.InstrumentMenu,'String',[{'Select the device'},...
        this.instr_names]);
    set(this.Gui.BaseDir,'String',this.base_dir);
end

end