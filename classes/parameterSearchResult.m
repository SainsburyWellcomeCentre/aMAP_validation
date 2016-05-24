classdef parameterSearchResult
    %PARAMETERSEARCHRESULT represents a (niftyreg) registration run performed using a
    %certain set of parameters. Can be used to start a scoring run.
    %   Detailed explanation goes here
    
    properties
        segAnalyserObj
        cppPath
        resampleDir
        parameterMap
        atlasNiiPath;
        brainNiiPath;
        stapleDir;
        knownParameters = {'sx','be','ln','lp','smoo','nmi','lncc','rbn','fbn'};
    end
    
    properties(Dependent)
        cppName
        meanDiceStaple
        meanDiceStapleNoSg
        medDiceStapleNoSg
        allDiceStapleNoSg
        brainName
    end
    
    properties(Hidden)
        parametersLocked = false;
    end
    
    methods
        function obj = parameterSearchResult(cppPath, resampleDir, atlasNiiPath, brainNiiPath, stapleDir, varargin)
            error('This class is defunkt at the moment and being rewritten, please bear with us');
            obj.parameterMap = containers.Map();
            obj.cppPath = cppPath;
            obj.resampleDir = resampleDir;
            if length(varargin)==1
                obj.parameterMap = varargin{1};
            else
                obj = obj.addParamsFromCppName();
            end
            obj.atlasNiiPath = atlasNiiPath;
            obj.brainNiiPath = brainNiiPath;
            obj.stapleDir = stapleDir;
        end
        
        function cppName = get.cppName(obj)
            [~,base,ext] = fileparts(obj.cppPath);
            cppName = [base ext];
        end
        
        function brainName = get.brainName(obj)
            brainName = parameterSearchResult.getBrainName(obj.cppName);
        end
        
        function meanDiceStaple = get.meanDiceStaple(obj)
            if isempty(obj.segAnalyserObj)
                meanDiceStaple=nan;
            else
                meanDiceStaple= mean(obj.segAnalyserObj.diceScoresStaple);
            end
        end
        
        function meanDiceStapleNoSg = get.meanDiceStapleNoSg(obj)
            if isempty(obj.segAnalyserObj)
                meanDiceStapleNoSg=nan;
            else
                meanDiceStapleNoSg= obj.segAnalyserObj.meanDiceStapleNoSg;
            end
        end
        
        function allDiceStapleNoSg = get.allDiceStapleNoSg(obj)
            if isempty(obj.segAnalyserObj)
                allDiceStapleNoSg = [];
            else
                allDiceStapleNoSg = obj.segAnalyserObj.diceScoresStaple(~strcmp(obj.segAnalyserObj.niftySegs.region,'SG'));
            end
        end
        
        function medDiceStapleNoSg = get.medDiceStapleNoSg(obj)
            medDiceStapleNoSg = median(obj.allDiceStapleNoSg);
        end
        
        function obj = addParamsFromCppName(obj)
            for i=1:numel(obj.knownParameters)
                obj = obj.setParameter(obj.knownParameters{i});
            end
        end
        
        function obj = fixParameterMap(obj)
            oldLocked = obj.parametersLocked;
            obj.parametersLocked = false;
            obj.parameterMap = containers.Map();
            obj = obj.addParamsFromCppName();
            obj.parametersLocked = oldLocked;
        end
        
        function obj = setParameter(obj, name)
            if obj.parametersLocked
                error('parameter map has been locked')
            end
            value =  obj.findParameter(obj.cppName, name);
            if isempty(value)
                return
            else
                obj.parameterMap(name) = value;
            end
        end
        
        function obj = lockParameterMap(obj)
            obj.parametersLocked = true;
        end
        
        function obj = calculateScores(obj, varargin)
            if numel(varargin)==1
                calculateUser=varargin{1};
            else
                calculateUser=false;
            end
            % resample nii file
            % generate result object
            if ~obj.parametersLocked
                obj = obj.lockParameterMap();
            end
            
            obj.segAnalyserObj = calculateRegistrationScores...
                (obj.getBrainName(obj.cppName),  obj.lazyAtlasResample(), obj.stapleDir, obj.computerID, calculateUser, true);
        end
        
        function atlasPath = lazyAtlasResample(obj)
            atlasPath = fullfile(obj.resampleDir, obj.makeAtlasFilename());
            if exist(atlasPath, 'file')
                return
            end
            fltPar = [' -flo ' obj.atlasNiiPath];
            refPar = [' -ref ' obj.brainNiiPath];
            resPar = [' -res ' atlasPath];
            transPar = [' -cpp ' obj.cppPath];
            otherPar = ' -inter 0';
            fullCmd = ['reg_resample' transPar fltPar refPar resPar otherPar];
            [status, cmdOut] = system(['bash ~/poltergeist.sh ' fullCmd], '-echo');
            if status~=0
                error('booooom');
            end
        end
        
        function resStr = stringFromParameters(obj)
            params = obj.parameterMap.keys();
            resStr='';
            for i=1:numel(params)
                currParam = char(params(i));
                resStr=[resStr '_' currParam num2str(obj.parameterMap(currParam))];
            end
        end
        
        function atlasName = makeAtlasFilename(obj)
            atlasName = [obj.getBrainName(obj.cppName) '_' obj.cppName(1:end-4) '_MAP.nii']
        end
        
    end
    
    methods (Static)
        function brainName=getBrainName(cppName)
            if ~isempty(strfind(cppName,'ref_0')) || ~isempty(strfind(cppName,'CR_Syt6_cre_rfp_35'))
                brainName = 'CR_Syt6CreRfp_35';
            elseif ~isempty(strfind(cppName,'ref_1')) || ~isempty(strfind(cppName,'MV_Ntsr1_165'))
                brainName = 'MV_Ntsr1_165';
            elseif ~isempty(strfind(cppName,'ER_Glt25d2Cre_9_5umstack'))
                brainName = 'ER_Glt25d2Cre_9';
            elseif ~isempty(strfind(cppName,'GAD67GFP_223'))
                brainName = 'AB_Gad67_223';
            elseif ~isempty(strfind(cppName,'MV_131017_MV_7'))
                brainName = 'MV131017_7';
            elseif ~isempty(strfind(cppName,'Ntsr1_169'))
                brainName = 'MV_Ntsr1_169';
                
            end
            
        end
        
        function parameter=findParameter(string, pattern)
            startIdx = strfind(string,pattern);
            if numel(startIdx)~=1
                parameter = [];
                return;
            end
            startIdx = startIdx+length(pattern);
            endIdx = startIdx;
            while true
                if endIdx+1 > length(string)
                    break;
                end
                %if the currect charakter is not a number or a point
                %followed by a number break out of the loop
                if isnan(str2double(string(endIdx+1))) &&...
                        ~(strcmp(string(endIdx+1),'.')&& ~isnan(str2double(string(endIdx+2))));
                    break
                end
                endIdx = endIdx+1;
            end
            parameter = str2double(string(startIdx:endIdx));
        end
    end
end

