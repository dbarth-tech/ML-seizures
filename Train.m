% Train Net for Google net DL reccognition
% Inludes more than 2 (i.e. signal versus noise) categories
clear all;
clc %clear the command window; 
warning off;
% 
RatName = 'B28';DetectorPath = GetCurrentPath(RatName);
DetectorPath
BasePath = extractBefore(DetectorPath,RatName); % this is where the signal/noise files should be and where model is written 


Fs=500;SignalLength = Fs*10;
cutlo=1;cuthi=40;order=1;notch=1;
fb = cwtfilterbank('SignalLength',SignalLength,'VoicesPerOctave',12); %create filterbank in advance for faster repeated application

% Ncat = 5;% 1=noise, 2=SRS, 3=SWD, 4=Spikes, 5=Humps
% Catnames = {'noise','SRS','SWD','Spikes','Humps'};
Ncat = 4;% 1=noise, 2=SWD, 3=ESs, 4=Spikelets
Catnames = {'noise','SWD','ESs','Spikelets'};
% Ncat = 3;% 1=noise,2=SWD, 3=Spikes
% Catnames = {'noise','SWD','Spikes'};

for icat=1:Ncat % get filenames and calculate image numbers
%     [EEGFiles(icat).name,EEGFiles(icat).path] = uigetfile([BasePath '*.dat'],['Please select EEG filename for: ',char(Catnames(1,icat))]);
    [EEGFiles(icat).name,EEGFiles(icat).path] = uigetfile([DetectorPath '*.dat'],['Please select EEG filename for: ',char(Catnames(1,icat))]);
end
EEGsizes = zeros(Ncat,1);
for icat=1:Ncat
    FileName = ([EEGFiles(icat).path,EEGFiles(icat).name]);
    fid=fopen(FileName,'r');
    EEG = fread(fid,'float');fclose(fid);
    EEGsizes(icat,1) = floor(size(EEG,1)/SignalLength); % number of images to be computed for this category
end

Nimages = sum(EEGsizes,1);    
allImagesArray = zeros(224,224,3,Nimages);
allImagesArray = uint8(allImagesArray);
Labels ={};
iknt=0;
for icat=1:Ncat
    FileName = ([EEGFiles(icat).path,EEGFiles(icat).name]);
    fid=fopen(FileName,'r');EEG = fread(fid,'float');fclose(fid); %this is one long concatinated trace
    % but now let's filter each EEG before training AND remember to filter
    % during classification
    EEG = FiltBlock(EEG,Fs,cutlo,cuthi,order);
    EEG = NotchBlock(EEG,Fs);
    nBlock = EEGsizes(icat,1); % number of 10 sec blocks in concatentated file for each category
    
%      tracefig=figure();scalefig=figure();

    
    
    for iblock=1:nBlock % convert each 10 sec sample into scalogram and store in allImagesArray 
        disp(iblock)
        iknt=iknt+1;
        istart = ((iblock-1)*SignalLength)+1;istop = istart+(SignalLength-1);%note now using full 10 seconds
        sampledat = EEG(istart:istop,1); %single 10 sec trace
        cfs = abs(fb.wt(sampledat)); % get scalogram coeficients 
        cfs = imresize(cfs,[224 224]);
        im = im2uint8(rescale(cfs)); %do the uint8s in sequence like this
        im = im2uint8(ind2rgb(im,jet(128))); % convert scalogram to 8-bit unsigned image in RGB
        im = imresize(im,[224 224]);
        allImagesArray(:,:,:,iknt) = im;
        Labels(iknt,1) = {num2str(icat)};
    end
end
Labels = categorical(Labels);

allImagesArrayRnd = allImagesArray;
LabelsRnd = Labels;
indx=randperm(Nimages);
for i=1:Nimages
   allImagesArrayRnd(:,:,:,indx(1,i)) = allImagesArray(:,:,:,i);
   LabelsRnd(indx(1,i),1) = Labels(i,1);
end
allImagesArray = allImagesArrayRnd;
Labels = LabelsRnd;

NimagesHalf = floor(Nimages/2);
imgsTrain=allImagesArray(:,:,:,1:NimagesHalf);
imgsValidation=allImagesArray(:,:,:,NimagesHalf+1:NimagesHalf+NimagesHalf);
LabelsTrain = Labels(1:NimagesHalf,1);
LabelsValidation = Labels(NimagesHalf+1:NimagesHalf+NimagesHalf,1);

rng default
net = googlenet;
lgraph = layerGraph(net);
numberOfLayers = numel(lgraph.Layers);

newDropoutLayer = dropoutLayer(0.6,'Name','new_Dropout');
lgraph = replaceLayer(lgraph,'pool5-drop_7x7_s1',newDropoutLayer);
numClasses = Ncat;
newConnectedLayer = fullyConnectedLayer(numClasses,'Name','new_fc',...
    'WeightLearnRateFactor',5,'BiasLearnRateFactor',5);
lgraph = replaceLayer(lgraph,'loss3-classifier',newConnectedLayer);
newClassLayer = classificationLayer('Name','new_classoutput');
lgraph = replaceLayer(lgraph,'output',newClassLayer);

options = trainingOptions('sgdm',...
    'MiniBatchSize',15,...
    'MaxEpochs',15,...
    'InitialLearnRate',1e-4,...
    'ValidationFrequency',10,...
    'Verbose',1,...
    'ExecutionEnvironment','gpu',...
    'Plots','training-progress');
rng default

% trainedGN = trainNetwork(imgsTrain,LabelsTrain',lgraph,options);
% pause
trainedGN = trainNetwork(allImagesArray,Labels',lgraph,options);
% save([BasePath 'GNmodCat' num2str(Ncat)],'trainedGN')
save([DetectorPath 'GNmodCat' num2str(Ncat)],'trainedGN')

% [YPred,probs] = classify(trainedGN,imgsValidation);
% for i=1:NimagesHalf
%     disp([YPred(i,1) LabelsValidation(i,1)])
% end
