% run after NL1 and inverse BH

Npixel = 864;
Nview = 1152;

A1=double(dataflow.rawdata_bk1(1:Npixel,:));
B1=double(dataflow.rawdata_bk2(1:Npixel,:));
A2=double(dataflow.rawdata_bk3(1:Npixel,:));
B2=double(dataflow.rawdata_bk4(1:Npixel,:));

x = [2.^(-A1) 2.^(-A2)];
y = [2.^(-B1) 2.^(-B2)]; 

x_sm = zeros(Npixel, Nview*2);
y_sm = zeros(Npixel, Nview*2);

index_range2 = dataflow.rawhead_bk2.index_range(1:2, :);
index_range4 = dataflow.rawhead_bk4.index_range(1:2, :);

Sr = zeros(Npixel, Nview*2);
for iview = 1:Nview
    Sr(index_range2(1,iview)+1:index_range2(2,iview), iview) = 1.0;
    Sr(index_range4(1,iview)+1:index_range4(2,iview), iview+Nview) = 1.0;
    x_sm(:, iview) = smooth(x(:,iview), 0.03, 'loess');
    x_sm(:, iview+Nview) = smooth(x(:,iview+Nview), 0.03, 'loess');
    y_sm(:, iview) = smooth(y(:,iview), 0.03, 'loess');
    y_sm(:, iview+Nview) = smooth(y(:,iview+Nview), 0.03, 'loess');
end

D =spdiags(repmat([1 -1], Npixel, 1), [0, 1], Npixel, Npixel);

Dyx = D\((y./y_sm-x./x_sm).*Sr);
Dx = (D'*x)./x_sm.*Sr;
Dy = (D'*y)./y_sm.*Sr;
Dx_sm = (D'*x_sm)./x_sm.*Sr;

% Dyx = D\((y-x).*Sr);
% Dx = (D'*x).*Sr;
% Dy = (D'*y).*Sr;

nrDyx = sum(Dyx.^2, 2);
nrDx = sum(Dx.^2, 2);
nrDy = sum(Dy.^2, 2);
nrDx_sm = sum(Dx_sm.^2, 2);

Px = sum(Dyx.*Dx, 2)./nrDx;
Py = sum(Dyx.*Dy, 2)./nrDy;
Qx = sum(Dyx.*Dx, 2)./sqrt(nrDx)./sqrt(nrDyx);
Qy = sum(Dyx.*Dy, 2)./sqrt(nrDy)./sqrt(nrDyx);

Px_sm = sum(Dyx.*Dx_sm, 2)./nrDx_sm;
Qx_sm = sum(Dyx.*Dx_sm, 2)./sqrt(nrDx_sm)./sqrt(nrDyx);

n1 = sum(Sr(:, 1:Nview), 2);
n2 = sum(Sr(:, Nview+1:Nview*2), 2);


