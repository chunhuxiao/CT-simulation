function [prmflow, status] = reconinitial(prmflow, status)
% recon initial
% [prmflow, status] = reconinitial(prmflow, status)

% copy status.reconcfg to prmflow
if ~iscell(status.reconcfg)
    prmflow = structmerge(status.reconcfg, prmflow);
else
    prmflow = structmerge(status.reconcfg{status.series_index}, prmflow);
end

% reload sub-config file
prmflow = subconfigure(prmflow);

% clean
prmflow = iniprmclean(prmflow);

% ini calibration table
prmflow.corrtable = struct();

% ini recon
prmflow.recon = struct();

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];

end


function prmflow = iniprmclean(prmflow)
% to fill up the paramters which could be used in recon but not configured
% hard code

if ~isfield(prmflow.system, 'collimatorexplain')
    prmflow.system.collimatorexplain = [];
end
if ~isfield(prmflow, 'IOstandard')
    prmflow.IOstandard = [];
end

% explain focal spot
spots = fliplr(dec2bin(prmflow.protocol.focalspot)=='1');
prmflow.system.Nfocal = sum(spots);
prmflow.system.focalspot = find(spots);

end