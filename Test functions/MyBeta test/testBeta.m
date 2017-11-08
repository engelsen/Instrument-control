file_path='C:\Users\engelsen\Documents\MATLAB\beta_cal_4.018MHz.txt';

test=MyBeta;

test.Data.loadTrace(file_path);
%Should give beta_02=0.9046 and beta_01=0.8958
% test.calcBeta;