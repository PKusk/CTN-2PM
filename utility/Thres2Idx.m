function [PulseIdx, OnIdx, OffIdx, PulseDurations, PulseIntervals] = Thres2Idx(Trace,Threshold)
% 2020.08.17 P.Kusk
%[PulseIdx, OnIdx, OffIdx, PulseDurations, PulseIntervals] = Thres2Idx(Trace,Threshold)
% Part of the peristimavg script made into function. Enter Peak based trace
% data and a threshold, returns rising edge index.
%2021.02.16 P.Kusk
% Modified the function to also be able to output entire pulse idx, rise
% and fall idx, pulse durations and pulse intervals (from on to on). also
% added an auto-threshold input that is defined as the median between max
% and mean of the signal.
    %active_trace = abf_timetbl.("2P_Trigger");
    if nargin < 2
    % AutoTresh is good for clear peaks and is defined as the median between the mean and max of the given signal.
    Threshold = median([mean(abs(Trace)) max(abs(Trace))]);
    %Threshold = median([median(abs(Trace)) max(abs(Trace))])*0.8; %2021.12.02
    end
    % Binarizing values above threshold and locating signal transitions by diff function (rising signal = +1 , decay signal = -1)
    BinarizedVal = abs(Trace) > Threshold;
    DiffBinarizedIntensityVal = diff(BinarizedVal);
    % Selecting only rising signals
    RisingEdge = (DiffBinarizedIntensityVal==1);
    FallingEdge = (DiffBinarizedIntensityVal==-1);
    % Locating the index of signals
    PulseIdx = find(BinarizedVal ==1);
    OnIdx = find(RisingEdge ==1);
    OffIdx = find(FallingEdge ==1);
    if length(OffIdx)> length(OnIdx)
    PulseDurations = OffIdx(2:end)-OnIdx(1:length(OffIdx(2:end)));
    else
    PulseDurations = OffIdx-OnIdx(1:length(OffIdx));
    end
    PulseIntervals = OnIdx(2:end)-OnIdx(1:end-1);
end