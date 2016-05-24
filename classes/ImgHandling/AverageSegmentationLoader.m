classdef AverageSegmentationLoader
    %ANALYSISIMAGEPROVIDER Helper class to load the STAPLE/SBA .nii files using my
    %standard nomenclature
    %   Detailed explanation goes here
    
    properties
        imgDir;
        sbaSuffix='NiftySegSBA.nii';
        stapleSuffix = 'NiftySegSTAPLE.nii';
        scale;
    end
    
    methods
        function obj = AverageSegmentationLoader(imgDir, scale)
            obj.imgDir = imgDir;
            obj.scale = scale;
        end
        
        function sbaImage = getSBA(obj, brainRegionComb)
            sbaImage = obj.loadNiiImg([brainRegionComb '_' num2str(obj.scale) '_' obj.sbaSuffix]);
        end
        
        function stapleImage = getSTAPLE(obj, brainRegionComb)
            stapleImage = obj.loadNiiImg([brainRegionComb '_' num2str(obj.scale) '_' obj.stapleSuffix]);
        end
        
        function img = loadNiiImg(obj, fileName)
            img = load_nii(fullfile(obj.imgDir, fileName));
        end
        
    end
    
end

