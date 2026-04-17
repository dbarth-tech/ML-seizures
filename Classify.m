 
% Use updated filenames files to locate EEG records, perform multicategory
% detection, and write structured array with detections for each 30 minute file
% updated to handle missing files labeled 'null' as timeline placeholders
    clc
    clear all;
    
% Cat: 1=noise, 2=SWDs (r), 3=ESs (g), 4=Spikelets
% Cat: 1 = noise, 2=SWDs (r), 3=spikes (g))

%     Experiment = 'Other';
    Experiment = 'Mvac';
%    Experiment = 'Sean';
%     Experiment = 'Jeremy';

    [BasePath, RatNames, Chans] = GetRatNames(Experiment);
    Nrats = size(RatNames,2);  

    Ncat=4;
%     Ncat=5;

%     Fs=500; CutLo=0.1; CutHi=100; Order=1; Notch=1;
    Fs=500; CutLo=1; CutHi=40; Order=1; Notch=1; %these are exactly the same as used during training
    fb = cwtfilterbank('SignalLength',5000,'VoicesPerOctave',12); %create filterbank in advance for faster repeated application
    allImages = zeros(224,224,3,180); %make this once to save a bit of time
    allImages = uint8(allImages);

    DeletOldDetectionFiles = 1; %use this rarely in case we want to change the training and redo
    if(DeletOldDetectionFiles>0)
        disp(['Are you sure you want DeletOldDetectionFiles set?']);
        pause
    end
%     for irat = 1:Nrats
    for irat =28:28
        RatName = char(RatNames(:,irat))
        DetectorPath=[BasePath, RatName, '\'];
        Channel = Chans(1,irat);
%         Channel = 3
        
        load([DetectorPath 'AllFileNames_EEG'],'FileNames');
        load([DetectorPath 'GNmodCat',num2str(Ncat)],'trainedGN');
        nEEGFiles = size(FileNames,2);        
        if(nEEGFiles>0)
            for ifile=1:nEEGFiles %here is where we process each file for seizures
                EEGFileName = deblank(char(FileNames(1,ifile)));
                if(strcmp(EEGFileName,'null'));continue;end %just place
%                 holder for missing file at this date/time so skip           
                [isfile,isfolder,fbytes,fdate,fdatenum,fpath,fname,fext] = GetFileInfo(EEGFileName);
                DETFileFolder = [fpath(1:strfind(fpath,'\EEG')) 'DET\' RatName '\'];
                % classifications for each 30 min block are put in DET folder is same folder as EEG as a .mat file with EEG filename
                if ~exist(DETFileFolder,'dir');mkdir(DETFileFolder);end %if DET folder does not exist, create it
                cd (DETFileFolder);
                DETFileName=[fname '.mat'];
                if exist (DETFileName, 'file')
                    if(DeletOldDetectionFiles)
                        disp('Deleting existent file.')
                        DETFileName
                        delete(DETFileName)
                    end
                end
                if exist(DETFileName, 'file')
                    continue
                else
%                     if ~exist(DETFileFolder,'dir');mkdir(DETFileFolder);end %if DET folder does not exist, create it
                    disp(['Writing DET for ',DETFileFolder, DETFileName])
                    tic
                    [LongTrace,ReformData,ReformDataUnfiltered,nlines] = ReadFilterRasterizeLongTraceRaw(EEGFileName,Channel,Fs,CutLo,CutHi,Order,Notch);
%                     [DETs] = ClassifyMultiCatArray(ReformDataUnfiltered,fb,trainedGN,allImages);
                    [DETs] = ClassifyMultiCatArray(ReformData,fb,trainedGN,allImages); % We now analize ReformData, which is filtered exactly the same as training EEG 
                    elapsed=toc
                    nDETs = size(DETs,2);
                    save (DETFileName, 'DETs')
                    percentdone=ifile/nEEGFiles*100;
                    disp(['elepsed time = ',num2str(elapsed),' nDETs = ',num2str(nDETs),'  Percent done = ',num2str(percentdone)])
                end
            end               
        end
    end
% end

