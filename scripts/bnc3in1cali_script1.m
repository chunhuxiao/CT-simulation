%% step 0. blade experiment
% to get the response curve, e.g. E:\matlab\CT\SINO\TM\detector\response_1219.mat
% skip

%% step1. beam harden #1

% inputs
% configure files
% calioutputpath = 'E:\data\simulation\cali\';
% % system_cfgfile = 'E:\matlab\CT\SINO\TM\system_configure_TM_basic.xml';
% system_cfgfile = 'E:\matlab\CT\SINO\TM\system_configure_TM_arti.xml';
% protocol_cfgfile = 'E:\matlab\CTsimulation\cali\calixml\protocol_beamharden.xml';
calioutputpath = 'D:\matlab\ct\BCT16\calibration\1\';
system_cfgfile = 'D:\matlab\ct\BCT16\BHtest\system_cali.xml';
protocol_cfgfile = 'D:\matlab\CTsimulation\cali\calixml\protocol_beamharden.xml';
% prepared rawdata
rawdata_file_empty = {[], [], 'E:\data\rawdata\bhtest\rawdata_staticair_120KV200mA_empty_v1.0.raw', []};
rawdata_file_body = {[], [], 'E:\data\rawdata\bhtest\rawdata_staticair_120KV200mA_large_v1.0.raw', []};
rawdata_file_head = {[], [], [], []};
rawdata_file = {rawdata_file_empty, rawdata_file_body, rawdata_file_head};
% % the rawdata_file should includes:
% % {air_80kV_empty, air_100kV_empty, air_120kV_empty, air_140kV_empty}, 
% % {air_80kV_body, air_100kV_body, air_120kV_body, air_140kV_body}, 
% % {air_80kV_head, air_100kV_head, air_120kV_head, air_140kV_head}
% % for each BH table (8 tables).
% response_file = 'E:\matlab\CT\SINO\TM\detector\response_1219.mat';
response_file = '';
% scan data method
scan_data_method = 'prep';      % 'prep', 'real' or 'simu'.

% view skip in meaning the rawdata
viewskip = 200;
% bad channel
badchannelindex = [2919 12609];
% pipe
pipe_bh = struct();
pipe_bh.Log2 = [];
pipe_bh.Badchannel = struct();
pipe_bh.Badchannel.badindex = badchannelindex;
pipe_bh.datamean.viewskip = viewskip;
pipe_bh.databackup.dataflow = 'rawdata';
pipe_bh.databackup.index = [];

% system configure
configure.system = readcfgfile(system_cfgfile);
configure.protocol = readcfgfile(protocol_cfgfile);
configure = configureclean(configure);
Nseries = configure.protocol.seriesnumber;
% prepare data
switch scan_data_method
    case 'simu'
        % do simulation to get the raw data
        scanxml = CTsimulation(configure);
    case 'real'
        % do real scan
        scanxml = cell(1, Nseries);
        SYS = systemconfigure(configure.system);
        SYS = systemprepare(SYS);
        % loop the series
        for i_series = 1:Nseries
            % I know the series 1,2,3 should be empty, body and head bowtie
            SYS.protocol = protocolconfigure(configure.protocol.series{i_series});
            SYS.protocol.series_index = i_series;    
            % load protocol (to SYS)
            SYS = loadprotocol(SYS);
            % reconxml
            [scanprm, scanxml{i_series}] = reconxmloutput(SYS);
            % scan data
            fprintf('scan data... ');
            % use the scanprm{iw}.protocol to scan data on real CT
            % TBC
            pause();
            % JUST A SAMPLE
        end
    case 'prep'
        % data has been prepared
        scanxml = cell(1, Nseries);
        % or
        % I know we have done this
        load('D:\matlab\ct\BCT16\BHtest\1\scanxml.mat');
        % do nothing
    otherwise
        error('Unknown method %s', scan_data_method);
end

% replace the response
configure.system.detector.spectresponse = response_file;
SYS = systemconfigure(configure.system);
SYS = systemprepare(SYS);

% The projection of air (for bowtie), simulation and real scan
Nseries = configure.protocol.seriesnumber;
P = struct();
bhcalixml = struct();
dataflow = struct();
% loop the series
for i_series = 1:Nseries
    % I know the series 1,2,3 should be empty, body and head bowtie
    SYS.protocol = protocolconfigure(configure.protocol.series{i_series});
    SYS.protocol.series_index = i_series;    
    % load protocol (to SYS)
    SYS = loadprotocol(SYS);
    % the bowtie is
    bowtie = lower(SYS.protocol.bowtie);
    % KVs
    Nw = SYS.source.Wnumber;
    % air projection
    Data = airprojection(SYS, 'energyvector');
    
    % get simulation data (ideal air)
    P.(bowtie) = Data.Pair;
    
    % get experiment data (scan air)
    if ~isempty(scanxml{i_series})
        bhcalixml.(bowtie) = readcfgfile(scanxml{i_series});
    else
        % prepared data?
        bhcalixml.(bowtie).recon = reconxmloutput(SYS, 0);
        for iw = 1:Nw
            if isfield(rawdata_file, bowtie) && ~isempty(rawdata_file.(bowtie){iw})
                % set prepared data
                bhcalixml.(bowtie).recon{iw}.rawdata = rawdata_file.(bowtie){iw};
            else
                % delete 
                bhcalixml.(bowtie).recon{iw} = struct();
            end
        end 
    end
    % replace pipe
    for iw = 1:Nw
        bhcalixml.(bowtie).recon{iw}.pipe = pipe_bh;
    end
    % run the pipes
    [~, dataflow.(bowtie)] = CTrecon(bhcalixml.(bowtie));
end

% fix the bowtie thickness curve by fitting the simulation with experiment data,
% and get the beam harden correction base on the fixed bowtie curve

% set SYS.output
SYS.output.corrtable = 'beamharden';
% ini the return (corr file name)
BHcalitable = struct();
% loop the body and head
for i_series = 1:Nseries
    SYS.protocol = protocolconfigure(configure.protocol.series{i_series});
    bowtie = lower(SYS.protocol.bowtie);
    if strcmpi(bowtie, 'empty')
        % skip the BH correction for empty bowtie
        continue;
    end
    SYS.protocol.series_index = i_series;
    % load protocol (to SYS)
    SYS = loadprotocol(SYS);
    
    % paramters to use
    Npixel = SYS.detector.Npixel;
    Nslice = max(SYS.detector.slicemerge);      % slice number after merge
    Nps = Npixel*Nslice;
    KV = SYS.protocol.KV;
    Nw = SYS.source.Wnumber;
    % material of the bowtie to fix
    mu_1 = SYS.collimation.bowtie{1}.material.mu_total(:);
    samplekeV = SYS.world.samplekeV(:);
    
    % ini the results
    BHcalitable.(bowtie) = cell(1, Nw);
    % loop KV
    for iw = 1:Nw
        rawmean = ['rawdata_bk' num2str(iw)];
        if ~isfield(dataflow.(bowtie), rawmean)
            continue;
        end
        % the simulated effective empty bowtie
        Dempty = log(P.empty{iw}*samplekeV);
        % the experiment effective bowtie thickness
        Dexp = (dataflow.(bowtie).(rawmean) - dataflow.empty.(rawmean)).*log(2);
        % try to fit the thickness fix 'dfit' to satisfy Dbowtie(dfit)-Dempty = Dexp.
        dfit = zeros(Npixel, Nslice);
        for ipixel = 1:Nps
            Pbow_ip = P.(bowtie){iw}(ipixel, :);
            Dexp_ip = Dexp(ipixel)-Dempty(ipixel);
            if isfinite(Dexp_ip)
                dfit(ipixel) = fzero(@(x) -log(Pbow_ip*(exp(-x.*mu_1).*samplekeV))-Dexp_ip, 0);
            end
        end
        % smooth
        for islice = 1:Nslice
            dfit(:, islice) = smooth(dfit(:,islice), 0.05, 'rloess');
        end
        % set KV
        SYS.protocol.KV = KV(iw);
        % reload protocol
        SYS = loadprotocol(SYS);
        % add effect filter
        Nfilt = length(SYS.collimation.filter);
        SYS.collimation.filter{Nfilt+1} = struct();
        SYS.collimation.filter{Nfilt+1}.effect = true;
        SYS.collimation.filter{Nfilt+1}.thickness = dfit(:);
        SYS.collimation.filter{Nfilt+1}.material = SYS.collimation.bowtie{1}.material;
        % BH cali
        BHcorr = simuBHcali(SYS, 4);
        
        % save table
        corrfile = fullfile(calioutputpath, [SYS.output.files.beamharden{1} '.corr']);
        cfgfile = cfgmatchrule(corrfile, SYS.path.IOstandard);
        corrcfg = readcfgfile(cfgfile);
        packstruct(BHcorr{1}, corrcfg, corrfile);
        % to return the files
        BHcalitable.(bowtie){iw} = corrfile;
    end
end
