function [sampleData, isSuccess]=cutDownHumanVoice(sampleDataInitial)
    if(size(sampleDataInitial, 2)== 2) %双通道数据才进行操作
        deta=sampleDataInitial(:, 1)-sampleDataInitial(:, 2); %两个通道的差值
        sampleData(:, 1)= deta; %左通道赋值
        sampleData(:, 2)= deta; %右通道赋值
    else%单通道数据不进行操作
        sampleData=sampleDataInitial;
        isSuccess= false;
    end
end
