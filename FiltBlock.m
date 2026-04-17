function outdat = FiltBlock(indat,Fs,cutlo,cuthi,order)
    % bandpass filters a column ordered block of data
    % outdat       	= npnts x nchan
    % indat         = npnts x nchan
    % cutlo		= lowpass cutoff
    % cuthi		= highpass cutoff
    % order		= filter order
    ny=Fs/2;
    outdat=indat;
    if(cutlo==0)
        [b,a]=butter(order,cuthi/ny,'low');
    else
        [b,a]=butter(order,[cutlo/ny,cuthi/ny]);
    end
%     outdat=filter(b,a,indat')';              %leave it on filter for speed
    outdat=filtfilt(b,a,indat')';          %change to filtfilt for accuracy
end
