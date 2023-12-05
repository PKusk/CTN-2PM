function data = read_Thor_xml_v2(fname)
% Usage: data = read_Thor_xml(fname)
% Given file "fname" created by a ThorLabs microscope, read_Thor_xml reads
% the file and returns a struct array "data" containing metadata about the
% recording, including image width, image height, frame count, frame rate,
% bit depth, and spatial resolution. 

% Written 1 December 2018 by Rebeca Toro. 
% Updated 3 October 2019 by Doug Kelley for niceties. Also renamed
% read_Thor_xml.m. 
% Updated 2 February 2021 by Peter Kusk for errors and added output.
% Updated 2 March 2021 by Peter Kusk for outputting scan mode and Z-stack
% information
% Updated Feb 2023 by Peter Kusk to allow output of "Experiment Notes"
if nargin<1
    error(['Usage: data = ' mfilename '(fname)'])
end

s=xml2struct(fname); % use function from file exchange 

data=struct;
data.AllocatedFrames=str2double(s.ThorImageExperiment.Streaming.Attributes.frames)*str2double(s.ThorImageExperiment.Streaming.Attributes.enable);
data.FrameRate=str2double(s.ThorImageExperiment.LSM.Attributes.frameRate);
data.umperpix=str2double(s.ThorImageExperiment.LSM.Attributes.pixelSizeUM);
data.ImageBitDepthReal=str2double(s.ThorImageExperiment.LSM.Attributes.inputRange1);
data.ImageHeight=str2double(s.ThorImageExperiment.LSM.Attributes.pixelY);
data.ImageWidth= str2double(s.ThorImageExperiment.LSM.Attributes.pixelX);
data.ImageHeightUM=str2double(s.ThorImageExperiment.LSM.Attributes.heightUM);
data.ImageWidthUM= str2double(s.ThorImageExperiment.LSM.Attributes.widthUM);
%data.BitsPerPixel=str2double(s.ThorImageExperiment.Camera.Attributes.bitsPerPixel);
%doesn't work with the nedergaard 2pm for some reason.
data.NumCh=numel(s.ThorImageExperiment.Wavelengths.Wavelength);
%Peter Add-on
data.AverageNum=str2double(s.ThorImageExperiment.LSM.Attributes.averageNum)*str2double(s.ThorImageExperiment.LSM.Attributes.averageMode);
data.ExperimentDate= s.ThorImageExperiment.Date.Attributes.date;
data.ExperimentName= s.ThorImageExperiment.Name.Attributes.name;
data.PixelDwellTime= str2double(s.ThorImageExperiment.LSM.Attributes.dwellTime);
data.ChBGain=str2double(s.ThorImageExperiment.PMT.Attributes.enableB)*str2double(s.ThorImageExperiment.PMT.Attributes.gainB);
data.ChAGain=str2double(s.ThorImageExperiment.PMT.Attributes.enableA)*str2double(s.ThorImageExperiment.PMT.Attributes.gainA);
data.PockelPowerStart= str2double(s.ThorImageExperiment.Pockels{1}.Attributes.start);
data.PowerRegStart=str2double(s.ThorImageExperiment.PowerRegulator.Attributes.start);
data.FrameRateReal = str2double(s.ThorImageExperiment.LSM.Attributes.frameRate)/(str2double(s.ThorImageExperiment.LSM.Attributes.averageNum)*str2double(s.ThorImageExperiment.LSM.Attributes.averageMode));
data.ExperimentNotes = string(s.ThorImageExperiment.ExperimentNotes.Attributes.text);

data.ZStartPos = str2double(s.ThorImageExperiment.ZStage.Attributes.startPos);
data.ZStepSizeUM = str2double(s.ThorImageExperiment.ZStage.Attributes.stepSizeUM);
data.ZSteps = str2double(s.ThorImageExperiment.ZStage.Attributes.steps);

% Determining scan mode
if str2double(s.ThorImageExperiment.LSM.Attributes.scanMode) == 0
    data.ScanMode = 'TwoWay';
    data.TwoWayAligment = s.ThorImageExperiment.LSM.Attributes.twoWayAlignment;
else
    data.ScanMode = 'OneWay';
end
% Determining if this is a Z-stack
if str2double(s.ThorImageExperiment.ZStage.Attributes.steps)>1
    data.ZStack = 1;
else
    data.ZStack = 0;
end
% Determining if this is a T-Stack
if str2double(s.ThorImageExperiment.Streaming.Attributes.enable)==1
    data.TStack = 1;
else
    data.TStack = 0;
end
end
