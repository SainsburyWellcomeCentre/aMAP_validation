function segAnalyserObj = calculateRegistrationScores(brainName,  atlasNiiPath, stapleDir, sharedParamObj, scoreUser, scoreNifty)
%calculateRegistrationScores Creates a segAnalyzer containing the dice scores of the
%computer and human segmentation for all regions in the sharedParameter
%object.
%   This class uses the Analyzer factory for the heavy lifting. It is
% mainly a little helper that stores the system-specific paths to the
% manually determined input data (segmentations, shift). It is used to make
% scoring the multi-parameter runs easier.

segAnalyserObj = segAnalyser(atlasNiiPath, brainName, sharedParamObj.manSegBaseDirs, stapleDir, sharedParamObj.tmpDir, sharedParamObj.scale);
segAnalyserObj = segAnalyserObj.initData();
shifts = sharedParamObj.shifts(strcmpi(sharedParamObj.shifts.name, brainName),:);
shifts = struct2table(shifts.shifts);
allRegions = sharedParamObj.regions;
for i = 1:size(allRegions,1)
    currShift = shifts(strcmpi(shifts.name, allRegions.sectionName(i)),:);
    segAnalyserObj = segAnalyserObj.addAtlasRegionAtlasCoordinate(allRegions.allenID(i), currShift);
end

segAnalyserObj = segAnalyserObj.removeUnsegmentedHemisphere();

if scoreUser
    segAnalyserObj = segAnalyserObj.scoreManualSegs();
end
if scoreNifty
    segAnalyserObj = segAnalyserObj.scoreNiftySegs();
end

end


