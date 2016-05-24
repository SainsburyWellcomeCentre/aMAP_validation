classdef ImgSource
    %IMGSOURCE Encapsulates an image source (usually coming from a
    %registration program)
    %   A wrapper to use the registration analysis routines
    %   on a variety of formats that all come with different loaders (nii,
    %   mhd, tiff etc...). pixdim is expected to be provided in mm by the
    %   backends, but right now there is no code in place to check/enforce
    %   this!
    
    properties (Constant)
        imgBackendYml='imgBackends.yml';
    end
    
    properties
        imgBackend
    end
    
    properties (Dependent)
        img
        pixdim
    end
    
    properties (SetAccess=immutable)
        imgPath
        imgBackends
    end
    
    methods
        function obj = ImgSource(imgPath)
            obj.imgPath = imgPath;
            
            [fileDir,~,~] = fileparts(mfilename('fullpath'));
            ymlPath = fullfile(fileDir,obj.imgBackendYml);
            if ~exist(ymlPath,'file')
                error(['Backend YML file does not exist! (should be at ' obj.imgBackendYml ')'])
            end
            if ~exist(obj.imgPath,'file')
                error(['Image file does not exist! (should be at ' obj.imgPath ')'])
            end
            
            obj.imgBackends = readSimpleYAML(ymlPath);
            obj.imgBackends = struct2table(obj.imgBackends.backendDefs);
            
            obj.imgBackend = obj.getMatchingImgBackend(obj.imgPath);
        end
        
        function imgBackend = getMatchingImgBackend(obj, imgPath)
            [~,fnameTmp,fExt]=fileparts(imgPath);
            if any(strcmp(fExt,{'.gz','.bz2'})) %If we have a compressed image, fetch the next extension as well
                [~,~,fExt2]=fileparts(fnameTmp);
                fExt = [fExt2 fExt];
            end
            imgBackendName = obj.imgBackends.loader(strcmpi(obj.imgBackends.ext,fExt));
            if isempty(imgBackendName)
                error(['Couldn''t find a compatible handler for ' obj.imgPath '\n' ...
                    'only the following file extensions are supported: ' strjoin(obj.imgBackends.ext,' ')])
            end
            constructor = str2func(imgBackendName{1});
            imgBackend = constructor(obj.imgPath);
        end
        
        function img = get.img(obj)
            img=obj.imgBackend.img;
        end
        
        function obj = set.img(obj, img)
            obj.imgBackend.img = img;
        end
        
        function pixdim = get.pixdim(obj)
            pixdim = obj.imgBackend.pixdim;
        end
    end
    
end

