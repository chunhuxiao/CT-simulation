function [Pout, Nmergedslice] = detectorslicemerge(Pin, Npixel, Nslice, slicemerge, mergemethod)
% merge the slices
% [Pout, Nmergedslice] = detectorslicemerge(Pin, Npixel, Nslice, slicemerge, mergemethod);
% or e.g. Pout = detectorslicemerge(Pin, detector.Npixel, detector.Nslice, detector.slicemerge, 'mean');

if nargin<3
    mergemethod = 'sum';
end

% Nslice = detector.Nslice;
% Npixel = detector.Npixel;

if all(slicemerge == 1:Nslice)
    % skip
    Pout = Pin;
    Nmergedslice = Nslice;
    return;
end

% to merge
Nmergedslice = max(slicemerge);
Pin = reshape(Pin, Npixel, Nslice, []);
% Pout = zeros(Npixel, Nmergedslice, size(Pin, 3), class(Pin));
Pout = zeros(Npixel, Nmergedslice, size(Pin, 3));
mergeweight = zeros(1, Nmergedslice);
% sum up the values
for ii = 1:Nslice
    index_ii = slicemerge(ii);
    if index_ii<=0 || ~isfinite(index_ii)
        continue;
    end
    Pout(:, index_ii, :) = Pout(:, index_ii, :) + Pin(:, ii, :);
    mergeweight(index_ii) = mergeweight(index_ii) + 1;
end
% switch the merge method
switch lower(mergemethod)
    case 'mean'
        Pout = Pout./mergeweight;
    case 'sum'
        % do nothing
        1;
    case 'any'
        Pout = Pout>0;
    case 'all'
        Pout = Pout==mergeweight;
    otherwise
        % sum
        1;
end
% cast to the class of Pin
Pout = cast(Pout, class(Pin));
Pout = reshape(Pout, Npixel*Nmergedslice, []);

end