function [dff_traces] = medianDFF(traces)
% 2022.05.09 - P.Kusk 
% Just a function to automatically output DF/F signals in percentage from median, from array of trace
% performing the standard ((F-F0)/F0)*100 where F0 is the median of the
% global signal.
median_f0 = median(traces,1);
dff_traces = ((traces-median_f0)./median_f0)*100;
end