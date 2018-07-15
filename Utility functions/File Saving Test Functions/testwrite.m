clear
save_dir='M:\Measurement Campaigns\2018-02-12 placeholder\';
file_path='M:\Measurement Campaigns\2018-02-12 placeholder\placeholder.txt';



hdr_spec='==';


Headers=struct('Date',struct(),'Instrument',struct());

time_vec=datevec(datetime('now'));
Headers.Date.year=time_vec(1);
Headers.Date.month=time_vec(2);
Headers.Date.day=time_vec(3);
Headers.Date.hour=time_vec(4);
Headers.Date.minute=time_vec(5);
Headers.Date.second=floor(time_vec(6));
Headers.Date.microsecond=round(1000*(time_vec(6)-Headers.Date.second));
Headers.Date.str_spec={'d','d','d','d','d','d','d'};

Headers.Instrument.Param1=1000;
Headers.Instrument.Param2='test';
Headers.Instrument.Param6=12490124e-123;
Headers.Instrument.Param7='test123m,masdf';
Headers.Instrument.str_spec={'d','s','d','s'};


x=1:1000;
y=x.^2;
test=MyTrace('x',x,'y',y);
save(test,'MeasHeaders',Headers,'save_dir',save_dir);

[titles,title_line_no]=readAllMeasHeaders(file_path,hdr_spec,'Data');
array_dlm=dlmread(file_path,'\t',title_line_no,0);
x=array_dlm(:,1);
y=array_dlm(:,2);