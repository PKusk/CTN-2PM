function ax = plotMeanAndSEM(traces, frq, color,linewidth,linestyle)

if ~exist('color','var')
      color = 'black';
end

if ~exist('linewidth','var')
      linewidth = 1;
end 

if ~exist('linestyle','var')
      linestyle = '-';
end 

AvgTrace = mean(traces,2);
StdTrace = std(traces,[],2)/sqrt(size(traces, 2)); % SEM
stdP = AvgTrace+StdTrace;
stdM = AvgTrace-StdTrace;
stdP(isnan(stdP)) = 0;
stdM(isnan(stdM)) = 0;

filling = fill([1:length(AvgTrace) fliplr(1:length(AvgTrace))]/frq ,[stdP' fliplr(stdM')],color, 'EdgeColor','none');
alpha(filling,0.3)
set(get(get(filling,'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
hold on
ax = plot([1:length(AvgTrace)]/frq, AvgTrace,'color',color,'linewidth',linewidth,'linestyle',linestyle);
end

