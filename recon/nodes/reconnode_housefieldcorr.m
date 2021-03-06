function [dataflow, prmflow, status] = reconnode_housefieldcorr(dataflow, prmflow, status)
% recon node, housefield correction
% [dataflow, prmflow, status] = reconnode_housefieldcorr(dataflow, prmflow, status);

% parameters set in pipe
HCprm = prmflow.pipe.(status.nodename);

if isfield(HCprm, 'HCscale')
    HCscale = HCprm.HCscale;
else
    HCscale = 1000;
end

% tmp codes
dataflow.rawdata = dataflow.rawdata.*HCscale;

% NOTE: HCscale should be different for the slices, which shall be defined by a calibration table.
% TBC

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end