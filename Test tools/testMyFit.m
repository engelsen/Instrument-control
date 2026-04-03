function testMyFit()
% testMyFit   Comprehensive tests for MyFit and all concrete subclasses.
%
% Tests parameter recovery on noise-free synthetic data, user parameter
% calculation, metadata generation, GUI creation/deletion, and the
% vectorize-replacement regex.
%
% Run from the Instrument-control root directory (or ensure all class
% folders are on the MATLAB path).

fprintf('\n=== MyFit Test Suite ===\n\n');
n_pass = 0;
n_fail = 0;

% ------------------------------------------------------------------ %
%  Helpers                                                            %
% ------------------------------------------------------------------ %

    function run(name, fn)
        try
            fn();
            fprintf('  PASS  %s\n', name);
            n_pass = n_pass + 1;
        catch ME
            fprintf('  FAIL  %s\n         %s\n', name, ME.message);
            n_fail = n_fail + 1;
        end
    end

    function assert_close(val, expected, rtol, label)
        % Passes if |val - expected| <= rtol * max(|expected|, atol/rtol)
        atol = 1e-9;
        ref  = max(abs(expected), atol / rtol);
        err  = abs(val - expected);
        assert(err <= rtol * ref, ...
            '%s: expected %.6g, got %.6g (rel err %.3g)', ...
            label, expected, val, err / ref);
    end

% ------------------------------------------------------------------ %
%  1.  Vectorisation regex                                            %
% ------------------------------------------------------------------ %

run('vectorise regex: anon_fit_fun accepts vector inputs', @() ...
    test_vectorise());

    function test_vectorise()
        % QuadraticFit has a^2 and * — good stress test for the regex
        Ft = MyQuadraticFit('enable_gui', false, 'enable_plot', false);
        x  = (1:5)';
        y  = Ft.anon_fit_fun(x, 1, 0, 0);   % should give [1;4;9;16;25]
        assert(isequal(y, x.^2), 'element-wise evaluation failed');
    end

% ------------------------------------------------------------------ %
%  2.  MyLinearFit  (polyfit override — Gof not set)                  %
% ------------------------------------------------------------------ %

run('MyLinearFit: parameter recovery via polyfit', @() test_linear());

    function test_linear()
        a0 = 2.5; b0 = -1.3;
        x  = linspace(-5, 5, 100)';
        y  = a0*x + b0;
        Ft = MyLinearFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        fitTrace(Ft);
        assert_close(Ft.param_vals(1), a0, 1e-6, 'gradient');
        assert_close(Ft.param_vals(2), b0, 1e-6, 'offset');
        % polyfit path: FitResult and Gof should remain empty
        assert(isempty(Ft.Gof), 'Gof should be empty for polyfit path');
    end

% ------------------------------------------------------------------ %
%  3.  MyQuadraticFit  (polyfit override)                             %
% ------------------------------------------------------------------ %

run('MyQuadraticFit: parameter recovery via polyfit', @() test_quadratic());

    function test_quadratic()
        a0 = 1.5; b0 = -2; c0 = 0.5;
        x  = linspace(-3, 3, 100)';
        y  = a0*x.^2 + b0*x + c0;
        Ft = MyQuadraticFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        fitTrace(Ft);
        assert_close(Ft.param_vals(1), a0, 1e-6, 'a');
        assert_close(Ft.param_vals(2), b0, 1e-6, 'b');
        assert_close(Ft.param_vals(3), c0, 1e-6, 'c');
    end

% ------------------------------------------------------------------ %
%  4.  MyGaussianFit                                                  %
% ------------------------------------------------------------------ %

run('MyGaussianFit: genInitParams + fitTrace', @() test_gaussian());

    function test_gaussian()
        a0 = 10; b0 = 1; c0 = 0.5; d0 = 1;
        x  = linspace(-5, 5, 300)';
        y  = a0 * exp(-((x - c0)/b0).^2 / 2) + d0;
        Ft = MyGaussianFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.param_vals(1), a0,  0.01, 'amplitude');
        assert_close(Ft.param_vals(2), b0,  0.01, 'width');
        assert_close(Ft.param_vals(3), c0,  0.01, 'center');
        assert_close(Ft.param_vals(4), d0,  0.01, 'offset');
    end

% ------------------------------------------------------------------ %
%  5.  MyLorentzianFit  (MyFitParamScaling)                           %
% ------------------------------------------------------------------ %

run('MyLorentzianFit: parameter recovery + confidence intervals', @() ...
    test_lorentzian());

    function test_lorentzian()
        a0 = 2; b0 = 0.1; c0 = 1; d0 = 0.5;
        x  = linspace(c0 - 1, c0 + 1, 500)';
        y  = 1/pi * a0 * b0/2 ./ ((x - c0).^2 + (b0/2)^2) + d0;
        Ft = MyLorentzianFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.param_vals(1), a0,  0.01, 'amplitude');
        assert_close(Ft.param_vals(2), b0,  0.01, 'width');
        assert_close(Ft.param_vals(3), c0,  0.01, 'center');
        assert_close(Ft.param_vals(4), d0,  0.01, 'offset');
        % Verify CI were computed: GoodnessOfFit section appears in metadata
        % (getConfInt is protected; this tests the same code path indirectly)
        Mdt = createMetadata(Ft);
        assert(any(strcmp({Mdt.title}, 'GoodnessOfFit')), ...
            'GoodnessOfFit missing — confidence intervals not computed');
    end

% ------------------------------------------------------------------ %
%  6.  MyDoubleLorentzianFit                                          %
% ------------------------------------------------------------------ %

run('MyDoubleLorentzianFit: two-peak recovery', @() ...
    test_double_lorentzian());

    function test_double_lorentzian()
        a0=2; b0=0.08; c0=0.5;
        d0=1.5; e0=0.08; f0=1.5;
        g0=0.1;
        x = linspace(0, 2, 1000)';
        y = 1/pi*b0/2*a0 ./ ((x-c0).^2+(b0/2)^2) + ...
            1/pi*e0/2*d0 ./ ((x-f0).^2+(e0/2)^2) + g0;
        Ft = MyDoubleLorentzianFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        % Identify which recovered peak is which by sorting centers
        ctrs = sort([Ft.param_vals(3), Ft.param_vals(6)]);
        assert_close(ctrs(1), c0, 0.02, 'center 1');
        assert_close(ctrs(2), f0, 0.02, 'center 2');
    end

% ------------------------------------------------------------------ %
%  7.  MyLorentzianGradFit                                            %
% ------------------------------------------------------------------ %

run('MyLorentzianGradFit: parameter recovery', @() ...
    test_lorentzian_grad());

    function test_lorentzian_grad()
        a0=2; b0=0.1; c0=1; d0=0.3; e0=0.5;
        x = linspace(0.5, 1.5, 500)';
        y = 1/pi*a0*b0/2 ./ ((x-c0).^2+(b0/2)^2) + d0*(x-c0) + e0;
        Ft = MyLorentzianGradFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.param_vals(2), b0, 0.02, 'width');
        assert_close(Ft.param_vals(3), c0, 0.02, 'center');
        assert_close(Ft.param_vals(4), d0, 0.05, 'gradient');
    end

% ------------------------------------------------------------------ %
%  8.  MyExponentialFit  (MyFitParamScaling)                          %
% ------------------------------------------------------------------ %

run('MyExponentialFit: parameter recovery', @() test_exponential());

    function test_exponential()
        a0=5; b0=-2; c0=1;
        x = linspace(0, 3, 200)';
        y = a0 * exp(b0*x) + c0;
        Ft = MyExponentialFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.param_vals(1), a0, 0.01, 'amplitude');
        assert_close(Ft.param_vals(2), b0, 0.01, 'rate');
        assert_close(Ft.param_vals(3), c0, 0.01, 'offset');
    end

% ------------------------------------------------------------------ %
%  9.  MyMechLorentzianFit  (user params: lw, freq, Q, Qf)           %
% ------------------------------------------------------------------ %

run('MyMechLorentzianFit: user params computed after fit', @() ...
    test_mech_lorentzian());

    function test_mech_lorentzian()
        freq_true = 1e6;   % Hz
        lw_true   = 1e3;   % Hz  (FWHM)
        a0=1; c0=freq_true; d0=0;
        x = linspace(c0 - 5*lw_true, c0 + 5*lw_true, 500)';
        y = 1/pi * a0 * lw_true/2 ./ ((x - c0).^2 + (lw_true/2)^2) + d0;
        Ft = MyMechLorentzianFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.lw,   lw_true,      0.01, 'linewidth (Hz)');
        assert_close(Ft.freq, freq_true/1e6, 0.01, 'frequency (MHz)');
        Q_true = (freq_true / lw_true) / 1e6;   % in units of 1e6
        assert_close(Ft.Q, Q_true, 0.01, 'Q (x10^6)');
    end

% ------------------------------------------------------------------ %
%  10. MyMechExponentialFit  (user params: tau, lw; freq user-input)  %
% ------------------------------------------------------------------ %

run('MyMechExponentialFit: tau and lw from exponential decay', @() ...
    test_mech_exp());

    function test_mech_exp()
        tau_true = 0.5;                      % s
        lw_true  = abs(-1/(pi * tau_true));  % Hz = 1/(pi*tau)
        a0 = 1; b0 = -1/tau_true; c0 = 0;
        x = linspace(0, 4, 300)';
        y = a0 * exp(b0*x) + c0;
        Ft = MyMechExponentialFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.tau, tau_true, 0.01, 'tau (s)');
        assert_close(Ft.lw,  lw_true,  0.01, 'linewidth (Hz)');
    end

% ------------------------------------------------------------------ %
%  11. MyOpticalLorentzianFit  (needs Axes for cursors)               %
% ------------------------------------------------------------------ %

run('MyOpticalLorentzianFit: constructs with axes, lw computed', @() ...
    test_optical());

    function test_optical()
        a0=2; b0=0.1; c0=1; d0=0;
        x = linspace(0.5, 1.5, 500)';
        y = 1/pi * a0 * b0/2 ./ ((x - c0).^2 + (b0/2)^2) + d0;
        fig = figure('Visible', 'off');
        ax  = axes(fig);
        Ft  = MyOpticalLorentzianFit('x', x, 'y', y, 'Axes', ax, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert(isfinite(Ft.lw), 'lw not computed or not finite');
        delete(Ft);
        delete(fig);
    end

% ------------------------------------------------------------------ %
%  12. MySpringShiftFit  (needs Axes; complex optomechanical fit)      %
% ------------------------------------------------------------------ %

run('MySpringShiftFit: constructs, fits without error', @() ...
    test_spring_shift());

    function test_spring_shift()
        a0=1; b0=0.1; c0=0.3; d0=0.1; e0=0.5;
        x = linspace(c0-0.5, c0+0.5, 500)';
        y = e0 * 4*(x-c0)*b0/2 ./ ((x-c0).^2+(b0/2)^2).^2 + ...
            1/pi*a0*b0/2 ./ ((x-c0).^2+(b0/2)^2) + d0;
        fig = figure('Visible', 'off');
        ax  = axes(fig);
        Ft  = MySpringShiftFit('x', x, 'y', y, 'Axes', ax, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        % Verify center recovery — most robust parameter
        assert_close(Ft.param_vals(3), c0, 0.05, 'center');
        delete(Ft);
        delete(fig);
    end

% ------------------------------------------------------------------ %
%  13. MyGorodetsky2000Fit                                            %
% ------------------------------------------------------------------ %

run('MyGorodetsky2000Fit: genInitParams + fitTrace', @() ...
    test_gorodetsky());

    function test_gorodetsky()
        a0=1; b0=0; c0=0; g0=0.05; k0_t=0.10; kex0=0.08;
        x = linspace(-0.5, 0.5, 500)';
        num = k0_t^2/4 - kex0^2/4 + g0^2/4 - (x-b0).^2 + 1i*k0_t*(x-b0);
        den = (k0_t+kex0)^2/4 + g0^2/4 - (x-b0).^2 + 1i*(x-b0)*(k0_t+kex0);
        y   = a0 * abs(num./den).^2 + c0*(x-b0);
        Ft  = MyGorodetsky2000Fit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.param_vals(2), b0, 0.05, 'center');
        assert(Ft.param_vals(5) > 0, 'k0 must be positive');
        assert(Ft.param_vals(6) > 0, 'kex must be positive');
    end

% ------------------------------------------------------------------ %
%  14. createMetadata                                                  %
% ------------------------------------------------------------------ %

run('createMetadata: returns populated object after nonlinear fit', @() ...
    test_metadata());

    function test_metadata()
        a0=2; b0=0.1; c0=1; d0=0;
        x = linspace(0.5, 1.5, 200)';
        y = 1/pi * a0 * b0/2 ./ ((x-c0).^2 + (b0/2)^2) + d0;
        Ft = MyLorentzianFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        fitTrace(Ft);
        Mdt = createMetadata(Ft);
        assert(~isempty(Mdt), 'metadata is empty');
        % FittingParameters section should contain the 4 params
        titles = {Mdt.title};
        assert(any(strcmp(titles, 'FittingParameters')), ...
            'FittingParameters section missing');
        assert(any(strcmp(titles, 'GoodnessOfFit')), ...
            'GoodnessOfFit section missing');
    end

% ------------------------------------------------------------------ %
%  15. GUI creation and deletion                                       %
% ------------------------------------------------------------------ %

run('GUI: creates figure, slider listeners, deletes cleanly', @() ...
    test_gui());

    function test_gui()
        x = linspace(-1, 1, 50)';
        y = 2*x + 1;
        Ft = MyLinearFit('x', x, 'y', y, ...
            'enable_gui', true, 'enable_plot', false);
        assert(isfield(Ft.Gui, 'Window') && isvalid(Ft.Gui.Window), ...
            'GUI window not created');
        % Sliders and their PostSet listeners should exist for each param
        for k = 1:Ft.n_params
            sname = sprintf('Slider_%s', Ft.fit_params{k});
            lname = [sname, '_listener'];
            assert(isfield(Ft.Gui, sname),  'slider handle missing');
            assert(isfield(Ft.Gui, lname),  'slider listener missing');
        end
        delete(Ft);   % should not throw
    end

% ------------------------------------------------------------------ %
%  16. setFitParams / clearFit public interface                       %
% ------------------------------------------------------------------ %

run('setFitParams: updates params; clearFit: empties fit trace', @() ...
    test_manual_set());

    function test_manual_set()
        a0=2; b0=0.1; c0=1; d0=0;
        x = linspace(0.5, 1.5, 200)';
        y = 1/pi * a0 * b0/2 ./ ((x-c0).^2+(b0/2)^2) + d0;
        Ft = MyLorentzianFit('x', x, 'y', y, ...
            'enable_gui', false, 'enable_plot', false);
        fitTrace(Ft);
        assert(~isempty(Ft.FitResult), 'FitResult should be set after fit');
        % setFitParams is the public way to change parameter values
        new_vals = Ft.param_vals * 2;
        setFitParams(Ft, new_vals);
        assert(isequal(Ft.param_vals, new_vals), 'setFitParams did not update param_vals');
        % clearFit should empty the fit trace data
        clearFit(Ft);
        assert(isempty(Ft.Fit.x), 'clearFit should empty Fit.x');
    end

% ------------------------------------------------------------------ %
%  17. Range cursor data selection                                     %
% ------------------------------------------------------------------ %

run('Range cursors: data_selection restricts fit range', @() ...
    test_range_cursors());

    function test_range_cursors()
        % Fit only the right half of the data; the left half is noisy
        a0=2; b0=0.1; c0=1.5; d0=0;
        x = linspace(0, 2, 500)';
        y_clean = 1/pi*a0*b0/2./((x-c0).^2+(b0/2)^2) + d0;
        y = y_clean;
        y(x < 1) = y(x < 1) + 100;   % corrupt left half
        fig = figure('Visible', 'off');
        ax  = axes(fig);
        Ft  = MyLorentzianFit('x', x, 'y', y, 'Axes', ax, ...
            'enable_gui', false, 'enable_plot', false, ...
            'enable_range_cursors', true);
        % Place cursors to exclude the corrupted region
        Ft.RangeCursors(1).value = 1.0;
        Ft.RangeCursors(2).value = 2.0;
        genInitParams(Ft);
        fitTrace(Ft);
        assert_close(Ft.param_vals(3), c0, 0.02, 'center inside range');
        delete(Ft);
        delete(fig);
    end

% ------------------------------------------------------------------ %
%  Summary                                                            %
% ------------------------------------------------------------------ %

fprintf('\n=== %d passed, %d failed ===\n\n', n_pass, n_fail);
if n_fail == 0
    fprintf('All tests passed.\n\n');
else
    fprintf('%d test(s) FAILED.\n\n', n_fail);
end

end
