function [ splitData, groups ] = splitGroups(dataVect, groupVect)
%SPLITGRPS Splits data according to the grouping variable
%   Expects a data vector and a grouping vector of the same size
%   and gives back cell arrays of the data split by groups and a
%   categorical array of the corresponding groups.
groupVect = categorical(groupVect);
groups = unique(groupVect);
splitData=cell(numel(groups,1));
for i =1:numel(groups)
splitData{i}=dataVect(groupVect==groups(i));
end

