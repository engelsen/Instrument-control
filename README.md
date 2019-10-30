# Instrument-control
The repository contains various MATLAB objects made for controlling instruments. The superclass `MyInstrument` has some basic functionality the subclasses can use. The MyTrace object is made for simple loading, saving and plotting of data and passing the data around with associated units and tags.

## Dependencies
The software is tested with MATLAB 2019b
* Most instrument classes rely on [Instrument Control Toolbox](https://ch.mathworks.com/products/instrument.html?s_tid=FX_PR_info)

* `MyFit` classes need [GUI Layout Toolbox](https://ch.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox), [UICOMPONENT toolbox](http://ch.mathworks.com/matlabcentral/fileexchange/14583-uicomponent-expands-uicontrol-to-all-java-classes) and [Signal Processing Toolbox](https://ch.mathworks.com/products/signal.html)

* The control class for HighFiness wavelengthmeters needs [MATLAB Support for MinGW-w64 C/C++ Compiler](https://ch.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-compiler)