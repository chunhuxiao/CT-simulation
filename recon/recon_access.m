function [dataflow, prmflow, status] = recon_access(dataflow, prmflow, status)
% recon & cali governing function
% [dataflow, prmflow, status] = recon_access(dataflow, prmflow, status)

switch lower(status.job)
    case 'readraw'
        dataflow = readrawdata(dataflow, status);
    otherwise 
        error(['Unknown job: ' status.job]);
end


end
