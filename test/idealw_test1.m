% test of the translatefillup in reconnode_watergoback
% load E:\matlab\CT\SINO\TM\idealtest1.mat

Nreb = prmflow.rebin.Nreb;
% delta_d = prmflow.rebin.delta_d;
mid_u = prmflow.rebin.midchannel;
% refblock = dataflow.rawhead.refblock;
Hlen = 2048;

% A0 = squeeze(dataflow.rawdata(:, 1, :));

[Npixel, Nview] = size(A0);
n_l = floor((Hlen-Npixel)/2);
n_r = ceil((Hlen-Npixel)/2);

% ini
A1 = zeros(Hlen, Nview);
A1(n_l+1:Hlen-n_r, :) = A0;
% bebug
A1_0 = nan(Hlen, Nview);
A1_0(n_l+1:Hlen-n_r, :) = A0;

blkvindex = any(refblock, 1);

% find a center projection
x0 = 1:Npixel;
wcenter = double(x0*A0./sum(A0, 1));

% index to fillup
% x_fl = [(1:n_l)-n_l  (1:n_r)+Npixel];
% s_fl = x_fl+n_l;
x_left = (1:n_l)-n_l;
s_left = x_left + n_l;
x_right = (1:n_r)+Npixel;
s_right = x_right + n_l;
% viewindex = 1:Nview;

A1 = fitandfill(A1, A0, refblock(1, :), wcenter, x_left, s_left);
A1 = fitandfill(A1, A0, refblock(2, :), wcenter, x_right, s_right);

function A1 = fitandfill(A1, A0, refblock, wcenter, x_fl, s_fl)

[Npixel, Nview] = size(A0);
x0 = 1:Npixel;
options_fzero = optimset('TolX',1e-8);
for ii = find(refblock)
    v1 = find(~refblock(1:ii), 1, 'last');
    v2 = find(~refblock(ii+1:end), 1, 'first') + ii;
    if isempty(v1)
        v1 = find(~refblock, 1, 'last');
        d1 = ii + Nview - v1;
    else
        d1 = ii - v1;
    end
    if isempty(v2)
        v2 = find(~refblock, 1, 'first');
        d2 = v2 + Nview - ii;
    else
        d2 = v2 - ii;
    end
    
    a1 = A0(:, v1);
    a2 = A0(:, v2);
    x1 = fzero(@(t) alignfit(a1, wcenter(ii), t), wcenter(ii)-wcenter(v1), options_fzero);
    x2 = fzero(@(t) alignfit(a2, wcenter(ii), t), wcenter(ii)-wcenter(v2), options_fzero);
    if ii == 899
        1;
    end
    A1(s_fl, ii) = interp1(x0, a1, x_fl-x1,'linear', 0).*(d2/(d1+d2)) + interp1(x0, a2, x_fl-x2,'linear', 0).*(d1/(d1+d2));
end

end


function r = alignfit(y, w, x)
% x = fzero(@(x) alignfit(y, w, x), x0);

y = y(:)';
N = length(y);
xx = 1:N;

y2 = interp1(xx, y, xx-x, 'linear', 0);
w2 = sum(y2.*xx)/sum(y2);
r = w2-w;

end