function [LongTrace,ReformData,ReformDataUnfiltered,nlines] = ReadFilterRasterizeLongTraceRaw(FileName,channel,Fs,cutlo,cuthi,order,notch)
% Set order to 0 to skip filtering
    fidEEGin=fopen(FileName,'r');
    FileName
    header=fread(fidEEGin,256,'float');
    whos header
    npnts = header(4); % this is now the total # points for 30 minutes
    NchanPerRat = header(7);
    ny = Fs/2;[b,a]=butter(order,[cutlo/ny,cuthi/ny]);
    InBuffEEG = fread(fidEEGin,[NchanPerRat,npnts],'int16'); %one long record of 4 channels
    LongTrace = (InBuffEEG(channel,:));
%     LongTrace = gpuArray(InBuffEEG(channel,:));
    nlines = size(LongTrace,2)/5000;
    ReformDataUnfiltered = reshape(LongTrace,[5000,nlines]);

    LongTrace = (filter(b,a,LongTrace)); %always filter as one long row of data (1,total points)

%     LongTrace = gather(filter(b,a,LongTrace)); %always filter as one long row of data (1,total points)
%     sysusr();
    if(notch);LongTrace = NotchBlock(LongTrace,Fs);end
    LongTrace = LongTrace-mean(LongTrace);
    ReformData = reshape(LongTrace,[5000,nlines]); %fastest moving is the row index, so chunks of 1-5000
    fclose(fidEEGin);
end
