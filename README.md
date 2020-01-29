# Instrument-control
The repository contains various MATLAB objects for controlling instruments (from command line and from GUIs), recording and saving data traces with metadata, and for interactive data analysis.

For more detailed information please refer to the project [Wiki](https://github.com/engelsen/Instrument-control/wiki) 

## Dependencies
The software is tested with MATLAB 2019b. Additional toolboxes required:
* Most instrument classes use [Instrument Control Toolbox](https://ch.mathworks.com/products/instrument.html?s_tid=FX_PR_info)

* `MyFit` classes need [Curve Fitting Toolbox](https://www.mathworks.com/products/curvefitting.html) and [Signal Processing Toolbox](https://ch.mathworks.com/products/signal.html)

* The control class for HighFiness wavelengthmeters needs [MATLAB Support for MinGW-w64 C/C++ Compiler](https://ch.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-compiler)
