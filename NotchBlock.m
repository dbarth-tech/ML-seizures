function outdat = NotchBlock(indat,Fs)
% notch filters a block of data to eliminate 60 Hz plus 120 and 180 Hz harmonics
% outdat       	= nchan x npnts
% indat         = nchan x npnts
[nchan,npnts] = size(indat);ny=Fs/2;
outdat=indat';



wo = 180/ny; bw=wo/35;
[b1,a1]=iirnotch(60/ny,bw);
[b2,a2]=iirnotch(120/ny,bw);
[b3,a3]=iirnotch(180/ny,bw);
outdat=filter(b1,a1,indat');         
outdat=filter(b2,b2,outdat);         
outdat=filter(b3,a3,outdat);         
outdat=outdat';

end

