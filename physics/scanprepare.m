function [samplekeV, viewangle, couch, shotindex] = scanprepare(SYS)
% scan prepare, called in projection scan

% parameters to use
Nview_pr = SYS.protocol.viewperrot;
Nview = SYS.protocol.viewnumber;
Nrot = SYS.protocol.rotationnumber;
Nshot = SYS.protocol.shotnumber;
startangle = SYS.protocol.startangle;
startcouch = SYS.protocol.startcouch;
couchstep = SYS.protocol.shotcouchstep;
couchspeed = SYS.protocol.couchspeed;
couchheight = SYS.protocol.couchheight;
rotspeed = SYS.protocol.rotationspeed;
inttime = SYS.protocol.integrationtime;

% samplekeV
if strcmpi(SYS.simulation.spectrum, 'Single')
    samplekeV = SYS.world.referencekeV;
else
    samplekeV = SYS.world.samplekeV;
end

% startangle to pi
startangle = mod(startangle*(pi/180), pi*2);

% viewangles
switch lower(SYS.protocol.scan)
    case {'axial', 'helical'}
        % rotation
        viewangle = 0 : pi*2/Nview_pr : pi*2*Nrot;
        viewangle = viewangle(1:Nview);
    otherwise
        % no rotation
        viewangle = zeros(1, Nview);
end
% multi shot + startangle
viewangle = reshape(repmat(viewangle(:), 1, Nshot) + startangle, 1, []);
% viewangle = mod(viewangle, pi*2);

% shotindex
shotindex = reshape(repmat(1:Nshot, Nview, 1), 1, []);

% couch
switch lower(SYS.protocol.scan)
    case 'axial'
        couch_z = repmat((0:Nshot-1).*couchstep + startcouch, Nview_pr, 1);
    case 'helical'
        couch_z = (1:Nview)'.*(couchspeed/rotspeed/Nview_pr) + ...
            (0:Nshot-1).*couchstep + startcouch;
    otherwise
        % static or topo
        couch_z = (1:Nview)'.*(couchspeed*inttime*1e-6) + ...
            (0:Nshot-1).*couchstep + startcouch;
end
couch = [zeros(Nview*Nshot, 1) -ones(Nview*Nshot, 1).*couchheight couch_z(:)];

end