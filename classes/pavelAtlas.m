classdef pavelAtlas
    %PAVELATLAS Allows access to pavels atlas for segmentation
    %   Used to access the computer-generated segmentations
    
    properties
         pavelStructPath=fullfile(sharedParams.getDataDir, 'ARA2_annotation_structure_info.csv');
         pavelDataCell;
         atlas;
         tmpDir;
         pavelAtlasNiiPath;
         %if you have niftyreg installed globally, change the following to an empty string:
         niftyRegDir = fullfile(sharedParams.getBaseDir, 'nonMatlab', 'niftyReg', 'bin', 'linux_x64');
    end
    
    properties (Hidden)
        dimsToRemove=[];
    end
    
    methods
        function obj = pavelAtlas(pavelAtlasNiiPath, tmpDir)
            obj.pavelAtlasNiiPath = pavelAtlasNiiPath;
            obj.atlas = ImgSource(pavelAtlasNiiPath);
            obj.pavelDataCell = pavelAtlas.parsePavelCSV(obj.pavelStructPath);
            obj.tmpDir = tmpDir;
        end
        
        function obj = flushAtlas(obj)
            obj.atlas=[];
        end
        
        function obj = reloadAtlas(obj)
            obj.atlas = ImgSource(obj.pavelAtlasNiiPath);
        end
        
        function obj = setToZero(obj, dim1, dim2, dim3)
            if nargin<2
                error('Need at least one input dimension');
            end
            if isempty(dim1)
                dim1=1:size(obj.atlas.img, 1);
            end
            if nargin<3||isempty(dim2)
                dim2=1:size(obj.atlas.img, 2);
            end
            if nargin<4||isempty(dim3)
                dim3=1:size(obj.atlas.img, 3);
            end
            obj.dimsToRemove={dim1, dim2, dim3};
            obj.atlas.img(dim1, dim2, dim3)=0;
        end
        
        function atlasImg = makeAtlasSegStack(obj, pavelRegionID, atlasPosList, correctionMatrix, width, height, pixSize4Nii, flipHemisphere)
             
            %if pavelRegionID==509
            %    warning('Region ID 509 does no longer work with new allen, changing to 502');
            %    pavelRegionID=502;
            %end
            if nargin==8 && flipHemisphere
                smallAtlas = ImgSource(obj.pavelAtlasNiiPath);
                smallAtlas = smallAtlas.img;
                if ~isempty(obj.dimsToRemove)
                    dim1=setdiff(1:size(obj.atlas.img, 1), obj.dimsToRemove{1});
                    if isempty(dim1)
                        dim1=1:size(obj.atlas.img, 1);
                    end
                    dim2=setdiff(1:size(obj.atlas.img, 2), obj.dimsToRemove{2});
                    if isempty(dim2)
                        dim2=1:size(obj.atlas.img, 2);
                    end
                    dim3=setdiff(1:size(obj.atlas.img, 3), obj.dimsToRemove{3});
                    if isempty(dim3)
                        dim3=1:size(obj.atlas.img, 3);
                    end
                    smallAtlas(dim1,dim2,dim3)=0;
                end
                smallAtlas = smallAtlas(:,atlasPosList,:);
            else
                smallAtlas = obj.atlas.img(:,atlasPosList,:);
            end
            smallAtlNii = make_nii(smallAtlas, obj.atlas.pixdim);
            tmpAtlName = fullfile(obj.tmpDir, 'tmpAtl.nii');
            tmpRefName = fullfile(obj.tmpDir, 'tmpRef.nii');
            tmpResName = fullfile(obj.tmpDir, 'tmpOut.nii');
            tmpAffName = fullfile(obj.tmpDir, 'tmpAff.txt');
            dlmwrite(tmpAffName, correctionMatrix, ' ');
            save_nii(smallAtlNii, tmpAtlName);
            tmpRefNii = make_nii(zeros(width, numel(atlasPosList), height), pixSize4Nii);
            tmpRefNii.img =zeros(2,2,2);
            save_nii(tmpRefNii, tmpRefName);
            fltPar = [' -flo ' tmpAtlName];
            refPar = [' -ref ' tmpRefName];
            resPar = [' -res ' tmpResName];
            transPar = [' -trans ' tmpAffName];
            otherPar = [' -inter 0'];
            fullCmd = [fullfile(obj.niftyRegDir,'reg_resample') transPar fltPar refPar resPar otherPar]
            [status, cmdOut] = system(['bash ~/poltergeist.sh ' fullCmd], '-echo');
            atlasImg = load_nii(tmpResName);
            %permute and flip to bring back to TissueVision coordinate space
            atlasImg = permute(atlasImg.img, [1 3 2]);
            atlasImg = flip(atlasImg,2);
            for i = 1 : size(atlasImg, 3)
                atlasImg(:,:,i) = obj.markRegions(atlasImg(:,:,i), pavelRegionID);
            end
        end 
        
        function img = markRegions(obj, atlasImg, pavelRegionID)
            if isempty(atlasImg)
                atlasImg = obj.atlas.img;
            end
            img = false(size(atlasImg));
            indices = obj.findChildren(pavelRegionID);
            for i= 1:numel(indices)
                img = img | atlasImg==indices(i);
            end
            % remove lower bit of SG
            if pavelRegionID==632 %SG
                img=obj.removeLowerSg(img);
            end
            img = double(img);
        end
        
        function childList = findChildren(obj, ID)
            childList=ID;
            for i = 1:size(obj.pavelDataCell,1)
                if obj.pavelDataCell{i,8}==ID
                    childList = vertcat(childList,obj.findChildren(obj.pavelDataCell{i,1}));
                end
            end
        end
        
    end
    
    methods (Static)
        
        function img = removeLowerSg(img)
            startX=1;
            startY=1500;
            img(startX:end,startY:end)=0;
        end
        
        function pavelDataCell = parsePavelCSV(pavelStructPath)
            %hairy code for reading the allen/pavel csv file.. Problem is I don't
            %know how to tell matlab to ignore commas in double quotes
            delimiter = {'","',',"','",'};
            formatSpec = '%f%s%s%s%[^\n\r]';
            fileID = fopen(pavelStructPath,'r');
            pavelDataCell = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,1, 'ReturnOnError', false);
            fclose(fileID);
            pavelDataCell(1) = cellfun(@(x) num2cell(x), pavelDataCell(1), 'UniformOutput', false);
            pavelDataCell = [pavelDataCell{1:end}];
            %5 numbers are now stored in coloumn 4, so let's split them
            pavelDataCell(:,4)= cellfun(@(x) strsplit(x,','), pavelDataCell(:,4), 'UniformOutput', false);
            %copy coloumn 5 to 9 to make space for the numbers of coloumn 4
            pavelDataCell(:,9) = pavelDataCell(:,5);
            %write the 5 numbers stored in coloumn 4 to coloumns 4-8 (and
            %convert to double)
            [pavelDataCell(:,4),pavelDataCell(:,5),pavelDataCell(:,6),pavelDataCell(:,7),pavelDataCell(:,8)] =...
                cellfun(@(x) deal(str2double(x{1}), str2double(x{2}), str2double(x{3}), str2double(x{4}), str2double(x{5})),...
                pavelDataCell(:,4), 'UniformOutput', false);           
        end
        
        function regionAbbrev= getSegAbbrevFromPavelRegionID(pavelRegionID)
            if ~isnumeric(pavelRegionID)
                error('pavelRegionID is not numeric');
            end
            %if pavelRegionID==509
            %    warning('Region ID 509 does no longer work with new allen, changing to 502');
            %    pavelRegionID=502;
            %end
            aitbl = pavelAtlas.makeAbbrevIndexTable();
            regionAbbrev = char(aitbl.region(aitbl.index==pavelRegionID));
            if isempty(regionAbbrev)
                error(['No idea what pavelRegionID ' num2str(pavelRegionID) ' is']);
            end
        end
        
        function regionID= getPavelRegionIDFromSegAbbrev(regionAbbrev)
            if ~ischar(regionAbbrev)
                error('regionAbbrev needs to be a char');
            end
            aitbl = pavelAtlas.makeAbbrevIndexTable();
            regionID = aitbl.index(aitbl.struct==regionAbbrev);
            if isempty(regionID)
                error(['No idea what regionAbbrev ' regionAbbrev ' is']);
            end
        end

        function aitbl = makeAbbrevIndexTable()
            aitbl =         table(202, {'MV'}, 'VariableNames', {'index', 'region'});
            aitbl = [aitbl; table(509, {'SUB'}, 'VariableNames', {'index', 'region'})];
            %aitbl = [aitbl; table(502, {'SUB'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(632, {'SG'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(254, {'RSP'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(394, {'V2M'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(385, {'V1'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(733, {'VPM'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(88,  {'AHN'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(322, {'S1BF'}, 'VariableNames', {'index', 'region'})];
            aitbl = [aitbl; table(31, {'CING'}, 'VariableNames', {'index', 'region'})];
            aitbl.region = categorical(aitbl.region);
        end
        
    end    
end

