function [cm_data]=cmap_bluered(m)
% Custom blue-white-red diverging colormap.

cm = diverging_map(0:0.001:1,[0.230, 0.299, 0.754],[0.706, 0.016, 0.150]);
if nargin < 1
    cm_data = cm;
else
    hsv=rgb2hsv(cm);
    hsv(144:end,1)=hsv(144:end,1)+1; % hardcoded
    cm_data=interp1(linspace(0,1,size(cm,1)),hsv,linspace(0,1,m));
    cm_data(cm_data(:,1)>1,1)=cm_data(cm_data(:,1)>1,1)-1;
    cm_data=hsv2rgb(cm_data);
  
end
end