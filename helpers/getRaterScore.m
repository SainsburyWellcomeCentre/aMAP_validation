function [ scores ] = getRaterScore( logStr, brainRegionComb )
%GETRATERSCORE Extracts the rater scores from the log string from the
%STAPLE run (with users added at the end)
    
    users = logStr{end};
    users = strsplit(users,';');
    users = cellfun(@(x) strsplit(x,':'), users, 'UniformOutput', false);


    sectIdx=cellfun(@(x) strcmp(x,'*******************************'), logStr);
    sectIdx=find(sectIdx);
    relevantLog = logStr(sectIdx(end)+1:end);
    
    k=1;
    for i=2:numel(relevantLog)-1
        if (strcmp(relevantLog{i-1}, '[') && strcmp(relevantLog{i+1}, ']'))
            scores(k)=processSection(users, relevantLog, i);
            scores(k).brainRegionComb = brainRegionComb;
            k=k+1;
        end
        i=i+1;        
    end
end

function resVal=processSection(userList, strList, i)
    raterIdx=strList{i};
    searchStr = ['[',raterIdx,']='];
    dataStart = cellfun(@(x) strcmp(x,searchStr), strList);
    dataStart=find(dataStart);
    dataStart(dataStart<i)=[];
    dataStart = dataStart(1)+1;
    
    resVal=struct('q', str2double(strList{dataStart}),'p', str2double(strList{dataStart+3}));
    userData = userList{str2double(raterIdx)};
    resVal.user=userData{1};
    resVal.idx=str2double(userData{2});
    resVal.brainRegionComb = '';
end

