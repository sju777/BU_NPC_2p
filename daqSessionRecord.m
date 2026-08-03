% daqSessionRecord begins background data acquisition of the data
% acquisition session
% 
% updated by Mai-Anh Vu, 10/24/18 to be a standalone module
% updated by Mai-Anh Vu, 10/29/18 to be general for a daq session

global session % our global variable to store everything

% start background data acquisition
session.nidaq.s.startBackground;
