classdef segAnalyserFactory
    %SEGANALYSERFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stepSize=2;
        brainName;
        shifts;
        segNiiPath;
        stapleDir;
        params;
    end
    
    methods
        function obj=segAnalyserFactory(brainName, segNiiPath, stapleDir, sharedParamObj)
            obj.brainName = brainName;
            obj.segNiiPath = segNiiPath;
            obj.params = sharedParamObj;
            obj.stapleDir = stapleDir;
            obj.shifts = obj.params.shifts(strcmpi(obj.params.shifts.name, obj.brainName),:);
            obj.shifts = struct2table(obj.shifts.shifts);

        end
        
        function segAnalyserObj = makeAnalyser(obj, removeHemisphere) %todo: rewrite this
            segAnalyserObj = segAnalyser(obj.segNiiPath, obj.brainName, obj.params.manSegBaseDirs, obj.stapleDir, obj.params.tmpDir, obj.params.scale);
            segAnalyserObj = segAnalyserObj.initData();
            allRegions = obj.params.regions;
            for i = 1:size(allRegions,1)
                currShift = obj.shifts(strcmpi(obj.shifts.name, allRegions.sectionName(i)),:);
                segAnalyserObj = segAnalyserObj.addAtlasRegionAtlasCoordinate(allRegions.allenID(i), currShift);
            end
            if removeHemisphere
                segAnalyserObj = segAnalyserObj.removeUnsegmentedHemisphere();
            end
        end
    end
    
end

