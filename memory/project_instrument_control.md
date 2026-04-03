---
name: Instrument-control project state
description: MATLAB instrument control repo — active work on MyFit class refactor and test suite
type: project
---

Repo at `/Users/nilsenge/Library/CloudStorage/Dropbox/MATLAB/Instrument-control`, branch `confint-fix`.

Active work on `@MyFit` and `Fit classes/`:
- Removed deprecated Java slider (`uicomponent`/`jslider`) — replaced with native `uicontrol` slider + `addlistener` PostSet for continuous drag replot + `drawnow limitrate`
- Replaced deprecated `vectorize()` with `regexprep(expr, '(?<!\.)([*/^])', '.$1')`
- Fixed pre-existing bugs in `MyGaussianFit`, `MyLorentzianFit`, `MyLorentzianGradFit`, `MyDoubleLorentzianFit` (calcInitParams return-value pattern, findpeaks empty-return handling, renamed `coeffs`→`param_vals`, missing `createUserParamList`)
- Fixed `genSliderVecs` in `MyDoubleLorentzianFit`, `MyLorentzianGradFit`, `MyGorodetsky2000Fit`: `validateData(this)` → `validateData(this.Data)`, `this.x_vec` → `this.Data.x`, `this.init_params` → `this.param_vals`
- Fixed save panel in `createGui.m`: `annotation()` objects don't register as `uix.VBox` children in modern MATLAB — replaced with `uicontrol('Style','text')`
- Test suite at `Test tools/testMyFit.m` — run with `testMyFit()`
- Interactive demo at `Test tools/demoMyFit.m` — run with `Ft = demoMyFit()`

**TODO: migrate GUI from `figure`/`uicontrol` to `uifigure`**
- Goal: replace ugly `uicontrol` sliders with `uislider`
- `uifigure` is fully programmatic — no App Designer/`.mlapp` required
- `uix.VBox/HBox` → `uigridlayout`; `uicontrol` slider → `uislider` with native `ValueChangingFcn` (no PostSet listener hack needed)
- Only `createGui.m` and `createUserControls.m` need rewriting; all subclasses and class architecture stay untouched
- Defer until a dedicated session

**Why:** `confint-fix` branch — original goal appears to be fixing confidence interval functionality; the Java slider and vectorize issues were additional deprecations found along the way.

**How to apply:** When resuming, check test suite passes first. Branch has many unrelated whitespace changes — review before merging to master.

Obsidian notes: `Projects/Instrument-control/Instrument Control.md` (parent) and `Projects/Instrument-control/MyFit Refactor.md` (detail).
