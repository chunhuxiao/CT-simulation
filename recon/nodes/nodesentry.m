function [dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, nodename)
% call nodes

switch lower(nodename)
    case 'initial'
        [prmflow, status] = reconinitial(prmflow, status);
    case 'loadrawdata'
        [dataflow, prmflow, status] = readrawdata(status.reconcfg, dataflow, prmflow, status);
    case 'loadcorrs'
        2;
    case 'log2'
        [dataflow, prmflow, status] = reconnode_log2(dataflow, prmflow, status);
    case {'aircorr', 'air'}
        4;
    case 'hccorr'
        5;
    case 'rebin'
        6;
    case 'filter'
        7;
    case 'backprojection'
        8;
    case 'statusmatrix'
        9;
    otherwise
        1;
end

end