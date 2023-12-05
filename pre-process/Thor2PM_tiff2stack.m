function Thor2PM_tiff2stack(Experiment_Path,Save_Path)
%2021.03.02 - P.Kusk - Thor2PM_tiff2stack(Experiment_Path,Save_Path)
% An attempt at making a function that easily converts the folders of .tif
% files into a tiff stack pr. channel and convert the xml metadata into an
% xlsx tabular formatted file.
%2023.02.02 - P.Kusk - Updated this function to allow output of the
%"Experiment Notes" from thorlabs XML metadata to xlsx tabular format.
% 2023.04.25 - P.Kusk - added line 41-44 to deal with alternate file naming
% on the thorlabs left side 2pm rig.

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
                if isempty(Image_No)
                    Image_No = str2double(extractBetween(active_ChA_dir(uu).name,'_001_001_001_','.tif')); % added this to work with different nomenclature on left side 2p rig.
                else
                end
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
        % Saving Channel A
        ChA_save_name = [Save_Path '\' SubFolders(ii).name '_ChanA.tif'];
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
        
        ChB_save_name = [Save_Path '\' SubFolders(ii).name '_ChanB.tif'];
        saveastiff(ChB_stack,ChB_save_name);
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
        ExperimentNotes = meta_data.ExperimentNotes;
        
        Meta_Table = table(FileName,FileDateTime,ImageHeight,ImageWidth,BitDepth, ...
            ImageHeightUM,ImageWidthUM,FrameRate,AvgNumber,PockelsPower,ChannelA_Gain,ChannelB_Gain,PowerRegulator, ...
            ScanMode,PixelDwellTime,IsTStack,TFrameCount,IsZStack,ZStartPos,ZStepSizeUM,ZSteps,ExperimentNotes);
        
        Meta_save_name = [Save_Path '\' SubFolders(ii).name '_MetaData.xlsx'];
        writetable(Meta_Table,Meta_save_name)
    else
        fprintf('No xml Meta Data could be found! \n')
    end
end
end