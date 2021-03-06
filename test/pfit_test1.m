% load('pptest1.mat');

t0 = [0 1];

tic
p1 = lsqnonlin(@(t) (iterinvpolyval(t, y(:))-x(:)).*w(:), t0, [], [], options);
r1 = iterinvpolyval(p1, y(:))-x(:);
toc
% p2 = [ 0.2 0.1 1.05];
% 
% tic;
% x1 = iterinvpolyval(p2, y, [0 1000]);
% toc;
% 
% tic;
% x2 = iterinvpolyval_t1(p2, y, x1, 1e-3);
% toc;


tic
% Norder = 2;
x = x(:)';
y = y(:)';
w = w(:)';
x2 = [x; x.^2];


% % prepare for inverse
% xrange = [min(x).*0.8 max(x).*1.1];
% Nrng = 1000;
% xx_rng = linspace(xrange(1), xrange(2), Nrng);
% xx_rng = [xx_rng; xx_rng.^2];

tol_p = [1e-5 1e-10];
p0 = [1 0];
Nmax = 10;
p = zeros(Nmax, 2);
p(1, :) = p0;
for ii = 1:Nmax-1
%     yy_rng = p(ii, :)*xx_rng;
%     b = x - interp1(yy_rng, xx_rng(1,:), y, 'linear', 'extrap');
    r = x - y./p(ii,1).*2./(sqrt(y./p(ii,1)^2.*4.*p(ii,2)+1)+1);
    b = r.*w;
    dyu1 = 1./(p(ii, 1) + x.*p(ii, 2).*2);
    A = -x2.*dyu1;
    A = A.*w;
%     AA = A*A';
%     dp = (b*A')/AA;
    aa = [A(1,:)*A(1,:)' -A(1,:)*A(2,:)' A(2,:)*A(2,:)'];
    aa = aa./(aa(1)*aa(3)-aa(2)^2);
    dp = (b*A')*aa([3 2; 2 1]);
    if all(abs(dp)<tol_p)
        break
    end
    p(ii+1, :) = p(ii, :) + dp;
end

toc


% function x = iterinvpolyval_rng(p, xx, y)
% 
% yy = p*xx;
% x = interp1(yy, xx, y, 'linear', 'extrap');
% 
% end


function dy = iterpolydiff_t0(p, x)

n = size(p, 2);
dy = ones(size(x));
for ii = 1:n-1
    dy = (dy.*x).*p(:, ii).*((n-ii+1)/(n-ii)) + 1.0;
end
dy = dy.*p(:, n);

end

function y = iterpolyval_s(p, x, s)
% return y = ((((x*p(1)+1)*x*p(2)+1)*x*p(3)+1)*...)*x*p(n)
% y = iterpolyval(p, x);

n = size(p, 2);
y = ones(size(x));
for ii = 1:n-1
    y(~s) = 0;
    y(s) = y(s).*x(s);
    y = y.*p(:, ii) + 1.0;
end
y(~s) = 0;
y(s) = y(s).*x(s);
y = y.*p(:, n);
y = y(s);
end