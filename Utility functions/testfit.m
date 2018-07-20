%Testing tool for MyFit
clear
x_vec=linspace(0,200,1000);

testFit=MyFit('fit_name','lorentzian','enable_gui',1);
params=cell(1,testFit.n_params);
for i=1:testFit.n_params
    params{i}=5*rand;
end
params{3}=200*rand;

params
y_vec=testFit.FitStruct.(testFit.fit_name).anon_fit_fun(x_vec,params{:}).*normrnd(1,0.04,size(x_vec));
figure(1)
ax=gca;
plot(x_vec,y_vec,'x');
axis([min(x_vec),max(x_vec),0.5*min(y_vec),1.5*max(y_vec)]);
hold on
testFit.plot_handle=ax;
testFit.enable_plot=1;
testFit.Data.x=x_vec;
testFit.Data.y=y_vec;
% testFit.genInitParams;
% testFit.init_params
% testFit.fitTrace;
% testFit.init_params