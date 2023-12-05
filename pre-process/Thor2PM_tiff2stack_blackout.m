function Thor2PM_tiff2stack_blackout(Experiment_Path,Save_Path)
%2021.06.02 - P.Kusk - Thor2PM_tiff2stack(Experiment_Path,Save_Path)
% An attempt at making a function that easily converts the folders of .tif
% files into a tiff stack pr. channel and convert the xml metadata into an
% xlsx tabular formatted file. This functions also automatically cuts out black frames that originate
% from PMT shut-off during optogenetic experiments.

% Identifying Subfolders in given directory
Experiment_Dir = dir(Experiment_Path);
DirFlags = [Experiment_Dir.isdir]; % id only directories
SubFolders = Experiment_Dir(DirFlags); % index subfolders
SubFolders = SubFolders(~ismember({SubFolders(:).name},{'.','..'})); % remove the '.' and '..' from list


for ii=1:length(SubFolders)
    active_subfolder = [SubFolders(ii).folder '\' SubFolders(ii).name];
    
    % In case no save directory is supplied, just save where you found sub-folder
    if nargin < 2
        Save_Path = SubFolders(ii).folder;
    end
    
    if isempty(Save_Path)
        Save_Path = SubFolders(ii).folder;
    end
    % Locating Channel A .tiff files and reading them to multipage file
    active_ChA_dir = dir([active_subfolder '\' 'ChanA_0*.tif']); %
    if isempty(active_ChA_dir)
        fprintf('This file has no Channel A \n')
    else
        % 2022.03.10 - Adding a "mal-sorting" contigency if imaging has more
        % than 10000 frames so that the pages in image are ordered correctly.
        % currently only works with time-stacks but can be expanded to Z-stacks
        % (though unlikely) if needed using datetime argument.
        if length(active_ChA_dir)>9999
            Image_Order = [];  % collecting the correct image number by appendix name iterative
            for uu=1:length(active_ChA_dir)
                Image_No = str2double(extractBetween(active_ChA_dir(uu).name,'_0001_0001_0001_','.tif'));
                Image_Order = cat(1,Image_Order,Image_No);
            end
            [~,Order_idx] = sort(Image_Order); % obtaining sorting index
            active_ChA_dir = active_ChA_dir(Order_idx); % applying sorting index on directory names for correct order.
        end
        ChA_info = imfinfo([active_ChA_dir(1).folder '\' active_ChA_dir(1).name]);
        ImSizeX = ChA_info.Width;
        ImSizeY = ChA_info.Height;
        ImSizeT = length(active_ChA_dir);
        ChA_stack = zeros(ImSizeX,ImSizeY,ImSizeT,'uint16'); % Pre-allocating memory for image stack, extent this if multiple colors or Z-planes.
        for jj = 1:length(active_ChA_dir)
            ChA_page = loadtiff([active_ChA_dir(jj).folder '\' active_ChA_dir(jj).name]);
            ChA_stack(:,:,jj) = ChA_page;
            fprintf(['Reading Channel A page ' num2str(jj) ' of ' num2str(ImSizeT) '\n'])
        end
        
        prechop_zscore_ChA_trace = detrend(zscore(squeeze(mean(ChA_stack,[1 2])))); % Extracting the mean fluorescence
        threshold = median([median(prechop_zscore_ChA_trace) min(prechop_zscore_ChA_trace)]); % Setting an automatic threshold as the median between the median and minimum value.
        
        %Identifying the amount and location of black frames.
        BinarizedVal = prechop_zscore_ChA_trace < threshold; % Detecting values below threshold.
        DiffBinarizedIntensityVal = diff(BinarizedVal); % Identifying wether the threshold cross is positive or negative.
        RisingEdge = (DiffBinarizedIntensityVal==1); % Positive value is found as the pulse rises.
        FallingEdge = (DiffBinarizedIntensityVal==-1); % Negative value is found as the pulse falls.
        OnIdx = find(RisingEdge ==1); % The index of these values are located
        OffIdx = find(FallingEdge ==1);
        
        % Introducing contingency that the no. "off" pulse has to be longer
        % than 2 frames to be cut out to avoid that some noise will cause
        % the stack to be chopped werdly.
        for jj = 1:length(OnIdx)
            if OffIdx(jj)-OnIdx(jj) < 2
                OnIdx(jj) = [];
                OffIdx(jj) = [];
            end
        end
        
        % Iterating through pairs of on/off indices and chopping it out of
        % the stack and subtracting the now shortening of the length from
        % the next pair of on/off indices in an iterative loop.
        postchop_zscore_ChA_trace = prechop_zscore_ChA_trace;
        chop_offset = 0;
        new_OnIdx = []; new_OffIdx = [];
        for jj = 1:length(OnIdx)
            active_OnIdx = OnIdx(jj)-chop_offset;
            active_OffIdx = OffIdx(jj)-chop_offset;
            postchop_zscore_ChA_trace(active_OnIdx-1:active_OffIdx+1) = [];
            ChA_stack(:,:,active_OnIdx-1:active_OffIdx+1) = [];
            chop_offset = chop_offset + length(active_OnIdx-1:active_OffIdx+1);
            new_OnIdx = cat(1,new_OnIdx,active_OnIdx);
            new_OffIdx = cat(1,new_OffIdx,active_OffIdx);
        end
        
        f1b = figure('Position',[1 41 1920 963]);
        subplot(2,1,1)
        plot(prechop_zscore_ChA_trace,'color','k')
        hold on
        yline(threshold,'--b','Threshold')
        for jj = 1:length(OnIdx)
            scatter(OnIdx(jj)-1,threshold,[15],'r','filled')
            scatter(OffIdx(jj)+1,threshold,[15],'r','filled')
        end
        title('Original Mean Stack Trace'); box off
        xlabel('Frames'); ylabel('zscore')
        subplot(2,1,2)
        plot(postchop_zscore_ChA_trace,'color','k')
        pulse_counter_ChA = {};
        for jj = 1:length(new_OnIdx)
            xline(new_OnIdx(jj),'r',['Pulse #' num2str(jj)])
            pulse_counter_ChA{jj} = ['Pulse #' num2str(jj)];
        end
        title('Post-Chop Stack Trace'); box off
        xlabel('Frames'); ylabel('zscore')
        sgtitle([SubFolders(ii).name ' ChA'],'Interpreter','none')
        saveas(f1a,[Save_Path '\' SubFolders(ii).name '_ChanA_BlackOut.png']);
        close gcf
        
        % Adding Sheet to excel doc with pulse indices and which frames have been cut
        Meta_save_name = [Save_Path '\' SubFolders(ii).name '_MetaData.xlsx'];
        chop_table = table(pulse_counter_ChA',new_OnIdx,OnIdx,OffIdx,'VariableNames',{'Chop_Frames_ID','Post_Chop_Idx','Pre_Chop_From_Idx','Pre_Chop_To_Idx'});
        writetable(chop_table,Meta_save_name,'Sheet','ChA_Chop_Data')
        overall_length_table = table(ImSizeT,size(ChA_stack,3),ImSizeT-size(ChA_stack,3),'VariableNames',{'Original_Length','Chopped_Length','No_of_removed_frames'});
        writetable(overall_length_table,Meta_save_name,'Sheet','ChA_Chop_Data','Range','E:G')
        
        % Saving Channel A
        ChA_save_name = [Save_Path '\' SubFolders(ii).name '_ChanA_BlackOut.tif'];
        saveastiff(ChA_stack,ChA_save_name);
        % Attempt to save some RAM before Read/writing channel B
        clear ChA_stack
    end
    
    
    
    % Repeat all of the above for Channel B.
    active_ChB_dir = dir([active_subfolder '\' 'ChanB_0*.tif']);
    if isempty(active_ChB_dir)
        fprintf('This file has no Channel B \n')
    else
        % 2022.03.10 - Adding a "mal-sorting" contigency if imaging has more
        % than 10000 frames so that the pages in image are ordered correctly.
        % currently only works with time-stacks but can be expanded to Z-stacks
        % (though unlikely) if needed using datetime argument.
        if length(active_ChB_dir)>9999
            Image_Order = [];  % collecting the correct image number by appendix name iterative
            for uu=1:length(active_ChB_dir)
                Image_No = str2double(extractBetween(active_ChB_dir(uu).name,'_0001_0001_0001_','.tif'));
                Image_Order = cat(1,Image_Order,Image_No);
            end
            [~,Order_idx] = sort(Image_Order); % obtaining sorting index
            active_ChB_dir = active_ChB_dir(Order_idx); % applying sorting index on directory names for correct order.
        end
        ChB_info = imfinfo([active_ChB_dir(1).folder '\' active_ChB_dir(1).name]);
        ImSizeX = ChB_info.Width;
        ImSizeY = ChB_info.Height;
        ImSizeT = length(active_ChB_dir);
        ChB_stack = zeros(ImSizeX,ImSizeY,ImSizeT,'uint16'); % Pre-allocating memory for image stack, extent this if multiple colors or Z-planes.
        for jj = 1:length(active_ChB_dir)
            ChB_page = loadtiff([active_ChB_dir(jj).folder '\' active_ChB_dir(jj).name]);
            ChB_stack(:,:,jj) = ChB_page;
            fprintf(['Reading Channel B page ' num2str(jj) ' of ' num2str(ImSizeT) '\n'])
        end
        
        prechop_zscore_ChB_trace = detrend(zscore(squeeze(mean(ChB_stack,[1 2])))); % Extracting the mean fluorescence
        threshold = median([median(prechop_zscore_ChB_trace) min(prechop_zscore_ChB_trace)]); % Setting an automatic threshold as the median between the median and minimum value.
        
        %Identifying the amount and location of black frames.
        BinarizedVal = prechop_zscore_ChB_trace < threshold; % Detecting values below threshold.
        DiffBinarizedIntensityVal = diff(BinarizedVal); % Identifying wether the threshold cross is positive or negative.
        RisingEdge = (DiffBinarizedIntensityVal==1); % Positive value is found as the pulse rises.
        FallingEdge = (DiffBinarizedIntensityVal==-1); % Negative value is found as the pulse falls.
        OnIdx = find(RisingEdge ==1); % The index of these values are located
        OffIdx = find(FallingEdge ==1);
        
        % Introducing contingency that the no. "off" pulse has to be longer
        % than 2 frames to be cut out to avoid that some noise will cause
        % the stack to be chopped werdly.
        for jj = 1:length(OnIdx)
            if OffIdx(jj)-OnIdx(jj) < 2
                OnIdx(jj) = [];
                OffIdx(jj) = [];
            end
        end
        
        % Iterating through pairs of on/off indices and chopping it out of
        % the stack and subtracting the now shortening of the length from
        % the next pair of on/off indices in an iterative loop.
        postchop_zscore_ChB_trace = prechop_zscore_ChB_trace;
        chop_offset = 0;
        new_OnIdx = []; new_OffIdx = [];
        for jj = 1:length(OnIdx)
            active_OnIdx = OnIdx(jj)-chop_offset;
            active_OffIdx = OffIdx(jj)-chop_offset;
            postchop_zscore_ChB_trace(active_OnIdx-1:active_OffIdx+1) = [];
            ChB_stack(:,:,active_OnIdx-1:active_OffIdx+1) = [];
            chop_offset = chop_offset + length(active_OnIdx-1:active_OffIdx+1);
            new_OnIdx = cat(1,new_OnIdx,active_OnIdx);
            new_OffIdx = cat(1,new_OffIdx,active_OffIdx);
        end
        
        f1b = figure('Position',[1 41 1920 963]);
        subplot(2,1,1)
        plot(prechop_zscore_ChB_trace,'color','k')
        hold on
        yline(threshold,'--b','Threshold')
        for jj = 1:length(OnIdx)
            scatter(OnIdx(jj)-1,threshold,[15],'r','filled')
            scatter(OffIdx(jj)+1,threshold,[15],'r','filled')
        end
        title('Original Mean Stack Trace'); box off
        xlabel('Frames'); ylabel('zscore')
        subplot(2,1,2)
        plot(postchop_zscore_ChB_trace,'color','k')
        pulse_counter_ChB = {};
        for jj = 1:length(new_OnIdx)
            xline(new_OnIdx(jj),'r',['Pulse #' num2str(jj)])
            pulse_counter_ChB{jj} = ['Pulse #' num2str(jj)];
        end
        title('Post-Chop Stack Trace'); box off
        xlabel('Frames'); ylabel('zscore')
        sgtitle([SubFolders(ii).name ' ChB'], 'Interpreter','none')
        saveas(f1b,[Save_Path '\' SubFolders(ii).name '_ChanB_BlackOut.png']);
        close gcf
        
        ChB_save_name = [Save_Path '\' SubFolders(ii).name '_ChanB_BlackOut.tif'];
        saveastiff(ChB_stack,ChB_save_name);
        
        % Adding Sheet to excel doc with pulse indices and which frames have been cut
        Meta_save_name = [Save_Path '\' SubFolders(ii).name '_MetaData.xlsx'];
        chop_table = table(pulse_counter_ChB',new_OnIdx,OnIdx,OffIdx,'VariableNames',{'Chop_Frames_ID','Post_Chop_Idx','Pre_Chop_From_Idx','Pre_Chop_To_Idx'});
        writetable(chop_table,Meta_save_name,'Sheet','ChB_Chop_Data')
        overall_length_table = table(ImSizeT,size(ChB_stack,3),ImSizeT-size(ChB_stack,3),'VariableNames',{'Original_Length','Chopped_Length','No_of_removed_frames'});
        writetable(overall_length_table,Meta_save_name,'Sheet','ChB_Chop_Data','Range','E:G')
    end
    
    %Extracting Relevant MetaData and writing it to an .xlsx file
    active_meta_dir = [active_subfolder '\' 'Experiment.xml'];
    if isfile(active_meta_dir)
        meta_data = read_Thor_xml_v2(active_meta_dir);
        FileName = {meta_data.ExperimentName};
        FileDateTime = {datestr(datetime(meta_data.ExperimentDate))};
        ImageHeight = meta_data.ImageHeight;
        ImageWidth = meta_data.ImageWidth;
        ImageHeightUM = meta_data.ImageHeightUM;
        ImageWidthUM = meta_data.ImageWidthUM;
        BitDepth = meta_data.ImageBitDepthReal;
        PockelsPower = meta_data.PockelPowerStart;
        ChannelA_Gain = meta_data.ChAGain;
        ChannelB_Gain = meta_data.ChBGain;
        FrameRate = meta_data.FrameRateReal;
        PowerRegulator = meta_data.PowerRegStart;
        AvgNumber = meta_data.AverageNum;
        ScanMode = {meta_data.ScanMode};
        PixelDwellTime = meta_data.PixelDwellTime;
        IsTStack = meta_data.TStack;
        TFrameCount = meta_data.AllocatedFrames;
        IsZStack = meta_data.ZStack;
        ZStartPos = meta_data.ZStartPos;
        ZStepSizeUM = meta_data.ZStepSizeUM;
        ZSteps = meta_data.ZSteps;
        
        Meta_Table = table(FileName,FileDateTime,ImageHeight,ImageWidth,BitDepth, ...
            ImageHeightUM,ImageWidthUM,FrameRate,AvgNumber,PockelsPower,ChannelA_Gain,ChannelB_Gain,PowerRegulator, ...
            ScanMode,PixelDwellTime,IsTStack,TFrameCount,IsZStack,ZStartPos,ZStepSizeUM,ZSteps);
        
        Meta_save_name = [Save_Path '\' SubFolders(ii).name '_MetaData.xlsx'];
        writetable(Meta_Table,Meta_save_name,'Sheet','2PM_MetaData')
    else
        fprintf('No xml Meta Data could be found! \n')
    end
end
end