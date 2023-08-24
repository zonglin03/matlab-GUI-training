classdef music < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        Menu                    matlab.ui.container.Menu
        Menu_play               matlab.ui.container.Menu
        Menu_pause              matlab.ui.container.Menu
        Menu_resume             matlab.ui.container.Menu
        Menu_stop               matlab.ui.container.Menu
        Menu_preMusic           matlab.ui.container.Menu
        Menu_nextMusic          matlab.ui.container.Menu
        Panel_playControl       matlab.ui.container.Panel
        Button_nextMusic        matlab.ui.control.Button
        Button_preMusic         matlab.ui.control.Button
        Button_stop             matlab.ui.control.Button
        Button_resume           matlab.ui.control.Button
        Button_pause            matlab.ui.control.Button
        Button_play             matlab.ui.control.Button
        Panel_process           matlab.ui.container.Panel
        Label_progress          matlab.ui.control.Label
        Slider_progress         matlab.ui.control.Slider
        Label_8                 matlab.ui.control.Label
        Panel_waveForm          matlab.ui.container.Panel
        UIAxes_current          matlab.ui.control.UIAxes
        UIAxes_all              matlab.ui.control.UIAxes
        Panel_musicEffect       matlab.ui.container.Panel
        Switch_humanVoice       matlab.ui.control.Switch
        Label_7                 matlab.ui.control.Label
        Label_humanVoice        matlab.ui.control.Label
        DropDown_reverberation  matlab.ui.control.DropDown
        Label_5                 matlab.ui.control.Label
        DropDown_speed          matlab.ui.control.DropDown
        Label_4                 matlab.ui.control.Label
        DropDown_equalizer      matlab.ui.control.DropDown
        Label_3                 matlab.ui.control.Label
        Panel_muicList          matlab.ui.container.Panel
        Button_importMusic      matlab.ui.control.Button
        ListBox_music           matlab.ui.control.ListBox
        Label_2                 matlab.ui.control.Label
        Label_appTitle          matlab.ui.control.Label
    end


    properties (Access = private)
        FileNames={}      %导入的音乐文件的名字
        PathName=""     %导入的音乐文件的路径
        FileCount=0     %导入的音乐文件的个数
        SampleData=[]   %播放的采样数据
        SampleDataInitial=[]%原始音频文件采样数据
        Fs=-1   %采样频率
        CurrentSample=1     %播放器的播放位置，默认从头开始
        Player={}   %播放器audioplayer对象
        EqType='Normal' %Eq类型 Normal', 'Jazz', 'Rock', 'Metal', 'Bass'
        IsRemoveHumanVoice=false    %是否进行人声消除，true:消除;false:不消除ReverbValuc=0%混响参数，以秒为单位
        PlaySpeed=1 %播放速度
    end

    methods (Access = private)

        function readMusicDataAndInit(app, fileName)
            fullFilePath=[app.PathName, fileName];%生成音乐文件路径名+文件名
            [sampleData, fs]=audioread(fullFilePath);%读入音频文件数据
            app.SampleDataInitial=sampleData;%存储原始音频文件采样数据
            app.SampleData=sampleData;%存储播放数据
            app.Fs=fs;%存储采样频率
            app.CurrentSample=1;%初始化播放器的播放位置
        end

        %计时器回调函数,定时更新进度条及波形显示
        function Player_timerFcn(app)
            %1.根据当前播放位置，设定进度条显示位置
            currentSample=app.Player.CurrentSample;%当前播放到的数据点
            totalSamples=app.Player.TotalSamples;%音乐文件总数据点数
            app.Slider_progress. Value=currentSample/(totalSamples+1);%设定进度条当前值

            %2.根据当前播放位置，设定文本标签显示效果
            %(1)获取当前播放位置显示文本
            currentSec=currentSampleapp. Fs;%当前播放到的时刻（以秒计)
            [tHourStrCur,tMinStrCur,tSecStrCur]=sec2HourMinSec(currentSec);%转换为以时分秒计
            currentStr=[tHourStrCur, ':', tMinStrCur, ':', tSecStrCur]; %时分秒组合字符串:"时:分:秒"
            %(2)获取总时长显示文本
            totalSec=totalSamples/app.Fs;%音乐文件总时长（以秒计）
            [ tHourStrTotal, tMinStrTotal, tSecStrTotal]=sec2HourMinSec(totalSec);%转换为时分秒计
            totalStr=[tHourStrTotal, ':', tMinStrTotal, ':', tSecStrTotal];%时分秒组合字符串: "时:分:秒"
            %(3)时间进度标签显示
            timeLabelStr=[currentStr,'/', totalStr]; %时间进度标签文本
            app.Label_progress.Text=timeLabelStr;%显示时间进度标签
            %3.波形显示
            %（1）获得总的数据
            tAll=(1 :totalSamples)/app.Fs;%从开始到结束所有时刻点
            tAll=tAll';%行向量变列向量
            xAll=app.SampleData(:,1);%从开始到结束单通道中所有音频数据数据
            %(2）获得当前播放位置附近的显示区间的数据
            duraDisplay=2;%当前播放位置附近显示的时长
            lengthDisplay=round(app.Fs*duraDisplay);%当前播放位置附近显示的数据点数
            if currentSample+lengthDisplay-1<=totalSamples %正常情况
                idxStart=currentSample;%获得显示的起始索引位置
            else %显示区间段最后超过总数据点数,防止最后越界
                idxStart=totalSamples-lengthDisplay+1;%获得起始索引位置
            end
            idxEnd=idxStart+lengthDisplay-1 ;%获得显示的结束索引位置
            tDisplay=tAll(idxStart:idxEnd,1);
            xDisplay=xAll(idxStart:idxEnd,1);
            %(3）在时域波形面板中的上面的坐标轴上绘图
            plot(app.UIAxes_all, tAll, xAll, '-k')%绘制总图
            hold(app.UIAxes_all, 'on')%可叠加绘制开启
            plot(app.UIAxes_all, tDisplay, xDisplay, '-r')%绘制当前播放附近的图
            hold(app. UIAxes_all, 'off')%可叠加绘制关闭
            %(4）在时域波形面板中的下面的坐标轴上绘图
            plot(app.UIAxes_current, tDisplay,xDisplay, '-r')%绘制当前播放附近的图

        end
        
        %Value changed function: DropDown_equalizer
        function DropDown_equalizerValueChanged(app, event)
            value = app.DropDown_equalizer.Value;%获取当前选择的Eq类型
            app.EqType=value;%将该Eq类型进行存储
            if(~isempty(app.Player))%对象非空时
                app.CurrentSample=app.Player.CurrentSample; %将当前播放位置进行存储
                Button_playPushed(app, event);%调用播放按钮的回调函数,立即播放
            end
        end

        %初始化音乐播放器
        function initPlayer(app)
            %1.处理Eq风格
            app.SampleData=app.SampleDataInitial;
            app.SampleData=setPopularEq(app.SampleData, app.EqType, app.Fs);
            %2.处理人声
            if(app.IsRemoveHumanVoice)%进行人声消除
                app.SampleData=cutDownHumanVoice(app.SampleData);%调用人声消除函数
            end
           %3.处理混响
            if(app.ReverbValue~=O) %等于0时无混响，不需要处理;不等于0时需要处理
                %调用加混响效果的函数
                app.SampleData=getReverbSampleData(app.SampleData,app.ReverbValue,app.Fs);
            end
            %4.播放数据非空时,实例化audioplayer对象
            if(~isempty(app.SampleData))
                app.Player=audioplayer( app.SampleData, app.Fs);%实例化audioplayer对象
                app.Player.TimerFcn=@(~, ~) Player_timerFcn(app);%定义 Timer回调函数
                app. Player.TimerPeriod=0.5;%定义Timer回调周期
            else
                app.Player={};
            end
            % 5.处理播放速度
            app.Player.SampleRate=round(app.Fs*app.PlaySpeed);

        end







    end

    



    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: Button_importMusic
        function Button_importMusicPushed(app, event)
            %1.读取音乐文件
            [fileNames,pathName]=uigetfile( {'*.mp3','*.wav'},'导入音乐文件',...
                'defaultName','MultiSelect' , 'on');
            if( isfloat(fileNames)) %用户点击取消按钮，未导入任何文件，返回值为double型:0
                return; %退出
            elseif(ischar(fileNames))%只读入1个文件时格式为 char类型，多个文件时为cell类型
                fileNames={fileNames};%将读入1个文件和多个文件都统一使用cell类型表征
            end
            %2.私有属性赋值,方便其他函数使用
            app.FileNames=fileNames; %(1)FilcNamc属性赋值
            app.PathName=pathName; %(2) PathName属性赋值
            app.FileCount=length(fileNames); %(3）FileCount属性赋值%
            % 3．歌曲列表框显示设置
            app.ListBox_music.Items=fileNames;%音乐列表框显示的内容
            app.ListBox_music.Value=fileNames{1,1};%初始导入后默认选中第1个
            %4.从音乐文件中读取播放数据并初始化播放数据
            readMusicDataAndInit(app, fileNames{1,1})

        end

        % Value changed function: ListBox_music
        function ListBox_musicValueChanged(app, event)
            value = app.ListBox_music.Value;
            readMusicDataAndInit(app,value);
        end

        % Menu selected function: Menu_play
        function Menu_playSelected(app, event)
            initPlayer(app);%初始化音乐播放器对象
            if(~isempty(app.Player))%对象非空时
                play(app.Player, app.CurrentSample);%播放
            end

        end

        % Menu selected function: Menu_pause
        function Menu_pauseSelected(app, event)
            if(~isempty(app.Player))%对象非空时
                pause(app.Player); %继续播放
            end

        end

        % Menu selected function: Menu_resume
        function Menu_resumeSelected(app, event)
            if(~isempty(app.Player))%对象非空时
                resume(app.Player); %继续播放
            end
        end

        % Menu selected function: Menu_stop
        function Menu_stopSelected(app, event)
            if(~isempty(app.Player))%对象非空时
                stop(app.Player); %继续播放
            end
        end

        % Menu selected function: Menu_preMusic
        function Menu_preMusicSelected(app, event)
            %1.获取当前歌曲的索引，即是第几首歌曲
            current Value=app.ListBox_music.Value;%获取当前选择的歌曲名
            currentIndex=0;%初始化当前歌曲的索引
            for ii=1:app.FileCount%循环对比，找出是哪一首歌曲
                if strcmp(currentValue, app.FileNames{1,ii})==1
                    currentIndex=ii;
                    break;
                end
            end
            %2.根据当前歌曲索引，获取上一首歌曲名
            if(currentIndex==1)%当前歌曲为第1首时，上一首为最后一首
                new Value=app.FileNames {1, app.FileCount}; %获取上一首歌曲名
            else %当前歌曲不是第1首时
                newValue=app.FileNames{1, currentIndex-1};%获取上一首歌曲名
            end
            %3.修改音乐列表框中的显示
            app.ListBox_music.Value=newValue;
            %4.读取上一首音乐数据并初始化播放数据
            readMusicDataAndInit(app, newValue);
            %5.调用播放按钮的回调函数，立即播放
            Button_playPushed(app, event);

        end

        % Menu selected function: Menu_nextMusic
        function Menu_nextMusicSelected(app, event)
            %1.获取当前歌曲的索引，即是第几首歌曲
            current Value=app.ListBox_music.Value;%获取当前选择的歌曲名
            currentIndex=0; %初始化当前歌曲的索引
            for ii=1:app.FileCount%循环对比,找出是哪一首歌曲
                if strcmp(currentValue,app.FileNames{1, ii})==1
                    currentIndex=ii;
                    break;
                end
            end
            %2.根据当前歌曲索引，获取下一首歌曲名
            if (currentIndex==app.FileCount)%当前歌曲为最后一首时，下一首为第一首
                new Value=app. FileNames{1,13;%获取下一首歌曲名
            else%当前歌曲不是最后一首时
                new Value=app.FileNames {1, currentIndex+1};%获取下一首歌曲名
            end
            %3.修改音乐列表框中的显示
            app.ListBox_music.Value=newValue;
            %4.读取上一首音乐数据并初始化播放数据
            readMusicDataAndInit(app, newValue);
            %5.调用播放按钮的回调函数，立即播放
            Button_playPushed(app, event);

        end

        % Value changed function: Slider_progress
        function Slider_progressValueChanged(app, event)
            value = app.Slider_progress.Value;%获取设定值
            if~isempty(app.Player)%当前播放器非空
                newSamplePos=floor((app.Player.TotalSamples+1 )*value);%获得新的起始播放点数
                pause(app.Player), %暂停当前播放
                play(app.Player,newSamplePos); %从新的指定位置处播放
            else %当前播放器为空
                app.Slider_progress.Value=0;%进度条置零
            end

        end

        % Value changed function: DropDown_equalizer
        function DropDown_equalizerValueChanged2(app, event)
            value = app.DropDown_equalizer.Value;
            app.EqType=value;%将该Eq类型进行存储
            if(~isempty(app.Player))%对象非空时
                app.CurrentSample=app.Player.CurrentSample;%将当前播放位置进行存储
                Button_playPushed(app,event);%调用播放按钮的回调函数，立即播放
            end

        end

        % Value changed function: Switch_humanVoice
        function Switch_humanVoiceValueChanged(app, event)
            value = app.Switch_humanVoice.Value;
            if (strcmp(value, 'Of')) %不进行人声消除
                app.IsRemoveHumanVoice=false;
            else %进行人声消除
                app.IsRemoveHumanVoice=true;
            end
            if(~isempty(app.Player))%对象非空时
                app.CurrentSample=app.Player. CurrentSample; %将当前播放位置进行存储
                Button_playPushed(app, event);%调用播放按钮的回调函数，立即播放
            end

        end

        % Value changed function: DropDown_reverberation
        function DropDown_reverberationValueChanged(app, event)
            value = app.DropDown_reverberation.Value;
            app.ReverbValue=str2double(strip(value, 'right', 's'));%获取混响值
            if(~isempty(app.Player))%对象非空时
                app.CurrentSample=app.Player.CurrentSample;%将当前播放位置进行存储
                Button_playPushed(app, event);%调用播放按钮的回调函数，立即播放
            end

        end

        % Value changed function: DropDown_speed
        function DropDown_speedValueChanged(app, event)
            value = app.DropDown_speed. Value;%获取当前选择的速度参数
            app.PlaySpeed=str2double(strip(value, 'right', 'X'));%获取速度值
            if ~isempty(app.Player)%对象非空时
                app.CurrentSample=app.Player.CurrentSample;%将当前播放位置进行存储
                Button_playPushed(app); %调用播放按钮的回调函数，立即播放
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 974 654];
            app.UIFigure.Name = 'MATLAB App';

            % Create Menu
            app.Menu = uimenu(app.UIFigure);
            app.Menu.Text = '音乐控制';

            % Create Menu_play
            app.Menu_play = uimenu(app.Menu);
            app.Menu_play.MenuSelectedFcn = createCallbackFcn(app, @Menu_playSelected, true);
            app.Menu_play.Text = '播放';

            % Create Menu_pause
            app.Menu_pause = uimenu(app.Menu);
            app.Menu_pause.MenuSelectedFcn = createCallbackFcn(app, @Menu_pauseSelected, true);
            app.Menu_pause.Text = '暂停';

            % Create Menu_resume
            app.Menu_resume = uimenu(app.Menu);
            app.Menu_resume.MenuSelectedFcn = createCallbackFcn(app, @Menu_resumeSelected, true);
            app.Menu_resume.Text = '续播';

            % Create Menu_stop
            app.Menu_stop = uimenu(app.Menu);
            app.Menu_stop.MenuSelectedFcn = createCallbackFcn(app, @Menu_stopSelected, true);
            app.Menu_stop.Text = '停止';

            % Create Menu_preMusic
            app.Menu_preMusic = uimenu(app.Menu);
            app.Menu_preMusic.MenuSelectedFcn = createCallbackFcn(app, @Menu_preMusicSelected, true);
            app.Menu_preMusic.Text = '上一首';

            % Create Menu_nextMusic
            app.Menu_nextMusic = uimenu(app.Menu);
            app.Menu_nextMusic.MenuSelectedFcn = createCallbackFcn(app, @Menu_nextMusicSelected, true);
            app.Menu_nextMusic.Text = '下一首';

            % Create Label_appTitle
            app.Label_appTitle = uilabel(app.UIFigure);
            app.Label_appTitle.FontSize = 32;
            app.Label_appTitle.Position = [426 598 166 43];
            app.Label_appTitle.Text = '音乐播放器';

            % Create Panel_muicList
            app.Panel_muicList = uipanel(app.UIFigure);
            app.Panel_muicList.TitlePosition = 'centertop';
            app.Panel_muicList.Title = '歌曲列表';
            app.Panel_muicList.FontWeight = 'bold';
            app.Panel_muicList.FontSize = 16;
            app.Panel_muicList.Position = [21 206 230 378];

            % Create Label_2
            app.Label_2 = uilabel(app.Panel_muicList);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.Position = [90 354 25 22];
            app.Label_2.Text = '';

            % Create ListBox_music
            app.ListBox_music = uilistbox(app.Panel_muicList);
            app.ListBox_music.Items = {};
            app.ListBox_music.ValueChangedFcn = createCallbackFcn(app, @ListBox_musicValueChanged, true);
            app.ListBox_music.Position = [24 44 173 303];
            app.ListBox_music.Value = {};

            % Create Button_importMusic
            app.Button_importMusic = uibutton(app.Panel_muicList, 'push');
            app.Button_importMusic.ButtonPushedFcn = createCallbackFcn(app, @Button_importMusicPushed, true);
            app.Button_importMusic.FontSize = 16;
            app.Button_importMusic.Position = [57 8 100 28];
            app.Button_importMusic.Text = '导入歌曲';

            % Create Panel_musicEffect
            app.Panel_musicEffect = uipanel(app.UIFigure);
            app.Panel_musicEffect.TitlePosition = 'centertop';
            app.Panel_musicEffect.Title = '音效控制';
            app.Panel_musicEffect.FontWeight = 'bold';
            app.Panel_musicEffect.FontSize = 16;
            app.Panel_musicEffect.Position = [21 15 230 181];

            % Create Label_3
            app.Label_3 = uilabel(app.Panel_musicEffect);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.FontSize = 16;
            app.Label_3.Position = [14 119 85 22];
            app.Label_3.Text = '音乐风格：';

            % Create DropDown_equalizer
            app.DropDown_equalizer = uidropdown(app.Panel_musicEffect);
            app.DropDown_equalizer.Items = {'Normal', 'Jazz', 'Rock', 'Metal', 'Bass'};
            app.DropDown_equalizer.ValueChangedFcn = createCallbackFcn(app, @DropDown_equalizerValueChanged2, true);
            app.DropDown_equalizer.FontSize = 16;
            app.DropDown_equalizer.Position = [114 119 100 22];
            app.DropDown_equalizer.Value = 'Normal';

            % Create Label_4
            app.Label_4 = uilabel(app.Panel_musicEffect);
            app.Label_4.HorizontalAlignment = 'right';
            app.Label_4.FontSize = 16;
            app.Label_4.Position = [14 84 85 22];
            app.Label_4.Text = '播放速度：';

            % Create DropDown_speed
            app.DropDown_speed = uidropdown(app.Panel_musicEffect);
            app.DropDown_speed.Items = {'0.5X', '0.75X', '1X', '1.25X', '1.5X', '1.75X', '2X'};
            app.DropDown_speed.ValueChangedFcn = createCallbackFcn(app, @DropDown_speedValueChanged, true);
            app.DropDown_speed.FontSize = 16;
            app.DropDown_speed.Position = [114 84 100 22];
            app.DropDown_speed.Value = '1X';

            % Create Label_5
            app.Label_5 = uilabel(app.Panel_musicEffect);
            app.Label_5.HorizontalAlignment = 'right';
            app.Label_5.FontSize = 16;
            app.Label_5.Position = [46 46 53 22];
            app.Label_5.Text = '混响：';

            % Create DropDown_reverberation
            app.DropDown_reverberation = uidropdown(app.Panel_musicEffect);
            app.DropDown_reverberation.Items = {'0.0s', '0.04s', '0.08s', '0.12s', '0.16s', '0.2s'};
            app.DropDown_reverberation.ValueChangedFcn = createCallbackFcn(app, @DropDown_reverberationValueChanged, true);
            app.DropDown_reverberation.FontSize = 16;
            app.DropDown_reverberation.Position = [114 46 100 22];
            app.DropDown_reverberation.Value = '0.0s';

            % Create Label_humanVoice
            app.Label_humanVoice = uilabel(app.Panel_musicEffect);
            app.Label_humanVoice.FontSize = 16;
            app.Label_humanVoice.Position = [19 11 85 22];
            app.Label_humanVoice.Text = '人声消除：';

            % Create Label_7
            app.Label_7 = uilabel(app.Panel_musicEffect);
            app.Label_7.HorizontalAlignment = 'center';
            app.Label_7.FontSize = 16;
            app.Label_7.Position = [146 1 25 22];
            app.Label_7.Text = '';

            % Create Switch_humanVoice
            app.Switch_humanVoice = uiswitch(app.Panel_musicEffect, 'slider');
            app.Switch_humanVoice.ValueChangedFcn = createCallbackFcn(app, @Switch_humanVoiceValueChanged, true);
            app.Switch_humanVoice.FontSize = 16;
            app.Switch_humanVoice.Position = [136 12 45 20];

            % Create Panel_waveForm
            app.Panel_waveForm = uipanel(app.UIFigure);
            app.Panel_waveForm.TitlePosition = 'centertop';
            app.Panel_waveForm.Title = '时域波形';
            app.Panel_waveForm.FontWeight = 'bold';
            app.Panel_waveForm.FontSize = 16;
            app.Panel_waveForm.Position = [266 160 687 424];

            % Create UIAxes_all
            app.UIAxes_all = uiaxes(app.Panel_waveForm);
            xlabel(app.UIAxes_all, 'Time(s)')
            ylabel(app.UIAxes_all, 'Magnitude')
            zlabel(app.UIAxes_all, 'Z')
            app.UIAxes_all.XTick = [0 0.2 0.4 0.6 0.8 1];
            app.UIAxes_all.Position = [21 219 640 170];

            % Create UIAxes_current
            app.UIAxes_current = uiaxes(app.Panel_waveForm);
            xlabel(app.UIAxes_current, 'Time(s)')
            ylabel(app.UIAxes_current, 'Magnitude')
            zlabel(app.UIAxes_current, 'Z')
            app.UIAxes_current.Position = [24 19 640 185];

            % Create Panel_process
            app.Panel_process = uipanel(app.UIFigure);
            app.Panel_process.TitlePosition = 'centertop';
            app.Panel_process.Position = [267 104 686 48];

            % Create Label_8
            app.Label_8 = uilabel(app.Panel_process);
            app.Label_8.HorizontalAlignment = 'right';
            app.Label_8.FontSize = 16;
            app.Label_8.Position = [7 11 85 22];
            app.Label_8.Text = '音乐进度：';

            % Create Slider_progress
            app.Slider_progress = uislider(app.Panel_process);
            app.Slider_progress.Limits = [0 1];
            app.Slider_progress.MajorTicks = [];
            app.Slider_progress.ValueChangedFcn = createCallbackFcn(app, @Slider_progressValueChanged, true);
            app.Slider_progress.MinorTicks = [];
            app.Slider_progress.FontSize = 16;
            app.Slider_progress.Position = [113 20 405 3];

            % Create Label_progress
            app.Label_progress = uilabel(app.Panel_process);
            app.Label_progress.FontSize = 16;
            app.Label_progress.Position = [533 10 143 22];
            app.Label_progress.Text = '00:00:00/00:00:00';

            % Create Panel_playControl
            app.Panel_playControl = uipanel(app.UIFigure);
            app.Panel_playControl.TitlePosition = 'centertop';
            app.Panel_playControl.Title = '播放控制';
            app.Panel_playControl.FontWeight = 'bold';
            app.Panel_playControl.FontSize = 16;
            app.Panel_playControl.Position = [267 15 688 81];

            % Create Button_play
            app.Button_play = uibutton(app.Panel_playControl, 'push');
            app.Button_play.FontSize = 16;
            app.Button_play.Position = [16 12 100 28];
            app.Button_play.Text = '播放';

            % Create Button_pause
            app.Button_pause = uibutton(app.Panel_playControl, 'push');
            app.Button_pause.FontSize = 16;
            app.Button_pause.Position = [126 12 100 28];
            app.Button_pause.Text = '暂停';

            % Create Button_resume
            app.Button_resume = uibutton(app.Panel_playControl, 'push');
            app.Button_resume.FontSize = 16;
            app.Button_resume.Position = [236 12 100 28];
            app.Button_resume.Text = '续播';

            % Create Button_stop
            app.Button_stop = uibutton(app.Panel_playControl, 'push');
            app.Button_stop.FontSize = 16;
            app.Button_stop.Position = [346 12 100 28];
            app.Button_stop.Text = '停止';

            % Create Button_preMusic
            app.Button_preMusic = uibutton(app.Panel_playControl, 'push');
            app.Button_preMusic.FontSize = 16;
            app.Button_preMusic.Position = [458 12 100 28];
            app.Button_preMusic.Text = '上一首';

            % Create Button_nextMusic
            app.Button_nextMusic = uibutton(app.Panel_playControl, 'push');
            app.Button_nextMusic.FontSize = 16;
            app.Button_nextMusic.Position = [571 12 100 28];
            app.Button_nextMusic.Text = '下一首';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = music

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end