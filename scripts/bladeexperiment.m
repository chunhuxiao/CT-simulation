% Cu blade experiment for fitting detector response

% CT system
CTsimupath = '../CTsimulation/';
addpath(genpath(CTsimupath));

configure_file = 'E:\matlab\calibration\system\configure_cali.xml';

% read configure file
configure = readcfgfile(configure_file);
% load configure
configure = configureclean(configure);
% system configure
SYS = systemconfigure(configure.system);
% phantom configure
SYS.phantom = phantomconfigure(configure.phantom);
% simulation prepare (load materials)
SYS = systemprepare(SYS);

% I know the 1st series is empty bowtie
i_series = 1;

SYS.protocol = protocolconfigure(configure.protocol.series{i_series});
SYS.protocol.series_index = i_series;
% load protocol (to SYS)
SYS = loadprotocol(SYS);

% projection 
Data = projectionscan(SYS, 'energyvector');

% I know the blades are
bladestep = 0.5;
blademaxthick = 20; 
blades = bladestep: bladestep: blademaxthick;

Nbld = length(blades);
Nw = SYS.source.Wnumber;
Npixel = double(SYS.detector.Npixel);
Nslice = double(SYS.detector.Nslice);
Np = Npixel*Nslice;
Nsmp = length(SYS.world.samplekeV);

Pbld = cell(1, Nw);
for iw = 1:Nw
    Pbld{iw} = ((Data.P{iw}(:)./Data.Pair{iw}(:)).^blades).*Data.Pair{iw}(:);
    Pbld{iw} = reshape(Pbld{iw}, Np, Nsmp, Nbld);
end
