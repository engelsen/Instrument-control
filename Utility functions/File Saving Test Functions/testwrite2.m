
save_dir='M:\Measurement Campaigns\2018-02-12 placeholder\';
file_path='M:\Measurement Campaigns\2018-02-12 placeholder\placeholder.txt';



hdr_spec='==';
x=1:1000;
y=x.^2;
test=MyTrace('x',x,'y',y);
save(test,'save_dir',save_dir);

% [Headers,title_line_no]=readAllMeasHeaders(file_path,hdr_spec,'Data');
% array_dlm=dlmread(file_path,'\t',title_line_no,0);
% x=array_dlm(:,1);
% y=array_dlm(:,2);