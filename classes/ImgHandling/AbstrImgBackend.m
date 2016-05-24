classdef (Abstract) AbstrImgBackend
    %ABSTRIMGBACKEND Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract, SetAccess = immutable)
        pixdim
    end
    
    properties (Abstract)
        img
    end
    
    methods
    end
    
end

