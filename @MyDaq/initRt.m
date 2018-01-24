function initRt(this)
this.base_dir='M:\Measurement Campaigns\';
%addInstr(this, tag, name, type, interface, address)
addInstr(this,'RtOsc1','RT Oscilloscope 1 (Tektronix DPO 3034)',...
    'DPO','USB','0x0699::0x0413::C013397');
addInstr(this,'Rsa5103','RSA 5103','RSA','TCPIP','192.168.1.3');
addInstr(this,'Rsa5106','RSA 5106','RSA','TCPIP','192.168.1.5');
addInstr(this,'AgNa','Agilent NA','NA','TCPIP','192.168.1.4');

if this.enable_gui
    set(this.Gui.InstrMenu,'String',[{'Select the device'};...
        this.instr_names]);
    set(this.Gui.BaseDir,'String',this.base_dir);
end

end