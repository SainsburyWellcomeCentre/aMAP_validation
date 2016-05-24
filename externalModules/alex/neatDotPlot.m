function neatDotPlot(data, categoryLabels, varargin)
% pass in data in a cellarray to plot neatly
%
%
% Possible options:
%
% 'verbose' - gives information as the points are jiggled in x 
% 'truncateOutliers' - truncates oulier data points, plotting as an 'x' to
% indicate non-true values
% 'stdMultipleForTruncation' - sets the number of standard deviations
% outside which a point is considered to be an outlier
% 'proximityCutoff' - how close a data point can get to another
% 'markerSize'

%% Parameters

p=inputParser;
p.addOptional('proximityCutoff', 0.013);
p.addOptional('stdMultipleForTruncation', 3);
p.addOptional('truncateOutliers', 0);
p.addOptional('verbose', 0);
p.addOptional('markerSize', 10);
p.addOptional('figurePosition', get(0, 'defaultfigureposition'))
p.addOptional('color', []);
p.addOptional('maxWidth',0.8);
%p.addOptional('noSpread', 0);
parse(p, varargin{:});
q=p.Results;


%% Input parsing

figure('Position', q.figurePosition);hold on

%% Truncate outliers, if requested. Set markers to show regular or truncated data
markers=cell(size(data));
for ii=1:length(data)
    y=sort(data{ii});
    y=y(~isnan(y));
    markers{ii}=zeros(size(y));
    if q.truncateOutliers
        yStd=std(y);
        yMean=mean(y);
        lowerThresh=yMean-q.stdMultipleForTruncation*yStd;
        upperThresh=yMean+q.stdMultipleForTruncation*yStd;
        
        markers{ii}(y<lowerThresh)=1;
        markers{ii}(y>upperThresh)=1;
        
        
        y(y<lowerThresh)=lowerThresh;
        y(y>upperThresh)=upperThresh;
    end
    data{ii}=y;
end
%% work out what our xlim and ylim will be
nGroups=numel(data);
allData=[data{:}];
ylim([min(allData) max(allData)]);
xlim([0 nGroups+1])

%% Do the plot

directionFun=@plus;

for ii=1:length(data)
    %% Get data
    y=data{ii};
    x=ii*ones(size(y));
    
    
    %% Check it doesn't overlap; sort it if it does
    for jj=2:numel(y);
        if eucDistToAnyLowerPoint(x, y, jj, xlim, ylim)<q.proximityCutoff
            if isequal(directionFun,@plus)
                directionFun=@minus;
            else
                directionFun=@plus;
            end
                
            while eucDistToAnyLowerPoint(x, y, jj, xlim, ylim)<q.proximityCutoff
                if q.verbose,fprintf('%u, %3.3f\n', jj, x(jj)),end
                
                x(jj)=directionFun(x(jj), q.proximityCutoff/10);
            end
        end
    end
    %% Show mean
    if range(x)==0
        meanLinePlotX=x(1)+[-0.1 0.1];
    else
        medX = mean(x);
        minX = max(min(x),medX-q.maxWidth/2);
        maxX = min(max(x),medX+q.maxWidth/2);
        meanLinePlotX=[minX maxX];
    end
    line(meanLinePlotX, [1 1]*median(y), 'Color', [1 0 0], 'LineWidth', 2)
    %% Plot regular data
    idx=markers{ii}==0;
    if isempty(q.color)
        clArr = [0 0 0];
    else
        clArr = q.color{ii};
    end
    h=scatter(x(idx), y(idx), q.markerSize, clArr, 'filled', 'd');
    
    %% Plot truncated datapoints
    idx=markers{ii}==1;
    if ~isempty(idx)
        scatter(x(idx), y(idx), [], [0 0 0], 'x');
    end

end

%% Sort out axes and labels

set(gca, 'XTick', 1:nGroups)
if nargin>1&&~isempty(categoryLabels)
    set(gca, 'XTickLabel', categoryLabels)
end

% zoom out a little
ylim(gca, ylim(gca)+[-0.05 0.05]*range(ylim(gca)));


end

function d=eucDistToAnyLowerPoint(x, y, idx, xLim, yLim)
%% Returns the minimum distance to any point lower than the index point

xDist=(x(idx)-x(1:idx-1))./range(xLim);
yDist=(y(idx)-y(1:idx-1))./range(yLim);
d=min(sqrt(xDist.^2+yDist.^2));
end