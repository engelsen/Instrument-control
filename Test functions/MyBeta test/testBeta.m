file_path='M:\Measurement Campaigns\2016-09-27 A8CD15 g0\beta_cal_4.018MHz.txt';

test=MyBeta;

test.Data.load(file_path);
%Should give beta_02=0.9046 and beta_01=0.8958
% test.calcBeta;