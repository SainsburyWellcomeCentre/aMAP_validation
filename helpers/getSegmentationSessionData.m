function segs = getSegmentationSessionData(manSegBaseDirs)
% compiles the results from the segmentation session into a table
    persistent segStatic
    if ~isempty(segStatic)
        segs = segStatic;
        return
    end
    segs = struct();
    i=1;
    for dayDir = manSegBaseDirs
        dayDirCont = dir(char(dayDir));
        dayDirCont = {dayDirCont.name};
        for userDir = dayDirCont
            workingDir = char(fullfile(dayDir,userDir));
            if ~exist(workingDir,'dir')
                continue;
            end
            segFiles = dir(workingDir);
            currUser = userDir;
            for j = 1:numel(segFiles)
                if ~strendswith(segFiles(j).name,'.tif')
                    continue
                end
                segs(i).user = currUser;
                segs(i).idx= getSegIdx(segFiles(j).name);
                segs(i).brain = getBrainName(segFiles(j).name);
                segs(i).region = getRegionName(segFiles(j).name);
                segs(i).sliceNum = getSliceNum(segFiles(j).name);
                segs(i).duration = getDuration(workingDir, segFiles, j);
                segs(i).path = fullfile(workingDir, segFiles(j).name);
                i = i+1;
            end
        end
    end
    segs = struct2table(segs);
    brainRegionComb = strcat(segs.brain, segs.region);
    segs.brainRegionComb = categorical(brainRegionComb);
    segs.region = categorical(segs.region);
    segs.brain = categorical(segs.brain);
    segStatic = segs;
end

function idx = getSegIdx(fileName)
    startIdx = strfind(fileName,'Seg')+3;
    if isempty(startIdx)
        idx = NaN;
        return;
    end
    if numel(startIdx)>1
        startIdx = startIdx(1);
    end
    endIdx = regexp(fileName(startIdx:end),'[^0-9]');
    if isempty(endIdx)
        endIdx = length(fileName);
    end
    if numel(endIdx)>1
        endIdx = endIdx(1);
    end
    endIdx = endIdx+startIdx-2;
    idx = str2double(fileName(startIdx:endIdx));
end

function name = getBrainName(fileName)
    startIdx = regexp(fileName,'[0-9][^0-9]');
    startIdx = startIdx(1)+1;
    endIdx = strfind(fileName,'.tif');
    endIdx = endIdx(1)-1;
    name = fileName(startIdx:endIdx);
    lastUs = strfind(name,'_');
    lastUs = lastUs(end);
    name=name(1:lastUs-1);
end

function name = getRegionName(fileName)
    startIdx = regexp(fileName,'\d\d\d-')+4;
    endIdx = strfind(fileName(startIdx:end), '_');
    if numel(endIdx)>1
        endIdx = endIdx(1);
    end
    endIdx = endIdx+startIdx-2;
    name = fileName(startIdx:endIdx);
end

function num = getSliceNum(fileName)
    startIdx = regexp(fileName,'Slice\d')+5;
    endIdx = regexp(fileName(startIdx:end),'\d[.]')+startIdx-1;
    num = str2double(fileName(startIdx:endIdx));
end

function duration = getDuration(workingDir, fileList, pos)
    duration=NaN;
    metaName='';
    for i=pos:-1:1
        if strendswith(fileList(i).name,'meta.txt')&&...
                strcmp(fileList(i).name(1:end-8),fileList(pos).name(1:end-5))
            metaName=fileList(i).name;
            break;
        end
    end
    if isempty(metaName)
        for i=pos:numel(fileList)
            if strendswith(fileList(i).name,'meta.txt')&&...
                strcmp(fileList(i).name(1:end-9),fileList(pos).name(1:end-5))
                metaName=fileList(i).name;
                break;
            end
        end
    end
    if isempty(metaName)
        sprintf('Couldn''t find metadata for %s',fileList(pos).name);
        return
    end
    fid = fopen(fullfile(workingDir,metaName));
    tline='';
    while ischar(tline)
        if strcmp(tline,'#duration');
            break;
        end
        tline = fgetl(fid);
    end
    if ~isempty(tline)
        duration=str2double(fgetl(fid));
    end
    fclose(fid);
end