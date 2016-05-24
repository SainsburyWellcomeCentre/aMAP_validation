classdef abstractOutlineImg
    %ABSTRACTOUTLINEIMG Defines an Outline Image interface to get 2D outlines from
    %manual or computer-generated segmentations. Individual subclasses will
    %store the "result" in different ways.
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Abstract)
        obj = addImg(obj, img, sliceNum, color)
        result = getOutline(obj)
    end
    
end

