function [dataflow, prmflow, status] = reconnode_housefieldcorr(dataflow, prmflow, status)
% recon node, housefield correction
% [dataflow, prmflow, status] = reconnode_housefieldcorr(dataflow, prmflow, status);

% tmp codes
HCscale = prmflow.pipe.Housefield.HCscale;
dataflow.rawdata = dataflow.rawdata.*HCscale;


% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end