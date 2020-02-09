function reconxml = simuresultsoutput(SYS, Data)
% outpu the simualtion results (rawdata, calibration tables and reconxml)
% reconxml = simuresultsoutput(SYS, Data);

% output the rawdata and air (no offset?)
rawdataoutput(SYS, Data);

% output calibration tables
corrtableoutput(SYS, Data);

% recon xml
[~, reconxml] = reconxmloutput(SYS);

end