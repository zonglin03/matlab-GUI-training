 function sampleData=setPopularEq(sampleDataInitial, EqType, fs)
            fre=[0 31 63 125 250 500 1000 2000 4000 8000 16000 fs/2];%12个典型频率
            f=fre/(fs/2); %归一化频率
            if strcmp(EqType, 'Normal')%正常音效
                sampleData=sampleDataInitial;
            else %附加其他音效
                switch EqType
                    case 'Jazz'%爵士音效
                        m=[0 1.995 1.995 1.259 1.585 0.631 0.794 1 1.259 1.585 2.512 0];
                    case 'Rock'%摇滚音效
                        m=[0 2.512 1.995 1.995 1.259 1 0.794 1 1.259 1.585 2.512 0];
                    case 'Metal '%重金属音效
                        m=[0 0.501 3.162 2.512 0.631 0.501 0.631 1.585 1.995 1.259 2.512 0];
                    case 'Bass'%Bass音效
                        m=[0 3.981 3.162 6.310 1.585 1 1 1 1 1 1 0];
                    otherwise
                        m=[1 1 1 1 1 1 1 1 1 1 1 1];
                end
                b=fir2(100, f, m);%获得FIR滤波器系数
                sampleData=filter(b, 1, sampleDataInitial);%滤波end

            end
        end