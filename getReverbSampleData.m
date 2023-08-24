function sampleData=getReverbSampleData(sampleDataInitial, reverbValue, fs)
            zeroNum=round(fs*reverbValue); %采样频率*延时时间=延时数据点数
            zerosData=zeros(zeroNum, size(sampleDataInitial, 2));%延时处需要补零
            x0=sampleDataInitial; %原始音频数据
            x1=[x0; zerosData]; %原始音频数据+补零
            x2=[zerosData; x0];%将原始数据向右偏移，左边补零，获得延时音频数据
            sampleData=(x1+x2)/2;%将原始数据与延时数据相加除以2获得混响数据
        end