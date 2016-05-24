classdef MhdBackend < AbstrImgBackend
    %MHDBACKEND Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = immutable)
        pixdim
        mhaHdr
    end
    
    properties
        img
    end
    
    methods
        function obj = MhdBackend(filePath)
            obj.img = mha_read_volume(filePath);
            obj.mhaHdr = mha_read_header(filePath);
            obj.pixdim = obj.mhaHdr.PixelDimensions;
        end
    end
    
end

