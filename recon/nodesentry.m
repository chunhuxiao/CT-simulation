function [dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, nodename)
% call nodes

status.nodename = nodename;
switch lower(nodename)
    case 'statusmatrix'
        % TBC
        0;
    case 'initial'
        % initial, what ever call this first
        [prmflow, status] = reconinitial(prmflow, status);
    case {'loadrawdata', 'readraw'}
        % read rawdata
        [dataflow, prmflow, status] = readrawdata(status.reconcfg, dataflow, prmflow, status);
    case 'loadcorrs'
        % load calibration tables
        [prmflow, status] = loadcalitables(prmflow, status);
    case 'log2'
        % log2
        [dataflow, prmflow, status] = reconnode_log2(dataflow, prmflow, status);
    case {'aircorr', 'air'}
        % air correction
        [dataflow, prmflow, status] = reconnode_aircorr(dataflow, prmflow, status);
    case 'badchannel'
        % fix badchannel
        [dataflow, prmflow, status] = reconnode_badchannelcorr(dataflow, prmflow, status);
    case {'crosstalk'}
        % crosstalk correction
        [dataflow, prmflow, status] = reconnode_crosstalkcorr(dataflow, prmflow, status);
    case {'beamharden', 'nonlinear'}
        % beam harden correction
        [dataflow, prmflow, status] = reconnode_beamhardencorr(dataflow, prmflow, status);
    case 'housefield'
        % Housefield CT value correction
        [dataflow, prmflow, status] = reconnode_housefieldcorr(dataflow, prmflow, status);
    case 'axialrebin'
        % rebin for axial
        [dataflow, prmflow, status] = reconnode_Axialrebin(dataflow, prmflow, status);
    case 'filter'
        % filter
        [dataflow, prmflow, status] = reconnode_Filter(dataflow, prmflow, status);
    case {'backproject', 'backprojection', 'bp'}
        % back projection
        [dataflow, prmflow, status] = reconnode_Backprojection(dataflow, prmflow, status);
    case 'fbp'
        % temporary FBP function
        [dataflow, prmflow, status] = reconnode_FBPtmp(dataflow, prmflow, status);
    % calibration
    case 'aircali'
        % air calibration
        [dataflow, prmflow, status] = reconnode_aircali(dataflow, prmflow, status);
    case 'inverserebin'
        % inverse the rebin, from parallel beams back to fan 
        [dataflow, prmflow, status] = reconnode_inverserebin(dataflow, prmflow, status);
    case {'databackup', 'backup'}
        % backup inner data
        [dataflow, prmflow, status] = reconnode_databackup(dataflow, prmflow, status);
    case {'dataoutput', 'output'}
        % output image or calibration table to files
        [dataflow, prmflow, status] = reconnode_dataoutput(dataflow, prmflow, status);
    case 'datamean'
        % calculate the mean of rawdata
        [dataflow, prmflow, status] = reconnode_datamean(dataflow, prmflow, status);
    otherwise
        % function handle, call a function in name of reconnode_nodename
        myfun = str2func(['reconnode_' nodename]);
        [dataflow, prmflow, status] = myfun(dataflow, prmflow, status);
        % It is a flexible way to include any recon nodes.
        % But we suggest to register a node's name in above cases, that 
        % will be easy to set breaks for debug.
end

end