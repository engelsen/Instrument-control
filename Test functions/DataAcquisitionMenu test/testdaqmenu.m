 runDPO4034_1;
 runRSA5106;
 
 test_menu=DataAcquisitionMenu('InstrHandles',{GuiScopeDPO4034_1.Instr,GuiRsaRSA5106.Instr});
 
 test_daq=MyDaq('daq_menu_handle',test_menu);