classdef sharedParams
    %SHAREDPARAMS Class to provide access to all the global parameters such
    %as paths to images, etc...
    %   Detailed explanation goes here

    properties (Constant)
        defaultRegistration='128HistoBins_Ln6Lp4Smo1';
        globalParamsYml='globalData.yml';
        registrationYml='registrations.yml';
        shiftYml='brainShifts.yml';
    end
    
    properties
        globalDataStruct
        registrationId
        registration
        brains
        regions
        shifts
    end
    
    properties(Dependent)
        registeredAtlasPaths
        scale
        brainNames
        registeredAtlasBaseDir
        brainBaseDir
        paramSearchCppDir
        resampleDir
        atlasPath
        manSegBaseDirs
        tmpDir
        stackSize
    end
    
    methods
        function obj = sharedParams(varargin)
            if nargin==0
                obj.registrationId=sharedParams.defaultRegistration;
            else
                obj.registrationId=varargin{1};
            end
            obj.globalDataStruct = readSimpleYAML(fullfile(sharedParams.getDataDir(),obj.globalParamsYml));
            obj.brains = struct2table(obj.globalDataStruct.brains);
            obj.regions = struct2table(obj.globalDataStruct.regionsUsed);
            
            obj.shifts = readSimpleYAML(fullfile(sharedParams.getDataDir(),obj.shiftYml));
            obj.shifts = struct2table(obj.shifts.brainShifts);
            
            registrationList = readSimpleYAML(fullfile(sharedParams.getDataDir(),obj.registrationYml));
            registrationList = registrationList.runs;
            
            regIDs = categorical({registrationList.idString});
            obj.registration = registrationList(regIDs==obj.registrationId);
            if isempty(obj.registration)
                error('couldn''t find the registration');
            end
        end
        
        function registeredAtlasPaths = get.registeredAtlasPaths(obj)
            registeredAtlasPaths = obj.registration.atlasNames;
        end
        
        function scale = get.scale(obj)
            scale = obj.globalDataStruct.scale;
        end
        
        function brainNames = get.brainNames(obj)
            brainNames = obj.registration.brainNames;
        end
        
        function atlasBaseDir = get.registeredAtlasBaseDir(obj)
            atlasBaseDir = obj.registration.atlasDir;
        end
        
        function brainBaseDir = get.brainBaseDir(obj)
            brainBaseDir=obj.globalDataStruct.brainBaseDir;
        end
        
        function paramSearchCppDir = get.paramSearchCppDir(obj)
            paramSearchCppDir = obj.globalDataStruct.paramSearchCppDir;
        end
        
        function resampleDir = get.resampleDir(obj)
            resampleDir = obj.globalDataStruct.resampleDir;
        end
        
        function atlasPath = get.atlasPath(obj)
            atlasPath = obj.globalDataStruct.atlasPath;
        end
        
        function manSegBaseDirs = get.manSegBaseDirs(obj)
            manSegBaseDirs = obj.globalDataStruct.manSegBaseDirs;
        end
        
        function tmpDir = get.tmpDir(obj)
            tmpDir = obj.globalDataStruct.tmpDir;
        end
        
        function stackSize = get.stackSize(obj)
            stackSize = obj.globalDataStruct.stackSize;
        end
        
        function brainFileName = getBrainAtlasFileName(obj, brainName)
            brainNames = categorical(obj.registration.brainNames);
            brainFileName = obj.registration.atlasNames(brainNames==brainName);
            if (isempty(brainFileName))
                error('Brain Name not known');
            end
            if numel(brainFileName)>1
                error('Multiple results available for that brain, something has gone wrong')
            end
            brainFileName=brainFileName{1};
        end
        
        function niiDir = getManSegNiiDir(obj, zRange)
            niiDir = [obj.globalDataStruct.manSegNiiDirBase num2str(obj.scale)];
            if nargin==2 && ~isempty(zRange)
                if isnumeric(zRange)
                    zRange=num2str(zRange);
                end
                niiDir = [niiDir '_zRange' zRange];
            end
        end
        
        
        function stapleDir = getStapleDir(obj, zRange)
            stapleDir = obj.globalDataStruct.stapleDirBase;
            if nargin==2 && ~isempty(zRange)
                if isnumeric(zRange)
                    zRange=num2str(zRange);
                end
                stapleDir = [stapleDir '_zRange' zRange];
            end
        end
        
        function shiftStruct=getShiftStruct(obj, brainName)
            shiftStruct = obj.shifts(strcmpi(obj.shifts.name, brainName), :);
        end
        
        function brainFileName = getBrainFileName(obj, brainName)
            brainFileName = obj.brains.brainFileName(strcmpi(obj.brains.name, brainName));
        end
        
        function brainHeight = getBrainHeight(obj, brainName)
            brainHeight = obj.brains.height(strcmpi(obj.brains.name, brainName));
        end
    end
    
    methods (Static)
        function dataDir = getDataDir()
            dataDir = fullfile(sharedParams.getBaseDir(), 'data');
        end
        
        function baseDir = getBaseDir()
            [baseDir,~,~] = fileparts(mfilename('fullpath'));
            [baseDir,~,~] = fileparts(baseDir);
        end
        
        function brainName = getBrainNameFromFileName(fileName)
            brainName='';
            if strfind(fileName, 'CR_Syt6_cre_rfp_35')
                brainName = [brainName 'CR_Syt6CreRfp_35'];
            elseif strfind(fileName, 'MV_Ntsr1_165')
                brainName = [brainName 'MV_Ntsr1_165'];
            elseif strfind(fileName, 'Ntsr1_169')
                brainName = [brainName 'MV_Ntsr1_169'];
            elseif strfind(fileName, 'MV_131017_MV_7')
                brainName = [brainName 'MV131017_7'];
            elseif strfind(fileName, 'GAD67GFP_223')
                brainName = [brainName 'AB_Gad67_223'];
            elseif strfind(fileName, 'ER_Glt25d2Cre_9')
                brainName = [brainName 'ER_Glt25d2Cre_9'];
            end
        end
        
    end
end

