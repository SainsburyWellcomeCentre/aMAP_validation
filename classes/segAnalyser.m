classdef segAnalyser
    %SEGANALYSER main class managing the analysis
    %   Computation of user/automated scores can be launched through
    %   this class.
    
    properties
        atlasImagePath='';
        stapleDir;
        atlas;
        niftySegs=struct2table(struct('pavelRegionID',[],'tvStackPos',[],'atlasPos',[], 'correctionMatrix', [], 'width', [], 'height', [],...
            'diceSTAPLE', [], 'diceSBA', [], 'maxDiceSTAPLE', [], 'maxDiceSBA', [],...
            'hdSTAPLE', [], 'hdSBA', [], 'minHdSTAPLE', [], 'minHdSBA', [],'region', []));
        segTable;
        brainName;
        avgSegLoader;
        manSegBaseDirs;
        tmpDir;
        scale;
    end
    
    properties(Dependent)
        meanDiceStapleNoSg
        diceScoresStaple
        diceScoresSBA
        maxSliceNum
    end
    
    properties(SetAccess=private)
        initialized=false;
    end
    
    methods
        
        function obj = segAnalyser(atlasImagePath, brainName, manSegBaseDirs, stapleDir, tmpDir, scale)
            obj.tmpDir = tmpDir;
            obj.manSegBaseDirs = manSegBaseDirs;
            obj.atlasImagePath = atlasImagePath;
            obj.brainName=brainName;
            obj.avgSegLoader = AverageSegmentationLoader(stapleDir, scale);
            obj.stapleDir = stapleDir;
            obj.scale = scale;
        end
        
        function meanDiceStapleNoSg = get.meanDiceStapleNoSg(obj)
            meanDiceStapleNoSg= mean(obj.niftySegs.maxDiceSTAPLE(~strcmp(obj.niftySegs.region,'SG')));
        end
        
        function diceScoresStaple = get.diceScoresStaple(obj)
            diceScoresStaple= obj.niftySegs.maxDiceSTAPLE;
        end
        
        function diceScoresSBA = get.diceScoresSBA(obj)
            diceScoresSBA= obj.niftySegs.maxDiceSTAPLE;
        end
        
        function maxSliceNum = get.maxSliceNum(obj)
            maxSliceNum=max(obj.segTable.sliceNum);
        end
        
        function obj = initData(obj)
            obj.atlas = pavelAtlas(obj.atlasImagePath, obj.tmpDir);
            obj.segTable = getSegmentationSessionData(obj.manSegBaseDirs);
            obj.segTable = obj.segTable(obj.segTable.brain==obj.brainName,:);
            
            obj.initialized=true;
        end
        
        function obj = removeUnsegmentedHemisphere(obj)
            switch obj.brainName
                case 'MV_Ntsr1_165'
                    midline = 551;
                case 'MV_Ntsr1_169'
                    midline = 522;
                case 'CR_Syt6CreRfp_35'
                    midline = 503;
                case 'ER_Glt25d2Cre_9'
                    midline = 407;
                case 'AB_Gad67_223'
                    midline = 513;
                case 'MV131017_7'
                    midline = 530;
                otherwise
                    error('Brain Name not known');
            end
            obj.atlas = obj.atlas.setToZero(1:midline);
        end
        
        function regions = getBrainRegionNames(obj)
            regions = unique(obj.segTable.region);
        end
        
        function tbl = getAutomatedSegResultsTable(obj)
            brainNames=[];
            for i=1:numel(obj)
                brainNames = [brainNames; repmat({obj(i).brainName}, size(obj(i).niftySegs,1),1)];
            end
            tbl = vertcat(obj.niftySegs);
            tbl.brain = brainNames;
            tbl.brainRegionComb = strcat(tbl.brain, tbl.region);
            tbl.brainRegionComb = categorical(tbl.brainRegionComb);
            tbl.region = categorical(tbl.region);
            tbl.brain = categorical(tbl.brain);
        end
        
        function obj = addAtlasRegionAtlasCoordinate(obj, pavelRegionID, shiftStruct)
            obj.niftySegs = [obj.niftySegs; obj.makeSegmentationTableRow(pavelRegionID, shiftStruct)];
        end
        
        % attempt to score the average computed from a set of segmentations
        % by comparing the staple and sba averages. Not used in the final analysis.
        function obj = scoreQualityOfAverage(obj) 
            qualityScore(size(obj.niftySegs,1))=NaN;
            for i = 1:size(obj.niftySegs,1)
                bsID = obj.makeBrainRegionCombID(obj.brainName, obj.niftySegs.pavelRegionID(i));
                stapleAvg = obj.avgSegLoader.getSTAPLE(bsID);
                sbaAvg = obj.avgSegLoader.getSBA(bsID);
                stapleAvg = stapleAvg.img;
                sbaAvg = sbaAvg.img;
                qualityScore(i) = diceScore(stapleAvg, sbaAvg);
            end
            obj.niftySegs.qualityScore = qualityScore';
        end
        
        function obj = scoreSegmentations(obj)
            obj = obj.scoreManualSegs();
            obj = obj.scoreNiftySegs();
        end
        
        function obj = scoreManualSegs(obj)
            if ~obj.initialized
                error('Not Initialized');
            end
            obj.segTable.diceSTAPLE=nan(size(obj.segTable,1),1);
            obj.segTable.diceSBA=nan(size(obj.segTable,1),1);
            obj.segTable.hdSTAPLE=nan(size(obj.segTable,1),1);
            obj.segTable.hdSBA=nan(size(obj.segTable,1),1);
            
            for i = 1:size(obj.niftySegs,1)
                bsID = obj.makeBrainRegionCombID(obj.brainName, obj.niftySegs.pavelRegionID(i));
                currTable=obj.segTable(obj.segTable.brainRegionComb==bsID,:); %brainRegionComb is categorical!
                stapleAvg = obj.avgSegLoader.getSTAPLE(bsID);
                sbaAvg = obj.avgSegLoader.getSBA(bsID);
                stapleAvg = stapleAvg.img;
                sbaAvg = sbaAvg.img;
                stapleRes = segAnalyser.getStapleResults(obj.stapleDir, bsID);
                for j = 1:size(currTable,1)
                    %currUser = currTable.user(j);
                    currIdx = currTable.idx(j);
                    currStapleRes = stapleRes(strcmp(currTable.user(j), {stapleRes.user}));
                    if isempty(currStapleRes) || ~any(currIdx==[currStapleRes.idx])
                        continue
                    end
                    newImg = imread(char(currTable.path(j)));
                    newImg = newImg'>0;
                    if obj.scale~=1
                        newImg = imresize(newImg, obj.scale);
                    end
                    %score dice and hausdorff here for both STAPLE avg and SBA and store result
                    [newImg, stapleAvg] = padToLarger(newImg, stapleAvg);
                    [newImg, sbaAvg] = padToLarger(newImg, sbaAvg); % sbaAvg.img and stapleAvg.img should be of identical size
                    %find the row in segTable that is the equivalent to the
                    %one we have in currTable
                    targetRow = ismember(obj.segTable(:,1:8), currTable(j,1:8));
                    obj.segTable.diceSTAPLE(targetRow) = diceScore(newImg, stapleAvg);
                    obj.segTable.diceSBA(targetRow) = diceScore(newImg, sbaAvg);
                    obj.segTable.hdSTAPLE(targetRow) = hausdorffFromImages(newImg, stapleAvg);
                    obj.segTable.hdSBA(targetRow) = hausdorffFromImages(newImg, sbaAvg);
                end
            end
            obj = obj.scoreQualityOfAverage();
        end
        
        function obj = scoreNiftySegs(obj)
            if ~obj.initialized
                error('Not Initialized');
            end
            
            for i = 1:size(obj.niftySegs,1)
                atlasPosList = [obj.niftySegs(i,:).atlasPos(1) : obj.niftySegs(i,:).atlasPos(2)];
                bsID = obj.makeBrainRegionCombID(obj.brainName, obj.niftySegs.pavelRegionID(i));
                currWidth = round(obj.niftySegs.width(i)*obj.scale);
                currHeight = round(obj.niftySegs.height(i)*obj.scale);
                flip = segAnalyser.hemisphereNeedsFlipping(bsID);
                tmpImgs = obj.atlas.makeAtlasSegStack(obj.niftySegs.pavelRegionID(i), atlasPosList, obj.niftySegs.correctionMatrix(i), currWidth, currHeight, [0.001/obj.scale 0.015 0.001/obj.scale], flip);
                stapleAvg = obj.avgSegLoader.getSTAPLE(bsID);
                sbaAvg = obj.avgSegLoader.getSBA(bsID);
                stapleAvg = stapleAvg.img;
                sbaAvg = sbaAvg.img;
                diceSTAPLE = [];
                diceSBA = [];
                hdSTAPLE=[];
                hdSBA=[];
                for j=1:numel(atlasPosList)
                    [currRegImg, stapleAvg] = padToLarger(tmpImgs(:,:,j), stapleAvg);
                    [currRegImg, sbaAvg] = padToLarger(currRegImg, sbaAvg);
                    diceSTAPLE(j) = diceScore(currRegImg, stapleAvg);
                    diceSBA(j) = diceScore(currRegImg, sbaAvg);
                    hdSTAPLE(j) = hausdorffFromImages(currRegImg, stapleAvg);
                    hdSBA(j) = hausdorffFromImages(currRegImg, sbaAvg);
                end
                obj.niftySegs.diceSTAPLE{i} = diceSTAPLE;
                obj.niftySegs.diceSBA{i} = diceSBA;
                obj.niftySegs.maxDiceSTAPLE(i) = max(diceSTAPLE);
                obj.niftySegs.maxDiceSBA(i) = max(diceSBA);
                obj.niftySegs.hdSTAPLE{i} = hdSTAPLE;
                obj.niftySegs.hdSBA{i} = hdSBA;
                obj.niftySegs.minHdSTAPLE(i) = min(hdSTAPLE);
                obj.niftySegs.minHdSBA(i) = min(hdSBA);
            end
        end
        
        function result = makeSegOutlineFromBrComb(obj, brComb, mode, range)
            if nargin<4
                range=[];
            end
            if nargin<3
                mode=[];
            end
            currSA=[];
            [brainID, regionID] = segAnalyser.splitBrainRegionCombID(brComb);
            for i=1:numel(obj)
                if strcmp(obj(i).brainName, brainID)
                    currSA = obj(i);
                    break;
                end
            end
            if isempty(currSA)
                error(['No matching segAnalyser found for ' brComb]);
            end
            result = currSA.makeSegOutlineImg(regionID, mode, range);
        end
        
        function result = makeSegOutlineImg(obj, region, mode, range)
            
            userColor=0;
            cmpColor=200;
            stapleColor=225;
            sbaColor=255;
            if isnumeric(region)
                regionIdx = region;
            else ischar(region)
                regionIdx = pavelAtlas.getPavelRegionIDFromSegAbbrev(region);
            end
            segRow = obj.niftySegs(obj.niftySegs.pavelRegionID==regionIdx,:);
            atlasPosList = [segRow.atlasPos(1) : segRow.atlasPos(2)];
            bsID = obj.makeBrainRegionCombID(obj.brainName, regionIdx);
            currTable=obj.segTable(obj.segTable.brainRegionComb==bsID,:); %brainRegionComb is categorical!
            currWidth = round(segRow.width*obj.scale);
            currHeight = round(segRow.height*obj.scale);
            flip = segAnalyser.hemisphereNeedsFlipping(bsID);
            cmpImg = obj.atlas.makeAtlasSegStack(segRow.pavelRegionID, atlasPosList, segRow.correctionMatrix, currWidth, currHeight, [0.001/obj.scale 0.015 0.001/obj.scale], flip);
            cmpImg = cmpImg(:,:,find(segRow.diceSBA{1}==max(segRow.diceSBA{1})));
            
            if nargin==2 || isempty(mode)
                doStack = false;
                outline = rasterOutlineImg(currWidth, currHeight, 1);
            elseif strcmp(mode,'stack')
                doStack = true;
                outline = rasterOutlineImg(currWidth, currHeight, obj.maxSliceNum);
            elseif strcmp(mode,'vector')
                doStack = false;
                outline = vectorOutlineImg(currWidth, currHeight);
                userColor=[0.5 0.5 0.5];
                cmpColor='r';
                stapleColor='g';
                sbaColor='m';
            else
                error(['Mode argument must be either ''stack'', ''vector'' or empty. (It was ' mode ')']);
            end
            
            if nargin<4 || isempty(range)
                range=[min(currTable.sliceNum):max(currTable.sliceNum)];
            end
            
            
            outline =  outline.addImg(cmpImg, 1, cmpColor);
            
            stapleAvg = obj.avgSegLoader.getSTAPLE(bsID);
            sbaAvg = obj.avgSegLoader.getSBA(bsID);
            pos=1;
            if doStack
                pos = round(median(currTable.sliceNum));
            end
            
            outline = outline.addImg(stapleAvg.img, pos, stapleColor);
            outline = outline.addImg(sbaAvg.img, pos, sbaColor);
            
            %only use one of the repeats
            userRegionID = strcat(currTable.user,cellstr(currTable.brainRegionComb));
            [~,uniqueIDs,~] = unique(userRegionID);
            currTable = currTable(uniqueIDs,:);

            for j = 1:size(currTable,1)
                userImg = imread(char(currTable.path(j)));
                if obj.scale~=1
                    userImg = imresize(userImg, obj.scale);
                end
                if doStack
                    pos = currTable.sliceNum(j);
                end
                if any(range==currTable.sliceNum(j))
                    if numel(userColor)==1;
                        userColor = userColor+1;
                    end
                    outline = outline.addImg(userImg', pos, userColor);
                end
            end
            result = outline.getOutline();
        end
    end
    
    methods (Hidden)
        
        function seg = makeSegmentationTableRow(obj, pavelRegionID, shiftStruct)
            seg = struct();
            seg.pavelRegionID = pavelRegionID;
            seg.atlasPos = shiftStruct.zRange;
            seg.tvStackPos = NaN;
            seg.correctionMatrix = shiftStruct.shift;
            seg.width = shiftStruct.width;
            seg.height = shiftStruct.height;
            seg.diceSTAPLE= {};
            seg.diceSBA= {};
            seg.maxDiceSTAPLE= NaN;
            seg.maxDiceSBA= NaN;
            seg.hdSTAPLE= {};
            seg.hdSBA= {};
            seg.minHdSTAPLE= NaN;
            seg.minHdSBA= NaN;
            seg.region = pavelAtlas.getSegAbbrevFromPavelRegionID(pavelRegionID);
            seg=struct2table(seg,'AsArray', true);
        end
        
    end
    
    methods (Static)
        function combID = makeBrainRegionCombID(brainName, pavelRegionID)
            combID = [brainName, pavelAtlas.getSegAbbrevFromPavelRegionID(pavelRegionID)];
        end
        
        function [brainName, regionName] = splitBrainRegionCombID(brID)
            brainName='';
            if strfind(brID, 'CR_Syt6CreRfp_35')
                brainName = 'CR_Syt6CreRfp_35';
            elseif strfind(brID, 'MV_Ntsr1_165')
                brainName = 'MV_Ntsr1_165';
            elseif strfind(brID, 'MV_Ntsr1_169')
                brainName = 'MV_Ntsr1_169';
            elseif strfind(brID, 'MV131017_7')
                brainName = 'MV131017_7';
            elseif strfind(brID, 'AB_Gad67_223')
                brainName = 'AB_Gad67_223';
            elseif strfind(brID, 'ER_Glt25d2Cre_9')
                brainName = 'ER_Glt25d2Cre_9';
            end
            
            regionName=brID(length(brainName)+1:end);
        end
        
        function result=hemisphereNeedsFlipping(brainRegionCombID)
            if strcmp(brainRegionCombID, segAnalyser.makeBrainRegionCombID('MV_Ntsr1_169', 632)) %flip hemisphere on SG on Mateos Ntsr1 169
                result=true;
            else
                result=false;
            end
        end
        
        function img = addOutline(img, outline, sliceNum)
            sz1 = min(size(img,1), size(outline,1));
            sz2 = min(size(img,2), size(outline,2));
            img(1:sz1, 1:sz2, sliceNum) = max(img(1:sz1, 1:sz2, sliceNum), outline(1:sz1, 1:sz2));
        end
        
        function make4Dnii(niiFileList, outputImgPath)
            imgsToJoin = strjoin(niiFileList(2:end), ' ');
            sm_command = ['seg_maths',niiFileList(1),'-merge ',num2str(numel(niiFileList(2:end))),'4',imgsToJoin,outputImgPath];
            sm_command = strjoin(sm_command, ' ');
            system(sm_command);
        end
        
        function logOut=runSTAPLE(nii4dPath, stapleOutPath, userList)
            stapleCommand = {'seg_LabFusion','-in',nii4dPath,'-STAPLE','-unc','-out',stapleOutPath, '-v 2'};
            stapleCommand = strjoin(stapleCommand, ' ');
            [~,logOut] = system(stapleCommand,'-echo');
            logOut = sprintf('%s\n%s\n%s', logOut, stapleCommand, strjoin(userList,';'));
            logOut = textscan(logOut,'%s');
            logOut = logOut{1};
        end
        
        function resultImg = cropBottomRight(img)
            [row, clmn] = find(img>0);
            resultImg = img;
            resultImg(max(row)+1:size(resultImg,1),:)=[];
            resultImg(:,max(clmn)+1:size(resultImg,2))=[];
        end
        
        function [maxX, maxY] = getMaxImgSize(pathList)
            maxX=0; maxY=0;
            for i= 1:numel(pathList)
                imgInfo = imfinfo(char(pathList(i)));
                maxX = max(maxX,imgInfo.Width);
                maxY = max(maxY,imgInfo.Height);
            end
        end
        
        function stapleStruct = getStapleResults(stapleDir, brainRegionComb)
            stapleOutDirCont = dir(stapleDir);
            stapleOutDirCont = {stapleOutDirCont.name};
            for fileName = stapleOutDirCont
                fileName = char(fileName);
                if ~strendswith(fileName,'STAPLE_log.txt') || ~strcmp(brainRegionComb,fileName(1:end-28))
                    continue;
                end
                stapleLogPath = fullfile(stapleDir,fileName);
                lf = fopen(stapleLogPath);
                logStr = textscan(lf,'%s');
                logStr=logStr{1};
                fclose(lf);
                stapleStruct = getRaterScore(logStr, brainRegionComb);
                return;
            end
        end
    end
end

