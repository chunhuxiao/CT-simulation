% a projection script for single energy
clear;
% path
addpath(genpath('../'));
rootpath = 'D:/matlab/CTsimulation/';
datapath = 'D:/data/simulation/';

% IO configure file
rawdata_cfgfile = [rootpath, 'IO/standard/rawdata_v1.0.xml'];
aircorr_cfgfile = [rootpath, 'IO/standard/air_corr_v1.0.xml'];
detector_cfgfile = [rootpath, 'IO/standard/detector_corr_v1.0.xml'];

% data file
rawdata_file = [datapath, 'sample/rawdata_sample_project.raw'];
aircorr_file =  [datapath, 'sample/air_sample_v1.0.corr'];
detector_file = 'D:\matlab\ct\BCT16\detector\detector_BCT16.corr';

% load rawdata
raw = loadbindata(rawdata_file, rawdata_cfgfile);
% load corr tables
aircorr = loadbindata(aircorr_file, aircorr_cfgfile);
detector = loadbindata(detector_file, detector_cfgfile);

% data flow
rawhead.Angle_encoder = [raw.Angle_encoder];
rawhead.Reading_Number = [raw.Reading_Number];
rawhead.Integration_Time = [raw.Integration_Time];
rawhead.Reading_Number = [raw.Reading_Number];
rawhead.Time_Stamp = [raw.Time_Stamp];
rawhead.mA = [raw.mA];
rawhead.KV = [raw.KV];
rawdata = single([raw.Raw_Data]);

% protocal hardcode
%  collimator = 16x0.5
detector.position = reshape(detector.position, [], 3);
detector.focalposition = reshape(detector.focalposition, [], 3);
detector.position = reshape(detector.position, detector.Npixel, detector.Nslice, 3);
sliceindex = 5:20;
detector.position = reshape(detector.position(:, sliceindex, :), [], 3);
detector.Nslice = 16;
% prm
Nview = size(raw(:), 1);
Z0 = 16384;

% break
rawdata0 = rawdata;

% log2
rawdata = rawdata - Z0;
rawdata(rawdata<=0) = nan;
rawdata = -log2(rawdata) + log2(single(rawhead.Integration_Time));

% air correction
% most simplified
rawdata = rawdata + aircorr.main;

% HC
mu_ref = 0.020323982562342;
HCscale = 1000*log(2)/mu_ref;
rawdata = rawdata.*HCscale;

% rebin
% parameters
focalposition = detector.focalposition;
Npixel = double(detector.Npixel);
Nslice = double(detector.Nslice);
mid_U = double(detector.mid_U);
Nps = Npixel*Nslice;
viewangle = linspace(0, pi*2, Nview+1);
viewangle = viewangle(1:end-1);

% fan angles
y = detector.position(1:Npixel, 2) - focalposition(2);
x = detector.position(1:Npixel, 1) - focalposition(1);
fanangles = atan2(y, x);
% d is the distance from ray to ISO
Lxy = sqrt(x.^2+y.^2);
d = -detector.SID.*cos(fanangles);

% rebin 1
delta_view = pi*2/Nview;
f = fanangles./delta_view;
viewindex = double(floor(f));
interalpha = repmat(f-viewindex, Nslice, 1);
viewindex = viewindex + 1;  % start from 0
startvindex = mod(max(viewindex), Nview)+1;
viewindex = repmat(viewindex, Nslice, Nview) + repmat(0:Nview-1, Nps, 1);
vindex1 = mod(viewindex-1, Nview).*Nps + repmat((1:Nps)', 1, Nview);
vindex2 = mod(viewindex, Nview).*Nps + repmat((1:Nps)', 1, Nview);

% rawdata = reshape(rawdata, Nps, Nview);
A = zeros(Nps, Nview);
A(vindex1) = rawdata.*repmat(1-interalpha, 1, Nview);
A(vindex2) = A(vindex2) + rawdata.*repmat(interalpha, 1, Nview);

% start angle for first rebin view
A = [A(:, startvindex:end) A(:, 1:startvindex-1)];
viewangle = [viewangle(startvindex:end) viewangle(1:startvindex-1)];
startviewangle = viewangle(1);

% rebin 2 (QDO)
% reorder
[a1, a2] = QDOorder(Npixel, mid_U);
s1 = ~isnan(a1);
s2 = ~isnan(a2);
N_QDO = max([a1, a2]);
d_QDO = nan(size(d));
d_QDO(a1(s1)) = d(s1);
d_QDO(a2(s2)) = -d(s2);
A_QDO = zeros(N_QDO, Nslice*Nview/2);
A = reshape(A, Npixel, Nslice, Nview);
A_QDO(a1(s1), :) = A(s1, 1:Nslice*Nview/2);
A_QDO(a2(s2), :) = A(s2, Nslice*Nview/2+1:end);
% interp
delta_t = detector.hx_ISO/2.0;
t1 = ceil(min(d_QDO)/delta_t + 0.5);
t2 = floor(max(d_QDO)/delta_t + 0.5);
Nreb = t2-t1+1;
midchannel = -t1+1.5;
tt = ((t1:t2)-0.5)'.*delta_t;

fd = d_QDO./delta_t + 0.5;
dindex = floor(fd) - t1 + 2;
dindex(dindex<=0) = 1;
dindex(dindex>Nreb) = Nreb+1;
tindex = nan(Nreb+1, 1);
tindex(dindex) = 1:N_QDO;
tindex = fillmissing(tindex(1:end-1), 'previous');
interalpha = (tt - d_QDO(tindex))./(d_QDO(tindex+1)-d_QDO(tindex));

B_QDO = A_QDO(tindex,:).*repmat(1-interalpha, 1, Nslice*Nview/2) + A_QDO(tindex+1,:).*repmat(interalpha, 1, Nslice*Nview/2);
B_QDO = reshape(B_QDO, Nreb, Nslice, Nview/2);

% BP
% bp parameter
parallelbeam.Np = Nreb;
parallelbeam.midchannel = midchannel;
% parallelbeam.midchannel = 474.75;
parallelbeam.delta_d = delta_t;
parallelbeam.h = 500/512;
parallelbeam.viewangle = single(viewangle(1:Nview/2));
% parallelbeam.viewangle = mod(viewangle - pi/2, pi*2);
parallelbeam.N = 512;

% read filter
fid = fopen('D:\data\simulation\sample\BodySoft.bin.res');
myfilter = fread(fid, inf, 'single=>single');
fclose(fid);

Bimage = zeros(parallelbeam.N, parallelbeam.N, Nslice, 'single');
for islice = 1:Nslice
	Bimage(:,:, islice) = filterbackproj2D(squeeze(B_QDO(:, islice, :)), parallelbeam, myfilter);
%     Bimage(:,:, islice) = single(filterbackproj2D(squeeze(B_QDO(:, islice, :)), parallelbeam));
end

% Bimage = Bimage.*0.5;  % in using matlab filter