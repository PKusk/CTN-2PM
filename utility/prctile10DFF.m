function dff_trace = prctile10DFF(trace,bin)
% 2022.05.10 - P.Kusk
% 

time_bins = 1:bin:length(trace);
time_bins = [time_bins length(trace)+1];

F0 = []; dff_trace = [];
for ii = 1:length(time_bins)-1
    trace_segment = trace(time_bins(ii):time_bins(ii+1)-1);
    tenth_prct = prctile(trace_segment,10);
    F0 = [F0 tenth_prct];
    dff_trace_segment = ((trace_segment-tenth_prct)./tenth_prct)*100;
    dff_trace = [dff_trace dff_trace_segment'];
end

%F0_interp = interp1(time_bins(1:length(time_bins)-1),F0,1:length(trace));

% figure,
% subplot(2,1,1)
% plot(trace,'k')
% hold on
% plot(time_bins(2:end),F0,'--r','LineWidth',1)
% subplot(2,1,2)
% plot(dff_trace,'k')


end