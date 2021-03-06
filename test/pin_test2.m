% pin cali main, test
% pinxml = 'F:\data-Dier.Z\PG\bay4_0527\Pinrecon.xml';
% pindata = 'F:\data-Dier.Z\PG\bay4_0527\pin_off230_10mmleft\startangle_0';
% [~, dataflow, prmflow] = CRISrecon(pinxml, pindata);

% startview = 501+1152;
startview = 577;
endview = startview+1152-1;
dataflow = dataflow_all;
dataflow.rawdata = dataflow.rawdata(:, startview:endview);
for ifield = fieldnames(dataflow.rawhead)'
    dataflow.rawhead.(ifield{1}) = dataflow.rawhead.(ifield{1})(:, startview:endview);
end

% inputs are dataflow and prmflow
Nslice = prmflow.recon.Nslice;
Npixel = prmflow.recon.Npixel;
Nview = prmflow.recon.Nviewprot;
detector = prmflow.system.detector;
focalposition = prmflow.system.focalposition(prmflow.recon.focalspot, :);
Npixelpermod = 16;
Nmod = Npixel/Npixelpermod;
SID = double(detector.SID);
hz = double(detector.hz_ISO);
viewangle = double(dataflow.rawhead.viewangle);

% det to fanangle
[fanangles0, focalangle] = detpos2fanangles(detector.position, focalposition);
fanangles0 = fanangles0 - focalangle;
fanangles0 = reshape(fanangles0, Npixel, Nslice);

% ini
fanangles = fanangles0;

figid = figure;
hold on
% iteration of det fix
alpha = 1.0;
Niter = 10;
for iiter = 1:Niter
    % fit splines for each view's projection
    cs = pinsplines(dataflow.rawdata, fanangles, Npixel, Nslice, Nview);
    % pin matrix
    alpha_L = [1.0, 0.5];
    [A, L, indexrange] = pinmatrix(cs, Npixel, Nslice, Nview, Npixelpermod, alpha_L);
    
    % pin curve fitting
    p0 = reshape(double([cs(:).p]), Nslice, Nview);    
    % fit pin
    x0 = [200 pi/2 0 0 1 0 1 0 0];
    p10 = pinfitfun(viewangle, Nslice, SID, hz, 0, x0);
    [dp, pinfit] = pincurvefit(cs, viewangle, SID, hz, Nslice, Nview, x0);
    
    detfix = zeros(Npixel, Nslice);
    d_right = zeros(Npixel, Nslice);
    for islice = 1:Nslice
        AA = A{islice}'*A{islice};
        edge1 = indexrange(islice, 1);  edge2 = indexrange(islice, 2);
        AA = AA(edge1:edge2, edge1:edge2) + L(edge1:edge2, edge1:edge2);
        d_right(:, islice) = A{islice}'*dp(islice,:)';
        detfix(edge1:edge2, islice) = AA\d_right(edge1:edge2, islice);
    end
    % plot
    figure(figid);
    plot(mean(detfix, 2));
    drawnow;
    % fix det
    fanangles = fanangles + detfix.*alpha;
end
% removed the unconverged components
fananglesM = fanangles - detfix.*alpha.*Niter;


function r = pinfitfun(viewangle, Nslice, SID, hz, p0, x)

viewangle = viewangle+[0 cumsum(diff(viewangle)<0)].*(pi*2);
viewangle = (viewangle - viewangle(1)).*x(7) + viewangle(1);

% viewangle = viewangle + cos(viewangle+x(8)).*x(9);
midfix = x(6) + sin(viewangle+x(8)).*x(9);

p = pinprojectfun(viewangle, x(1)/SID, x(2), Nslice, x(3)/SID, x(4)/SID, hz).*x(5) + midfix;
r = p - p0;
dr = r(:,end) - r(:, 1);
r = [r dr.*sqrt(size(p, 2))];

end

function cs = pinsplines(rawdata, fanangles, Npixel, Nslice, Nview)

rawdata = reshape(rawdata, Npixel, []);
[pmax, idxmax] = max(rawdata, [], 1);

m = 20;
index = (-m:m)' + idxmax;
sout = (index>Npixel) | (index<1);
index(index>Npixel) = Npixel;
index(index<1) = 1;
index = index + (0:Nview*Nslice-1).*Npixel;
A1 = rawdata(index);
A1(sout) = 0;
C1 = (sum(rawdata, 1) - sum(A1, 1))./(Npixel-m*2-1-sum(sout, 1));

A1 = A1 - C1;
A1(sout) = 0;
pmax = pmax - C1;

cut = 0.05;
A1(A1 < repmat(pmax.*cut, m*2+1, 1)) = 0;

cs = spline([0 1], [0 0]);
cs.vindex = [];
cs.pindex = [];
cs.p = nan;
cs.dp = nan;
cs(Nslice, Nview) = cs(1);
for ii = 1:Nview*Nslice
    islice = mod(ii-1, Nslice) + 1;
    iview = ceil(ii/Nslice);
    find_ii = find(A1(:, ii)>0, 1, 'first')-1 : find(A1(:, ii)>0, 1, 'last')+1;
    fanindex_ii = mod(index(find_ii, ii)'-1, Npixel)+1;
    fan_ii = fanangles(fanindex_ii, islice);
    tmp = spline(fan_ii, [0; A1(find_ii, ii); 0]);
    tmp.pindex = fanindex_ii;
    tmp.vindex = ones(size(fanindex_ii)).*iview;
    [tmp.dp, tmp.p] = ppcenterderivative(tmp);
    cs(ii) = tmp;
end

end

function [A, L, indexrange] = pinmatrix(cs, Npixel, Nslice, Nview, Npixelpermod, alpha)

A = cell(Nslice, 1);
indexrange = zeros(Nslice, 2);
for islice = 1:Nslice
    pindex = [cs(islice, :).pindex];
    vindex = [cs(islice, :).vindex];
    A{islice} = sparse(vindex, pindex, double([cs(islice, :).dp]), Nview, Npixel);
    % cut edge
    edge1 = ceil((min(pindex)+32)/Npixelpermod)*Npixelpermod + 1;
    edge2 = floor((max(pindex)-32)/Npixelpermod)*Npixelpermod;
    indexrange(islice, :) = [edge1, edge2];
%     A{islice} = A{islice}(:, p1:p2);
end

% dgA = zeros(Npixel, Nslice);
% L = spdiags(ones(Npixel, 1)*[-1 2 1], [-1 0 1], Npixel, Npixel);
Nmod = Npixel/Npixelpermod;
Lmod = cell(1, Nmod);
Lvalue = repmat([-1/2 1 -1/2], Npixelpermod, 1);
Lvalue(1, 2) = 1/2;  Lvalue(end, 2) = 1/2;  
Lmod(:) = {spdiags(Lvalue, [-1 0 1], Npixelpermod, Npixelpermod)};
Lall = spdiags(repmat([-1/2 1 -1/2], Npixel, 1), [-1 0 1], Npixel, Npixel);
Lall(1, 1) = 1/2;  Lall(end, end) = 1/2;
alpha_mod = alpha(1);  alpha_all = alpha(2);
L = blkdiag(Lmod{:}).*alpha_mod + Lall.*alpha_all;
end

function [dp, pinfit] = pincurvefit(cs, viewangle, SID, hz, Nslice, Nview, x0)

if nargin<7
    x0 = [200 pi/2 0 0 1 0 1 0 0];
end
p0 = reshape(double([cs(:).p]), Nslice, Nview);
pinfit = lsqnonlin(@(x) pinfitfun(viewangle, Nslice, SID, hz, p0, x), x0);
p1 = pinfitfun(viewangle, Nslice, SID, hz, 0, pinfit);
p1 = p1(:, 1:end-1);
dp = p1 - p0;

end