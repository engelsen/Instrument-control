%Testing tool for MyFit
clear
x_vec=linspace(0,10,100);

testFit=MyFit('fit_name','exponential','enable_gui',0);
params=cell(1,testFit.n_params);
for i=1:testFit.n_params
    params{i}=rand;
end
params{2}=-rand;

y_vec=testFit.FitStruct.(testFit.fit_name).anon_fit_fun(x_vec+rand(size(x_vec)),params{:});
figure(1)
ax=gca;
plot(x_vec,y_vec,'x');
hold on
testFit.plot_handle=ax;
testFit.enable_plot=1;
testFit.Data.x=x_vec;
testFit.Data.y=y_vec;
testFit.genInitParams;
testFit.init_params
testFit.fitTrace;
