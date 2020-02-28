function [dataflow, prmflow, status] = reconnode_watergoback(dataflow, prmflow, status)
% cali node, put in sausage and go back to pig
% [dataflow, prmflow, status] = reconnode_watergoback(dataflow, prmflow,
% status);
% use to find the ideal target for BH and nonlinear calibration.

% prm
Nslice = prmflow.recon.Nslice;
Nview = prmflow.recon.Nview;
% from rebin
Nreb = prmflow.rebin.Nreb;
mid_u = prmflow.rebin.midchannel;
delta_d = prmflow.rebin.delta_d;

% caliprm
caliprm = prmflow.pipe.(status.nodename);

% smooth & fill
if isfield(caliprm, 'span')
    smooth_span = caliprm.span;
else
    smooth_span = 30;
end
% off-focal tolerance
if isfield(caliprm, 'offfocal')
    offfocal_tol = caliprm.offfocal;
else
    offfocal_tol = 0;
end

% forward filter
if isfield(caliprm, 'filter')
    H1 = loadfilter(caliprm.filter, Nreb, delta_d);
else
    % default filter
    H1 = filterdesign('hann', Nreb, delta_d, 1.0);
end
Hlen = length(H1);

% backward filter
H0 = filterdesign('', Nreb, delta_d, inf);

% fill up
dataflow.rawdata = reshape(dataflow.rawdata, Nreb, Nslice, Nview);
A = zeros(Hlen, Nslice, Nview);
if isfield(dataflow.rawhead, 'refblock')
    blkvindex = any(dataflow.rawhead.refblock, 1);
else
    blkvindex = [];
end
for ii = 1:Nslice
    [A(:, ii, :), n_left] = translatefillup(squeeze(dataflow.rawdata(:, ii, :)), Hlen, mid_u, blkvindex);
end

% reshape
Nd = Nslice*Nview;
A = reshape(A, Hlen, Nd);

% weight center
xx = 1:Hlen;
Wcnt = (xx*A)./sum(A, 1);
% smooth
Wcnt = reshape(Wcnt, Nslice, Nview);
m = 30;
for ii = 1:Nslice
    tmp = smooth([Wcnt(ii, end-m+1:end) Wcnt(ii, :) Wcnt(ii, 1:m)], 0.03, 'rloess');
    Wcnt(ii, :) = tmp(m+1:end-m);
end
Wmid = mean(Wcnt, 2);

% filter by H1
A = ifft(fft(A).*H1, 'symmetric');

% target
C0 = 1000.*(2/pi);

% mean shape & cut
A = reshape(A, Hlen, Nslice, Nview);
Amean = zeros(Hlen, Nslice);
xcut_l = zeros(Nslice, 1);
xcut_r = zeros(Nslice, 1);
Cmean = zeros(Nslice, 1);
for ii = 1:Nslice
    Ac = zeros(Hlen, Nview);
    xx = 1:Hlen;
    for iview = 1:Nview
        Ac(:, iview) = interp1(xx, A(:, ii, iview), xx+(Wcnt(ii, iview)-Wmid(ii)), 'linear', 0);
    end
    Amean(:, ii) = mean(Ac, 2);
    % cut for mean
    x1_l = find(Amean(:, ii)>C0.*0.9, 1, 'first');
    x1_r = find(Amean(:, ii)>C0.*0.9, 1, 'last');
    m = 16;
    Cmean(ii) = mean(Amean(x1_l+m:x1_r-m, ii));
end

% to find water edge
Amean = mean(Amean, 2);
DfA = diff(Amean);
% left
[~, edge_pl] = max(Amean(x1_l: x1_l+m));
edge_pl = max(edge_pl, find(Amean(x1_l: x1_l+m)>C0.*1.3, 1, 'last'));
edge_pl = x1_l + edge_pl - 1;
xcut_l(:) = find(DfA(edge_pl:end)>0, 1, 'first') + edge_pl - 1;
% right
[~, edge_pr] = max(Amean(x1_r-m: x1_r));
edge_pr = min(edge_pr, find(Amean(x1_r-m: x1_r)>C0.*1.3, 1, 'first'));
edge_pr = x1_r-m + edge_pr - 1;
xcut_r(:) = find(DfA(1:edge_pr)<0, 1, 'last')+1;
%     % with off-focal
%     xcut_l(ii) = find(Amean(x1_l+2:end, ii)<Cmean(ii), 1, 'first')+x1_l+1;
%     xcut_r(ii) = find(Amean(1:x1_r-2, ii)<Cmean(ii), 1, 'last');    

A = reshape(A, Hlen, Nd);


Asmth = zeros(max(xcut_r-xcut_l)+1, 1);
span_smth = smooth_span/(xcut_r(1)-xcut_l(1));
index_sm = 1:xcut_r(1)-xcut_l(1)+1;
Asmth(index_sm) = smooth(Amean(xcut_l(1):xcut_r(1)), span_smth, 'rloess');
switch offfocal_tol
    case {'deep', 0}
        % deep off-focal
        x3_l = find(diff(Asmth(index_sm)>mean(Cmean))<0, 1, 'first')+1;
        x3_r = find(diff(Asmth(index_sm)>mean(Cmean))>0, 1, 'last');
        % with draw the cuts
        d_l = find(Asmth(index_sm)>mean(Cmean), 1, 'first');
        xcut_l(:) = xcut_l(:)+d_l-1;
        d_r = find(Asmth(index_sm)>mean(Cmean), 1, 'last');
        xcut_r(:) = xcut_l(:)+d_r-1;
    case {'week', 1}
        % week off-focal
        x3_l = find(diff(Asmth(index_sm)>mean(Cmean))~=0, 1, 'first')+1;
        x3_r = find(diff(Asmth(index_sm)>mean(Cmean))~=0, 1, 'last');
        % with draw the cuts
        xcut_l(:) = xcut_l(:)+x3_l-1;
        xcut_r(:) = xcut_l(:)+x3_r-1;
    case {'none', 3}
        % no off-focal (sure?)
        x3_l = 1;
        x3_r = xcut_r(1)-xcut_l(1)+1;
    otherwise
        error('Illegal off-focal tolerance: %s', num2str(offfocal_tol));
end

for ii = 1:Nslice
    Asmth(x3_l:x3_r, ii) = Cmean(ii);
end


% index range of the target
index_range= zeros(2, Nd);
index_range(1, :) = reshape(round(Wcnt-Wmid+xcut_l), 1, []);
index_range(2, :) = reshape(round(Wcnt-Wmid+xcut_r), 1, []);

% replace
C1 = zeros(1, Nd);
for ii = 1:Nd
    % index
    islice = mod(ii-1, Nslice)+1;
    ix1 = index_range(1,ii);  
    ix2 = index_range(2,ii);
    % interp
    xx = (xcut_l(islice) : xcut_r(islice)) + Wcnt(ii)-Wmid(islice);
    index_sm = 1:xcut_r(islice)-xcut_l(islice)+1;
    tofill = interp1(xx, Asmth(index_sm, islice), ix1:ix2, 'linear', 'extrap');
    % norm and replace
    C1(ii) = mean(A(ix1:ix2, ii))/mean(tofill);
    A(ix1:ix2, ii) = tofill.*C1(ii);
    C1(ii) = C1(ii)*Cmean(islice);
end

% inverse filter by H0
A = ifft(fft(A)./H0, 'symmetric');
% scale to C0
A = A.*(C0./C1);

% % interation one more step (skip)
% A = ifft(fft(A).*H1, 'symmetric');
% for ii = 1:Nd
%     A(index_range(1,ii):ix(2,ii), ii) = C0;
% end
% % inverse filter by H0 again
% A = ifft(fft(A)./H0, 'symmetric');

% % regular by max (skip)
% A = reshape(A, Hlen, Nslice, Nview);
% for ii = 1:Nslice
%     maxA = max(A(:,ii,:),[],1);
%     A(:,ii,:) = A(:,ii,:)+(mean(maxA)-maxA);
% end

% reshape
A = reshape(A, Hlen*Nslice, Nview);
index_range = reshape(index_range, 2*Nslice, Nview);

% to return
dataflow.rawdata = A;
dataflow.rawhead.index_range = index_range;
% the returns for inverse rebin
prmflow.rebin.Nreb = Hlen;
prmflow.rebin.Nleft = n_left;
prmflow.rebin.midchannel = mid_u+n_left;

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end