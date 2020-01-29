resp0=load('D:\matlab\ct\BCT16\BHtest\response_1219.mat');
samplekeV = resp0.samplekeV;

Npixel = 912;
Nslice = 24;
Npperm = 16;
Nmod = Npixel/Npperm;
Nps = Npixel*Nslice;
Nslamg = 4;

v = [0 50 100 150];
ap = 1;
am = 1;

Nv = length(v);
Rp = randn(Nps, Nv);
Rm = randn(Nmod, Nslamg, Nv);
Rm = repelem(Rm, Npperm, 8, 1);
Rm = reshape(Rm(:, 5:28, :), Nps, Nv);

Rv = Rp.*ap + Rm.*am;
R = zeros(Nps, length(samplekeV));
for ii = 1:Nps
    R(ii, :) = spline(v, [0 Rv(ii, :) 0], samplekeV);
end

a0 = 0.02;
a1 = 0.06;

a = ones(Npixel, Nslice).*a0;
a(1:Npperm:end, :) = a1;
a(Npperm:Npperm:end, :) = a1;

resp1 = resp0;
resp1.response = resp0.response + R.*a(:);