function detector = detectorextracollim(detector, det_corr, samplekeV)
% merge extra informations of detector by collimation
% detector = detectorextracollim(detector, det_corr, samplekeV);

% response
if isfield(det_corr, 'response') && ~isempty(det_corr.response)
    % samplekeV of the response curve(s)
    detector.samplekeV = det_corr.samplekeV;
    % collimation
    if size(det_corr.response, 1)==1
        detector.response = det_corr.response;
    else
        det_corr.response = reshape(det_corr.response, det_corr.Npixel, det_corr.Nslice, []);
        sliceindex = detector.startslice : detector.endslice;
        detector.response = reshape(det_corr.response(:, sliceindex, :), detector.Npixel*detector.Nslice, []);
    end
    % interp to samplekeV
    [index, alpha] = interpprepare(detector.samplekeV, samplekeV, 0);
    detector.response = detector.response(:, index(:,1)).*alpha(:,1)' + detector.response(:, index(:,2)).*alpha(:,2)';
else
    detector.response = ones(size(samplekeV));
end

% cross talk
if isfield(det_corr, 'crossmatrix') && ~isempty(det_corr.crossmatrix)
    % crossmatrix
    crsindex = false(det_corr.Npixel, det_corr.Nslice);
    crsindex(:, detector.startslice : detector.endslice) = true;
    detector.crossmatrix = det_corr.crossmatrix(crsindex(:), crsindex(:));
end

% TBC
% ASG, norm vector, 

% pixel area (hard code)
% I know the det_corr.pixelarea has not been defined.
w = weightofslicemerge(detector);
detector.pixelarea = repmat(w(:)', detector.Npixel, 1);

end
