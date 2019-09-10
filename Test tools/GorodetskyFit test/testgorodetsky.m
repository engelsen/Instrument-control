load('testmat')
figure(124)
ax=gca;
testfit=MyFit('fit_name','Gorodetsky2000','x',xf,'y',yf,'Axes',ax,...
    'enable_gui',true,'enable_plot',true);
testfit.Data.plot(ax);
hold on
testfit.genInitParams;
testfit.init_params(1)
testfit.init_params(3:end)
testfit.plotInitFun;
testfit.fitTrace;
testfit.plotFit('Color','r');
testfit.Gof
testfit.FitInfo