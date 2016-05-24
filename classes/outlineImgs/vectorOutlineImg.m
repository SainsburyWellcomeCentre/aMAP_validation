classdef vectorOutlineImg < abstractOutlineImg
    %VECTOROUTLINEIMG Vector-based implementation of the outline image, for
    %plotting in e.g. illustrator. 
    %   Stores the Result as a 2D matlab-figure and ignores the third dimensions.
    
    properties
        fig;
        axes;
        sizeX;
        sizeY;
    end
    
    methods
        function obj = vectorOutlineImg(sizeX, sizeY, ~)
            obj.fig = figure();
            obj.axes = gca();
            obj.axes.YDir = 'reverse';
            obj.sizeX = sizeX;
            obj.sizeY = sizeY;
        end
        function obj = addImg(obj, img, ~, color)
            outlines = bwboundaries(img);
            for i = 1:numel(outlines)
                currOl=outlines{i};
                line(currOl(:,1), currOl(:,2), 'Parent', obj.axes, 'Color', color)
            end
        end
        function result = getOutline(obj)
            if ~isempty(obj.sizeX)
                obj.axes.XLim = [0 obj.sizeX];
            end
            if ~isempty(obj.sizeY)
                obj.axes.YLim = [0 obj.sizeY];
            end
            result = obj.fig;
        end
    end
    
end

