function Ft = demoMyFit()
% demoMyFit  Interactive demo for MyFit subclasses.
%
% Opens a dialog to choose a fit type, generates noisy synthetic data,
% plots it, and launches the fit GUI linked to the same axes so you can
% adjust sliders, run fits, and inspect results interactively.
%
% Returns the fit object so you can inspect it from the command line:
%   Ft = demoMyFit();
%   Ft.param_vals
%   Ft.Gof

% ------------------------------------------------------------------ %
%  Pick fit type                                                       %
% ------------------------------------------------------------------ %

labels = { ...
    'Lorentzian           (MyMechLorentzianFit)', ...
    'Exponential decay    (MyMechExponentialFit)', ...
    'Gaussian             (MyGaussianFit)', ...
    'Double Lorentzian    (MyDoubleLorentzianFit)', ...
    'Lorentzian + slope   (MyLorentzianGradFit)', ...
    'Gorodetsky 2000      (MyGorodetsky2000Fit)' ...
};

idx = listdlg( ...
    'ListString',    labels, ...
    'SelectionMode', 'single', ...
    'Name',          'demoMyFit', ...
    'PromptString',  'Choose a fit type:', ...
    'ListSize',      [320, 130]);

if isempty(idx)
    fprintf('Cancelled.\n');
    Ft = [];
    return
end

% ------------------------------------------------------------------ %
%  Generate synthetic data for the chosen fit                         %
% ------------------------------------------------------------------ %

rng(42);   % reproducible noise

switch idx

    case 1  % ----- MyMechLorentzianFit --------------------------------
        % a=5e4 gives peak amplitude ~1 above background (2a/(pi*lw) ≈ 1.06)
        freq = 1e6;  lw = 3e4;  area = 5e4;  bg = 0.05;
        x = linspace(freq - 6*lw, freq + 6*lw, 600)';
        y_clean = 1/pi * area * lw/2 ./ ((x - freq).^2 + (lw/2)^2) + bg;
        y = y_clean + 0.01 * max(y_clean) * randn(size(x));
        title_str = sprintf('Lorentzian  |  f_0 = %.3g MHz,  lw = %.3g kHz', ...
            freq/1e6, lw/1e3);
        FitClass = @MyMechLorentzianFit;

    case 2  % ----- MyMechExponentialFit --------------------------------
        tau = 0.8;  a = 1;  c = 0.02;  f_mhz = 2;
        x = linspace(0, 4, 400)';
        y_clean = a * exp(-x / tau) + c;
        y = y_clean + 0.02 * randn(size(x));
        title_str = sprintf('Exponential decay  |  \\tau = %.2g s,  f = %.3g MHz', ...
            tau, f_mhz);
        FitClass = @MyMechExponentialFit;

    case 3  % ----- MyGaussianFit ---------------------------------------
        amp = 8;  sigma = 0.6;  ctr = 1.5;  offset = 1;
        x = linspace(-2, 5, 400)';
        y_clean = amp * exp(-((x - ctr)/sigma).^2 / 2) + offset;
        y = y_clean + 0.15 * randn(size(x));
        title_str = sprintf('Gaussian  |  a = %.3g,  \\sigma = %.3g,  c = %.3g', ...
            amp, sigma, ctr);
        FitClass = @MyGaussianFit;

    case 4  % ----- MyDoubleLorentzianFit --------------------------------
        a1=2; w1=0.06; c1=0.5;
        a2=1.5; w2=0.07; c2=1.5;
        bg=0.08;
        x = linspace(0, 2, 800)';
        y_clean = 1/pi*w1/2*a1./((x-c1).^2+(w1/2)^2) + ...
                  1/pi*w2/2*a2./((x-c2).^2+(w2/2)^2) + bg;
        y = y_clean + 0.03 * max(y_clean) * randn(size(x));
        title_str = sprintf('Double Lorentzian  |  c_1 = %.2g,  c_2 = %.2g', c1, c2);
        FitClass = @MyDoubleLorentzianFit;

    case 5  % ----- MyLorentzianGradFit ----------------------------------
        a=3; w=0.1; c=1; grad=1.5; offset=0.5;
        x = linspace(0.5, 1.5, 500)';
        y_clean = 1/pi*a*w/2./((x-c).^2+(w/2)^2) + grad*(x-c) + offset;
        y = y_clean + 0.02 * max(abs(y_clean)) * randn(size(x));
        title_str = sprintf('Lorentzian + slope  |  c = %.3g,  w = %.3g', c, w);
        FitClass = @MyLorentzianGradFit;

    case 6  % ----- MyGorodetsky2000Fit -----------------------------------
        a=1; b=0; slope=0; gam=0.05; k0=0.10; kex=0.07;
        x = linspace(-0.5, 0.5, 600)';
        num = k0^2/4 - kex^2/4 + gam^2/4 - (x-b).^2 + 1i*k0*(x-b);
        den = (k0+kex)^2/4 + gam^2/4 - (x-b).^2 + 1i*(x-b)*(k0+kex);
        y_clean = a * abs(num./den).^2 + slope*(x-b);
        y = y_clean + 0.01 * randn(size(x));
        title_str = sprintf('Gorodetsky 2000  |  k_0 = %.3g,  k_{ex} = %.3g', k0, kex);
        FitClass = @MyGorodetsky2000Fit;

end

% ------------------------------------------------------------------ %
%  Create figure, plot data, launch fit GUI                           %
% ------------------------------------------------------------------ %

fig = figure('Name', 'demoMyFit', 'NumberTitle', 'off');
ax  = axes(fig);

% Plot raw data in grey first so fit curve renders on top
plot(ax, x, y, '.', 'Color', [0.65 0.65 0.65], 'MarkerSize', 5, ...
    'DisplayName', 'Data');
hold(ax, 'on');
title(ax, title_str, 'Interpreter', 'tex');

% Create fit object — constructor calls genInitParams automatically
% and plots the initial guess curve into ax
Ft = FitClass('x', x, 'y', y, 'Axes', ax, ...
    'enable_gui', true, 'enable_plot', true, 'save_panel', true);

% Pre-fill freq for MechExponentialFit (normally user-entered)
if idx == 2
    Ft.freq = f_mhz;
end

fprintf('\nTrue parameters for this demo:\n');
switch idx
    case 1, fprintf('  freq = %.3g MHz,  lw = %.3g kHz,  a = %.3g,  bg = %.3g  (peak ≈ %.3g)\n', freq/1e6, lw/1e3, area, bg, 2*area/(pi*lw)+bg);
    case 2, fprintf('  tau = %.3g s,  rate = %.3g s^-1,  amp = %.3g,  offset = %.3g\n', tau, 1/tau, a, c);
    case 3, fprintf('  amp = %.3g,  sigma = %.3g,  center = %.3g,  offset = %.3g\n', amp, sigma, ctr, offset);
    case 4, fprintf('  c1 = %.3g,  w1 = %.3g,  c2 = %.3g,  w2 = %.3g\n', c1, w1, c2, w2);
    case 5, fprintf('  amp = %.3g,  width = %.3g,  center = %.3g,  grad = %.3g\n', a, w, c, grad);
    case 6, fprintf('  k0 = %.3g,  kex = %.3g,  gamma = %.3g,  center = %.3g\n', k0, kex, gam, b);
end
fprintf('\nFit object returned as Ft. Use Ft.param_vals, Ft.Gof etc.\n\n');

end
