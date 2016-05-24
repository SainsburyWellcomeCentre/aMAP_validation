% resizes all Images to the same dimensions, (done already, so no longer
% needed)
% rater.resizeSegImgsToMax();

%% initialization (make sure global Data has been edited to match your machine!)
parameters = sharedParams();

%full z range
modeStr = '';
arg = [];
dirArg = '';

%z-range limited to a window of 7 sections (the one with most manual segs
%is used)
% modeStr = 'range';
% arg = 7;
% dirArg = arg;

%z=range limited to the smallest possible window containing 50% of the
%manual segmentations
% modeStr = 'quantiles';
% arg = [0.25 0.75];
% dirArg = 'Quartiles';


%% normal run with all slices considered
rater = userRater(parameters.manSegBaseDirs, parameters.getManSegNiiDir(dirArg), parameters.getStapleDir(dirArg), parameters.scale);
% Rerbuilding the nii images; only needs to be done once per z-range (unless
% the downscaling is changed), so it can be commented out once the files
% are generated
rater.create4dNii(modeStr, arg);

rater.runStaple;
rater = rater.parseStapleResults;
