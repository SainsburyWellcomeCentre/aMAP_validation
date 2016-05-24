classdef NiftyBackend < AbstrImgBackend
    %NIFTYBACKEND Backend for loading Nifty (.nii and .nii.gz) files
    %   Detailed explanation goes here
    
    properties (SetAccess = immutable)
        pixdim
        niftyObj
    end
    
    properties
        img
    end
    
    methods
        function obj = NiftyBackend(filePath)
            obj.niftyObj = load_nii(filePath);
            obj.img = obj.niftyObj.img;
            obj.pixdim = obj.niftyObj.hdr.dime.pixdim(2:4);
        end
    end
    
end