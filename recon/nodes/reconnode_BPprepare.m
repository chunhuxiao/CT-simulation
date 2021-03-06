function [dataflow, prmflow, status] = reconnode_BPprepare(dataflow, prmflow, status)
% recon node, BP prepare, set FOV, image size, center (XYZ), tilt ... for the images
% [dataflow, prmflow, status] = reconnode_BPprepare(dataflow, prmflow, status);

% BP parameters
BPprm = prmflow.pipe.(status.nodename);

% FOV
if isfield(BPprm, 'FOV')
    prmflow.recon.FOV = BPprm.FOV;
elseif isfield(prmflow.protocol, 'reconFOV')
    prmflow.recon.FOV = prmflow.protocol.reconFOV;
else
    % default FOV = 500
    prmflow.recon.FOV = 500;
end
% imagesize
if isfield(BPprm, 'imagesize')
    prmflow.recon.imagesize = BPprm.imagesize;
elseif isfield(prmflow.protocol, 'imagesize')
    prmflow.recon.imagesize = prmflow.protocol.imagesize;
else
    % default imagesize = 512
    prmflow.recon.imagesize = 512;
end
% image XY
if isfield(BPprm, 'center')
    prmflow.recon.center = BPprm.center;
else
    prmflow.recon.center = prmflow.protocol.reconcenter;
end
% window
if isfield(BPprm, 'windowcenter')
    prmflow.recon.windowcenter = BPprm.windowcenter;
else
    prmflow.recon.windowcenter = prmflow.protocol.windowcenter;
end
if isfield(BPprm, 'windowwidth')
    prmflow.recon.windowwidth = BPprm.windowwidth;
else
    prmflow.recon.windowwidth = prmflow.protocol.windowwidth;
end
% kernel
if isfield(BPprm, 'kernel')
    prmflow.recon.kernel = BPprm.kernel;
elseif isfield(prmflow.protocol, 'reconkernel')
    prmflow.recon.kernel = prmflow.protocol.reconkernel;
else
    % default kernel?
    prmflow.recon.kernel = '';
end
% imagethickness & imageincrement
prmflow.recon.imagethickness = prmflow.protocol.imagethickness;
prmflow.recon.imageincrement = prmflow.protocol.imageincrement;
% tilt
prmflow.recon.gantrytilt = prmflow.protocol.gantrytilt*(pi/180);
% couch (table) step & couch direction
prmflow.recon.shotcouchstep = prmflow.protocol.shotcouchstep;
prmflow.recon.couchdirection = prmflow.protocol.couchdirection;
% startcouch
prmflow.recon.startcouch = prmflow.protocol.startcouch;

switch lower(prmflow.recon.scan)
    case 'axial'
        prmflow.recon.Nimage = prmflow.recon.Nslice * prmflow.recon.Nshot;
        prmflow.recon.imagecenter = imagescenterintilt(prmflow.recon.center, prmflow.recon);
    otherwise
        warning('sorry, only Axial now.');
        % only Axial now
end

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end


function Cout = imagescenterintilt(Cin, recon)
% Cin is recon center; Cout is the rotation center on images

Cout = repmat(-Cin(:)', recon.Nimage, 1);
% Y shfit
Yshift = -(recon.imageincrement*tan(recon.gantrytilt)).*(-(recon.Nslice-1)/2 : (recon.Nslice-1)/2);
if recon.couchdirection > 0
    Yshift = fliplr(Yshift);
end
Yshift = repmat(Yshift(:), recon.Nshot, 1);
Cout(:, 2) = Cout(:, 2) + Yshift;
% Z shift
Zshift = (recon.imageincrement*sec(recon.gantrytilt)).*(-(recon.Nslice-1)/2 : (recon.Nslice-1)/2);
if recon.couchdirection > 0
    Zshift = fliplr(Zshift);
end
Zshift = Zshift(:) - (0:recon.Nshot-1).*recon.shotcouchstep;
Zshift = Zshift(:) - recon.startcouch;
Cout = [Cout Zshift];

end
