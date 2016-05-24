classdef userRater
    %USERRATER takes care of the operations needed to score the human
    %raters
    
    properties
        manSegBaseDirs;
        nii4dDir;
        segTable;
        indexVect;
        brCombValues;
        maxX=0;
        maxY=0;
        scale;
        stapleOutDir;
        seg_maths = fullfile(sharedParams.getBaseDir, 'nonMatlab', 'niftyseg_build', 'seg-apps', 'seg_maths');
        %if you have niftyseg install globally, change the following to an empty string:
        niftySegDir = fullfile(sharedParams.getBaseDir, 'nonMatlab', 'niftyseg_build', 'seg-apps');
    end
    
    methods
        function obj = userRater(manSegBaseDirs, nii4dDir, stapleOutDir, scale)
            obj.manSegBaseDirs = manSegBaseDirs;
            obj.nii4dDir = nii4dDir;
            obj.segTable = getSegmentationSessionData(manSegBaseDirs);
            obj.indexVect = grp2idx(obj.segTable.brainRegionComb);
            obj.brCombValues = unique(obj.indexVect);
            for i= 1:size(obj.segTable,1)
                imgInfo = imfinfo(char(obj.segTable.path(i)));
                obj.maxX = max(obj.maxX,imgInfo.Width);
                obj.maxY = max(obj.maxY,imgInfo.Height);
            end
            obj.stapleOutDir = stapleOutDir;
            obj.scale = scale;
        end
        
        function resizeSegImgsToMax(obj)
            for i= 1:size(obj.segTable,1)
                imInfo = imfinfo(char(obj.segTable.path(i)));
                if imInfo.Width ~= obj.maxX || imInfo.Height ~= obj.maxY
                    oldImg = imread(char(obj.segTable.path(i)));
                    newImg=zeros(obj.maxY,obj.maxX);
                    newImg(1:size(oldImg, 1), 1:size(oldImg, 2)) = oldImg;
                    imwrite(uint8(newImg), char(obj.segTable.path(i)));
                end
            end
        end
        
        function create4dNii(obj, varargin)
            %% create 4d segmentation images for STAPLE, use both segmentations from one rater as individual data point
            %does not work with full res images, downscaling is necessary
            quants=[];
            range=[];
            if nargin>1 && ~isempty(varargin{1})
                mode=varargin{1};
                if strcmp(mode, 'range')
                    range=varargin{2};
                elseif strcmp(mode, 'quantiles')
                    quants=varargin{2};
                else
                    error('Invalid input arguments. Input arguments must be mode (either ''range'' or ''quantiles'' followed by the range definition)');
                end
            else
                range=10000000;
            end
            for i = 1:numel(obj.brCombValues)
                currTable = obj.segTable(obj.indexVect==i,:);
                sliceNums = [currTable.sliceNum];
                if ~isempty(range)
                    edges = [0:max(sliceNums)]+0.5;
                    [sliceFreq, ~] = histcounts(sliceNums, edges);
                    if range>=numel(sliceFreq)
                        validSlices=[min(sliceNums):max(sliceNums)];
                    else
                        sliceRangeCount = zeros(numel(sliceFreq),1);
                        for j=1:numel(sliceFreq)-range+1
                            sliceRangeCount(j)=sum(sliceFreq(j: j+range-1));
                        end
                        maxSlice=find(sliceRangeCount==max(sliceRangeCount));
                        maxSlice = maxSlice(1);
                        validSlices = [maxSlice : maxSlice+range-1];
                    end
                    %debug catch here:
                    if max(validSlices)-min(validSlices)>range
                        dbstop if error;
                        error(['Slice range botched up! in' currTable.brainRegionComb(1)]);
                    end
                else
                    qt=quantile(sliceNums, quants)
                    validSlices=[floor(qt(1)):floor(qt(2))];
                end
                
                if ~exist(obj.nii4dDir, 'dir')
                    mkdir(obj.nii4dDir)
                end
                
                currTable = currTable(ismember(currTable.sliceNum, validSlices),:);
                
                niiImgList=cell(1,size(currTable,1));
                userList='';
                for j = 1:size(currTable,1)
                    tifPath = char(currTable.path(j));
                    userList = [userList,{[currTable.user{j},':',num2str(currTable.idx(j))]}];
                    newImg = zeros(obj.maxX,obj.maxY);
                    newImg(:,:) = imread(tifPath)';
                    newImg = uint8(newImg>0);
                    newImg = imresize(newImg, obj.scale, 'nearest');
                    niiImg = make_nii(newImg);
                    niiImgList(j) = {[tifPath(1:end-4), '_',num2str(obj.scale),'.nii']};
                    save_nii(niiImg, char(niiImgList(j)));
                end
                
                outputImg = strcat(char(currTable.brainRegionComb(1)),'_',num2str(obj.scale),'_4DSegMathsMerged.nii.gz');
                outputImg = fullfile(obj.nii4dDir, outputImg);
                imgsToJoin = strjoin(niiImgList(2:end), ' ');
                sm_command = [fullfile(obj.niftySegDir, 'seg_maths'),niiImgList(1),'-merge ',num2str(numel(niiImgList(2:end))),'4',imgsToJoin,outputImg];
                sm_command = strjoin(sm_command, ' ')
                commandFilePath = strcat(char(currTable.brainRegionComb(1)),'_',num2str(obj.scale),'_4DSegMathsMergeCommand.txt');
                commandFilePath = fullfile(obj.nii4dDir, commandFilePath)
                commandFile = fopen(commandFilePath,'w');
                fprintf(commandFile,'%s\n', sm_command);
                fprintf(commandFile,'%s', strjoin(userList,';'));
                fclose(commandFile);
                system(sm_command);
                cellfun(@delete, niiImgList);
            end
        end
        
        function runStaple(obj)
            %% running the STAPLE and SBA analysis
            nii4dDirCont = dir(obj.nii4dDir);
            nii4dDirCont = {nii4dDirCont.name};
            if ~exist(obj.stapleOutDir, 'dir')
                mkdir(obj.stapleOutDir)
            end
            for fileName = nii4dDirCont
                fileName = char(fileName);
                nii4dPath = fullfile(obj.nii4dDir,fileName);
                if ~strendswith(nii4dPath,'.nii.gz')
                    continue;
                end
                logName = [fileName(1:end-28),num2str(obj.scale),'_','4DSegMathsMergeCommand.txt']
                lf = fopen(fullfile(obj.nii4dDir,logName));
                userStr = textscan(lf,'%s');
                userStr=userStr{1};
                userStr=userStr{end};
                fclose(lf);
                
                fnUs = strfind(char(fileName),'_');
                outPathSTAPLE = [fileName(1:fnUs(end)),'NiftySegSTAPLE.nii'];
                outPathSTAPLE = fullfile(obj.stapleOutDir, outPathSTAPLE);
                outPathSBA = [fileName(1:fnUs(end)),'NiftySegSBA.nii'];
                outPathSBA = fullfile(obj.stapleOutDir, outPathSBA);
                outPathLog = [fileName(1:fnUs(end)),'NiftySegSTAPLE_log.txt'];
                outPathLog = fullfile(obj.stapleOutDir, outPathLog);
                
                segLfCommand = fullfile(obj.niftySegDir, 'seg_LabFusion');
                stapleCommand = {segLfCommand,'-in',nii4dPath,'-STAPLE','-unc','-out',outPathSTAPLE, '-v 2'};
                stapleCommand = strjoin(stapleCommand, ' ');
                sbaCommand = {segLfCommand,'-in',nii4dPath,'-SBA','-out',outPathSBA};
                sbaCommand = strjoin(sbaCommand, ' ');
                
                [~,logOut] = system(stapleCommand,'-echo');
                logFile = fopen(outPathLog,'w');
                fprintf(logFile,'%s\n', logOut);
                fprintf(logFile,'%s\n', stapleCommand);
                fprintf(logFile,'%s', userStr);
                fclose(logFile);
                system(sbaCommand, '-echo');
            end
        end
        function obj = parseStapleResults(obj)
            %% getting the results of the staple analysis out and assigning it to the table
            
            stapleOutDirCont = dir(obj.stapleOutDir);
            stapleOutDirCont = {stapleOutDirCont.name};
            obj.segTable(:,'p')={NaN};
            obj.segTable(:,'q')={NaN};
            for fileName = stapleOutDirCont
                fileName = char(fileName);
                if ~strendswith(fileName,'STAPLE_log.txt')
                    continue;
                end
                stapleLogPath = fullfile(obj.stapleOutDir,fileName);
                lf = fopen(stapleLogPath);
                logStr = textscan(lf,'%s');
                logStr=logStr{1};
                fclose(lf);
                brainRegionComb = fileName(1:end-28);
                results = getRaterScore(logStr, brainRegionComb);
                indices = find(obj.segTable.brainRegionComb==brainRegionComb);
                for i = 1:numel(results)
                    for j = 1:numel(indices)
                        if strcmp(obj.segTable.user(indices(j)),results(i).user)&&...
                                obj.segTable.idx(indices(j))==results(i).idx
                            obj.segTable.p(indices(j))=results(i).p;
                            obj.segTable.q(indices(j))=results(i).q;
                            break;
                        end
                    end
                end
            end
        end
    end
    
end

