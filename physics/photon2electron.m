function Dataflow = photon2electron(SYS, Dataflow)
% photon energy to intensity

% to use
% tube
Nw = SYS.source.Wnumber;
KV = SYS.source.KV;
mA = SYS.source.mA;
mA_air = SYS.source.mA_air;
% DCB
T = SYS.datacollector.integrationtime;
gain = SYS.datacollector.DBBgain/SYS.world.refrencekeV/SYS.detector.mergescale;
Z0 = SYS.datacollector.DBBzero;
Tscale = 1000/SYS.datacollector.inttimeclock;

% constant
electric_charge = 1.602e-19;
epeffect = 0.01;

% loop Nw
for iw = 1:Nw
    W = KV{iw}*mA{iw};
    PEscale = T*1e-6*W/electric_charge/1000*epeffect;
    % I know T*1e-6 is in sec, W is in KV*mA=V*Q/sec, electric_charge*1000(V) is in KeV, epeffect is 1%,
    % therefore PEscale is in V*Q/KeV, which will scale the KeV normed P in counting number on KeV,
    % P*PEscale/Ephonton is the phonton number where Ephonton is in KeV.
    
    % Intensity
    Dataflow.P{iw} = Dataflow.P{iw}.*PEscale;
    % Quantum noise
    if SYS.simulation.quantumnoise && ~isempty(Dataflow.Eeff{iw})
        Dataflow.P{iw} = poissrnd(Dataflow.P{iw}./Dataflow.Eeff{iw}).*Dataflow.Eeff{iw};
    end
    % slice merge
    Dataflow.P{iw} = detectorslicemerge(Dataflow.P{iw}, SYS.detector, 'sum');
    % DBB gain
    Dataflow.P{iw} = Dataflow.P{iw}.*gain + Z0;
    % air main
    Dataflow.Pair{iw} = -log2(detectorslicemerge(Dataflow.Pair{iw}, SYS.detector, 'sum') ...
        .*PEscale.*gain.*(mA_air{iw}/mA{iw})) + log2(T*Tscale);
    % We don't put quantum noise on Pair which is used as a reference but not a scan of air.
end

end
