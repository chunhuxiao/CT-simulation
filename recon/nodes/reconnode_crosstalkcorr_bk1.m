function [dataflow, prmflow, status] = reconnode_crosstalkcorr(dataflow, prmflow, status)
% recon node, crosstalk correction
% [dataflow, prmflow, status] = reconnode_crosstalkcorr(dataflow, prmflow, status);

% parameters to use in prmflow
Nview = prmflow.recon.Nview;
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;

% parameters set in pipe
crossprm = prmflow.pipe.(status.nodename);
if isfield(crossprm, 'weight')
    weight = crossprm.weight;
else
    weight = 1.0;
end

% calibration table
crscorr = prmflow.corrtable.(status.nodename);
crsorder = crscorr.order;
crsval = reshape(crscorr.main, [], crsorder);

% reshape
dataflow.rawdata = reshape(dataflow.rawdata, Npixel*Nslice, Nview);
% to intensity
dataflow.rawdata = 2.^(-dataflow.rawdata);
% correct
if crsorder == 1
	% the correction operator is a tridiagonal matrix [crsval; 1-crsval-crsval_2; crsval_2];
	crsval_2 = [crsval(2:end); 0];
	% rawfix
	rawfix = dataflow.rawdata.*(-crsval-crsval_2);
	rawfix(1:end-1, :) = rawfix(1:end-1, :) + dataflow.rawdata(2:end, :).*crsval_2(1:end-1);
	rawfix(2:end, :) = rawfix(2:end, :) + dataflow.rawdata(1:end-1, :).*crsval(2:end);
	% add to rawdata
	dataflow.rawdata = dataflow.rawdata + rawfix.*weight;
else
    error('Currently thhe crosstalk correction only support 1-order method.');
end
% min cut
minval = 2^-32;
dataflow.rawdata(dataflow.rawdata<minval) = minval;
% log2
dataflow.rawdata = -log2(dataflow.rawdata);

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end