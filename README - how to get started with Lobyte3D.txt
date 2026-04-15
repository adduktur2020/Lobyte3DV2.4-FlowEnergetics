Welcome to Lobyte 3Dv2.4, the reduced-complexity dispersive flow fan model. See Burgess et al (2019) and Tahiru et al. 2024; 2026 for more details of this model and what it does, 
but to get started, just follow these simple instructions

Double-click on Lobyte3D.m to start Matlab and load this source code file

To run the model with a specified parameter input file, on the Matlab command line type:
lobyte3D modelInputParameters/FrdFan.txt

Note that to run the model for different target Froude number, the basal friction should be changed as specified in the parameter file.

Also, in the folder codeRunSpecificModels you will find Matlab code to run specific models and combinations of models - 
these may not all work without the associated parameter files, but they are good examples to see how to set up several model runs to run automatically

Other sub folders are:
modelInputParameters		- all the input parameter information that Lobyte3D needs is kept in here
modelOutput			- Lobyte3D output files are all kept in here. Note that the main output file containing saved strata is named using the model name parameter which is the first input parameter
postProcessing			- all the files used to carry out synthetic seismic modelling and other results


