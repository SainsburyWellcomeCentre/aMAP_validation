classdef rasterOutlineImg < abstractOutlineImg
    %RASTEROUTLINEIMG Raster-based implementation of the outline image,
    %supports stacks.
    %   Detailed explanation goes here
    
    properties
        outlineImg;
    end
    
    methods
        function obj = rasterOutlineImg(width, height, numZ)
            obj.outlineImg = zeros(width, height, numZ);
        end
        
        function obj = addImg(obj, img, sliceNum, brightness)
            img = rasterOutlineImg.makeOutline(img, brightness);
            sz1 = min(size(obj.outlineImg,1), size(img,1));
            sz2 = min(size(obj.outlineImg,2), size(img,2));
            obj.outlineImg(1:sz1, 1:sz2, sliceNum) = max(obj.outlineImg(1:sz1, 1:sz2, sliceNum), img(1:sz1, 1:sz2));
        end
        
        function result = getOutline(obj)
            result = uint8(obj.outlineImg);
        end
    end
    
    methods(Static)
        function img = makeOutline(img, brightness)
            img = bwperim((img>0), 8)*brightness;
        end
    end
end

