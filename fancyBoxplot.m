% fancyBoxplot.m

close all
clear all

%% diameter data. 11/7/14

awake = [20.0
14.6
11.3
23.6
12.0
24.1
18.0];

isoflurane = [27.4
15.3
13.1
25.2
15.0
24.5
22.0];

%% plot

diameter = [awake;isoflurane];

awakeGroup = cell(size(awake));
for i = 1:numel(awakeGroup)
    awakeGroup{i} = 'awake';
end

isofluraneGroup = cell(size(isoflurane));
for i = 1:numel(isofluraneGroup)
    isofluraneGroup{i} = 'isoflurane';
end

groups = [awakeGroup;isofluraneGroup];

% create a boxplot
figure
subplot(3,4,1)
hold on
% plot raw data on top of boxplot
plot(1*ones(size(awake)),awake,'o','MarkerSize',4,'MarkerFaceColor','k','MarkerEdgeColor','none')
% plot(2*ones(size(isoflurane)),isoflurane,'o','MarkerSize',4,'MarkerFaceColor','none','MarkerEdgeColor','c')
plot(2*ones(size(isoflurane)),isoflurane,'o','MarkerSize',4,'MarkerFaceColor','k','MarkerEdgeColor','none')
% plot boxplot
boxplot(diameter,groups,'colors','kk','symbol','k+','width',0.4);
title('diameters 11/7/14')
ylabel('diameter (µm)')
% ylim([0 60])

plot(1,mean(awake),'kx','MarkerSize',6)
plot(2,mean(isoflurane),'kx','MarkerSize',6)

hold off
%% stats

% alpha = 0.05;
% [p,anovaTable,stats] = anova1(diameter, groups);
% [c,meanAndStdErr,handle,groupNames] = multcompare(stats,'display','on','alpha',alpha,'ctype','tukey-kramer');
% [groupNames num2cell(meanAndStdErr)]