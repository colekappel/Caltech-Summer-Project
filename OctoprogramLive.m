%{

 
 *  Documentation: https://drive.google.com/drive/folders/1KO-BbYIWLT3vGuHTHezoEGocm-yG4Wc9

 *  Required Hardware Parts List: https://docs.google.com/document/d/1zNLYMNLZTGmoZ9-0ag7mZ5a84KvkOMSjKftjlTZL42o/edit#
 
 *  Instructions for Putting Hardware together: https://docs.google.com/presentation/d/1c655EPxgbJqD-ze0mLTKCqgfO5gB6cGL3y8jaUUU26Q/edit#slide=id.g3fed37a16b_0_40
  

Modified and Created Summer, 2021
by Cole Kappel

This Program is an infinite loop that plots the live sensor data at hcst.
It updates sensor data with current arduino time stamp every 15 seconds - 
the updateCadence.
Make sure to run this program in MATLAB R2021a (some errors are encountered if
running in MATLAB 2017b)
%}
clear %clear the workspace for error testing
opengl hardware
x=0;
IPAdress='192.168.1.3'; %KPIC - define your IP address here. For HCST it should be 192.168.1.3

% vvvv color bar limits vvvvv
tLow =0;
tHigh=40;
hLow=0;
hHigh=100;
%^^^^^^^^^^^^^^^^^^^^^^^

updateCadence =15; %Live plots update every 15 seconds
timerVal = tic; %For taking data every x seconds see tic toc documentation in matlab
numSensors = 8;
numDataPoints = 12;
mainFile = 'C:\Users\ET\Desktop\EnviSensData';

%Code for formatting axes and creating different figures for each 
%Environmental factor see: https://www.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html

%Create seperature figures for each 7 min plot and put them in a subplot so
%they all get displayed in one figure
dimRows = 3;
dimCols=2;
sevenM = figure('Name','7 Min Live Plot', 'NumberTitle','off');
subplot(dimRows,dimCols,1)
hAxes(1) = gca; %Figure for humidity
subplot(dimRows,dimCols,2);
hAxes(2) = gca; %Figure for temperature
subplot(dimRows,dimCols,3)
hAxes(3) = gca; %Figure for Pressure
subplot(dimRows,dimCols,4);
hAxes(4) = gca; %Figure for Accel X, Y
subplot(dimRows,dimCols,5);
hAxes(13) = gca; %Figure for Accel Z 7m

%Create separate figure for 3h plots
threeH=figure('Name','3 Hour Live Plot', 'NumberTitle','off');
subplot(dimRows,dimCols,1)
hAxes(5) = gca; %Figure for humidity
subplot(dimRows,dimCols,2);
hAxes(6) = gca; %Figure for temperature
subplot(dimRows,dimCols,3)
hAxes(7) = gca; %Figure for Pressure
subplot(dimRows,dimCols,4);
hAxes(8) = gca; %Figure for Accel X, Y
subplot(dimRows,dimCols,5);
hAxes(14) = gca; %Figure for Accel Z 3h

%Create separate figure for 24h plots
twenty4H=figure('Name','24 Hour Live Plot', 'NumberTitle','off');
subplot(dimRows,dimCols,1)
hAxes(9) = gca; %Figure for humidity
subplot(dimRows,dimCols,2);
hAxes(10) = gca; %Figure for temperature
subplot(dimRows,dimCols,3)
hAxes(11) = gca; %Figure for Pressure
subplot(dimRows,dimCols,4);
hAxes(12) = gca; %Figure for Accel X, Y
subplot(dimRows,dimCols,5);
hAxes(15) = gca; %Figure for Accel Z 24h

%vvv Code for creating the figure w/ color maps and the sensor layout in the HCST vvv
tempData = [0 0 0 0; 0 0 0 0]; %First initialize color maps with all zeros
humData = [0 0 0 0; 0 0 0 0];

f = figure('Name','HCST Sensor Layout and Live Color Maps', 'NumberTitle','off');

%KPIC delete these lines or add a pic of your sensor layout? vvvvvvvvvvv 

SensorLayout= imread('C:\Users\ET\Desktop\HCST_SensorLayout.png'); %Pic of sensor layout 
SensorLayoutBg = imresize(SensorLayout,2);

%KPIC delete these lines ^^^^^^^^^^^^

humCMap = heatmap(f,humData,'Colormap',summer,'OuterPosition',[.5 .5 .5 .43]);
humCMap.YData={'A','B'}; %Y label
humCMap.Title = 'Live Percent Humidity Readings';
humCMap.XLabel='Sensor Label';
tempCMap = heatmap(f,tempData,'Colormap',jet,'OuterPosition',[0 .5 .5 .43]);
tempCMap.ColorData =tempData;
tempCMap.Title = strcat(['Live Temperature in ', char(176),'C']);
tempCMap.YData={'A','B'}; %Y label
tempCMap.XLabel='Sensor Label';

%%KPIC delete these lines or add a pic of your sensor layout? vvvvvvvvvvv vvvvvvvvvvv
subplot(2,2,[3,4])
imagesc(SensorLayoutBg) %Show the image in the figure
title('HCST Sensor Layout');
axis off; %Turn of the axis on the image
%KPIC delete these lines ^^^^^^^^^^^^

%Define Y limits for humidty, pressure, accel, temp, and pressure
humHigh = 60;
humLow = 48;
pressHigh = 1000;
pressLow=980;
accelHigh=15;
accelLow=-10;
tempHigh=27;
tempLow=20;


%Format Humidity 7 min graph
hAxes(1).YLim = [humLow humHigh];
hAxes(1).Title.String= "Percent Humidity for the Past 7 minutes";
hAxes(1).YLabel.String= 'Percent Humidity (%)';
hAxes(1).XLabel.String= 'Time';
hAxes(1).XGrid='on';
hAxes(1).YGrid='on';
%Optional extra formatting options commented below
%hAxes(1).XMinorGrid='on'; %Commented code is for minor axes
%hAxes(1).YMinorGrid='on';
%hAxes(1).MinorGridLineStyle ='-';
%hAxes(1).MinorGridAlphaMode= 'manual';
%hAxes(1).MinorGridAlpha = 0.75;
%hAxes(1).Color = 'b'; %Set background color of graph
%hAxes(1).AmbientLightColor = 'b'; %not sure what this does

%Format Humidty 3h graph (same format as 7 min graph except title is for 3
%hours
hAxes(5).YLim = [humLow humHigh];
hAxes(5).Title.String= "Percent Humidity for the Past 3 hours";  
hAxes(5).YLabel.String= 'Percent Humidity (%)';
hAxes(5).XLabel.String= 'Time';
hAxes(5).XGrid='on';
hAxes(5).YGrid='on';

%Format Humidity 24h graph
hAxes(9).YLim = [humLow humHigh];
hAxes(9).Title.String= "Percent Humidity for the Past 24 hours";  
hAxes(9).YLabel.String= 'Percent Humidity (%)';
hAxes(9).XLabel.String= 'Time';
hAxes(9).XGrid='on';
hAxes(9).YGrid='on';

%Format 7 Min Temperature Graph
hAxes(2).YLim = [tempLow tempHigh];
hAxes(2).Title.String= "Temperature for the Past 7 minutes";
hAxes(2).XLabel.String= 'Time';
hAxes(2).YLabel.String= 'Temperature in Degrees Celsius';
hAxes(2).XGrid='on';
hAxes(2).YGrid='on';

%Format 3 Hour Temperature Graph
hAxes(6).YLim = [tempLow tempHigh];
hAxes(6).Title.String= "Temperature for the Past 3 Hours";
hAxes(6).XLabel.String= 'Time';
hAxes(6).YLabel.String= 'Temperature in Degrees Celsius';
hAxes(6).XGrid='on';
hAxes(6).YGrid='on';

%Format 24 Hour Temperature Graph
hAxes(10).YLim = [tempLow tempHigh];
hAxes(10).Title.String= "Temperature for the Past 24 Hours";
hAxes(10).XLabel.String= 'Time';
hAxes(10).YLabel.String= 'Temperature in Degrees Celsius';
hAxes(10).XGrid='on';
hAxes(10).YGrid='on';

%Format Pressure 7 Min graph
hAxes(3).YLim = [pressLow pressHigh];
hAxes(3).Title.String= "Pressure for the Past 7 minutes";
hAxes(3).XLabel.String= 'Time';
hAxes(3).YLabel.String= 'Pressure in hPa or millibar';
hAxes(3).XGrid='on';
hAxes(3).YGrid='on';

%Format Pressure 3 Hour Graph
hAxes(7).YLim = [pressLow pressHigh];
hAxes(7).Title.String= "Pressure for the Past 3 Hours";
hAxes(7).XLabel.String= 'Time';
hAxes(7).YLabel.String= 'Pressure in hPa or millibar';
hAxes(7).XGrid='on';
hAxes(7).YGrid='on';

%Format Pressure 24 Hour Graph
hAxes(11).YLim = [pressLow pressHigh];
hAxes(11).Title.String= "Pressure for the Past 24 Hours";
hAxes(11).XLabel.String= 'Time';
hAxes(11).YLabel.String= 'Pressure in hPa or millibar';
hAxes(11).XGrid='on';
hAxes(11).YGrid='on';

%Format Acceleration 7 Min Graph
hAxes(4).Title.String= "Acceleration for the Past 7 minutes (Ax = solid, Ay = dashed)";
hAxes(4).XLabel.String= 'Time';
hAxes(4).YLabel.String= 'Acceleration in (m/s^2)';
hAxes(4).XGrid='on';
hAxes(4).YGrid='on';

%Format Acceleration 3 Hour Graph
%hAxes(8).YLim = [accelLow accelHigh];
hAxes(8).Title.String= "Acceleration for the Past 3 Hours (Ax = solid, Ay = dashed)";
hAxes(8).XLabel.String= 'Time';
hAxes(8).YLabel.String= 'Acceleration in (m/s^2)';
hAxes(8).XGrid='on';
hAxes(8).YGrid='on';

%Format Acceleration 24 Hour Graph
hAxes(12).Title.String= "Acceleration for the Past 24 Hours (Ax = solid, Ay = dashed)";
hAxes(12).XLabel.String= 'Time';
hAxes(12).YLabel.String= 'Acceleration in (m/s^2)';
hAxes(12).XGrid='on';
hAxes(12).YGrid='on';

%Format Z Acceleration 7 Min Graph
hAxes(13).YLim = [accelLow accelHigh];
hAxes(13).Title.String= "Z Acceleration for the Past 7 minutes";
hAxes(13).XLabel.String= 'Time';
hAxes(13).YLabel.String= 'Acceleration in (m/s^2)';
hAxes(13).XGrid='on';
hAxes(13).YGrid='on';

%Format Z Acceleration 3 Hour Graph
hAxes(14).YLim = [accelLow accelHigh];
hAxes(14).Title.String= "Z Acceleration for the Past 3 Hours";
hAxes(14).XLabel.String= 'Time';
hAxes(14).YLabel.String= 'Acceleration in (m/s^2)';
hAxes(14).XGrid='on';
hAxes(14).YGrid='on';

%Format Z Acceleration 24 Hour Graph
hAxes(15).YLim = [accelLow accelHigh];
hAxes(15).Title.String= "Z Acceleration for the Past 24 Hours";
hAxes(15).XLabel.String= 'Time';
hAxes(15).YLabel.String= 'Acceleration in (m/s^2)';
hAxes(15).XGrid='on';
hAxes(15).YGrid='on';

%define arrays for setting the dynamic y-axis limits
hData7=[];
hData3h=[];
hData24h=[];
tData7=[];
tData3h=[];
tData24h=[];
pData7=[];
pData3h=[];
pData24h=[];
aData7=[];
aData3h=[];
aData24h=[];
aZData7=[];
aZData3h=[];
aZData24h=[];
%vvv define color array to create animated lines in a for loop vvv
%Colors are red, blue, green, cyan, pink, yellow, black, orange in that
%order
colorArray = ["r","b","g","c","m","y","k","#D95319"];

%define all animated Lines 
for z = 1:8
h(z) = animatedline(hAxes(1),'MaximumNumPoints',28,'Color',colorArray(z)); %humidity 7 min animated line
hH3(z) = animatedline(hAxes(5),'MaximumNumPoints',720,'Color',colorArray(z));%humidity 3h animated line
hH24(z) = animatedline(hAxes(9),'MaximumNumPoints',5760,'Color',colorArray(z)); %humidity 24h animated line
t7(z) =  animatedline(hAxes(2),'MaximumNumPoints',28,'Color', colorArray(z)); %temp 7 min animated line
tH3(z) =animatedline(hAxes(6),'MaximumNumPoints',720,'Color',colorArray(z));%temp 3h animated line
tH24(z) = animatedline(hAxes(10),'MaximumNumPoints',5760,'Color',colorArray(z)); %temp 24h animated line
p(z) = animatedline(hAxes(3),'MaximumNumPoints',28,'Color',colorArray(z)); %press 7 min animated line
pH3(z) = animatedline(hAxes(7),'MaximumNumPoints',720,'Color',colorArray(z));%press  3h animated line
pH24(z) = animatedline(hAxes(11),'MaximumNumPoints',5760,'Color',colorArray(z)); %press 24h animated line
ax(z) =  animatedline(hAxes(4),'MaximumNumPoints',28,'Color',colorArray(z)); %solid line for accel x 7m
axH3(z) = animatedline(hAxes(8),'MaximumNumPoints',720,'Color',colorArray(z)); %solid line for accel x  3h
axH24(z) = animatedline(hAxes(12),'MaximumNumPoints',5760,'Color',colorArray(z)); %solid line for accel x  24h
ay(z) = animatedline(hAxes(4),'MaximumNumPoints',28,'Color',colorArray(z),'LineStyle','--');  %dashed line for accel y 7m
ayH3(z) = animatedline(hAxes(8),'MaximumNumPoints',720,'Color',colorArray(z),'LineStyle','--');  %dashed line for accel y 3h
ayH24(z) = animatedline(hAxes(12),'MaximumNumPoints',5760,'Color',colorArray(z),'LineStyle','--'); %dashed line for ay 24h
az(z) = animatedline(hAxes(13),'MaximumNumPoints',28,'Color',colorArray(z)); 
azH3(z) = animatedline(hAxes(14),'MaximumNumPoints',720,'Color',colorArray(z));   
azH24(z)= animatedline(hAxes(15),'MaximumNumPoints',5760,'Color',colorArray(z));


end

while numSensors<10 %Creates an infinite loop bc numSensors is always < 10

%Define time based on arduino current time vvvvvvv

data_RN=webread(strcat('http://',IPAdress,'/now'));

%vvvvvv convert data to matrices vvvvvvv

data_RN = table2cell(data_RN);

data_RN(:,1)=[]; %delete time stamp to be able to convert to matrix

data_RN=cell2mat(data_RN);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

unixTRN=data_RN(1,97);

t=datetime(unixTRN,'ConvertFrom','epochtime');


%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

dayOfYear = day(t,'dayofyear');
sdate = datenum(t); %sdate is in days
%^^^^^^^^^^^^ end of code for getting the correct time ^^^^^^^^^^^^^
    
currTime=t;

%vvvvvvvvv Code for creating the matrix to be added to the excel file vvvvvvvvvv
data = data_RN; 

A(1,:) = ["temp", "humidity", "pressure","accelX","acelY","accelZ","gyroX","gyroY","gyroZ","magX","magY","magZ"];

b=1;
for a  =2:(numSensors+1)
    A(a,:) = data(b:b+11 );
    b=b+numDataPoints;
end

%Add current time
TimeInit = {currTime," "," "," "," "," "," "," "," "};
Time = transpose(TimeInit);

dataCurrTime = cat(2,Time,A);
%^^^^^^^^^^^^^^^^ end of code for creating the matrix ^^^^^^^^^^^^^^^^^^^^^

elapsedTime = toc(timerVal); %Get the elapsed time in seconds
if elapsedTime>updateCadence %vvvvvvvvv Code runs every 15 seconds or however often based on the updateCadence vvvvvvvvvvvvvv
    
    %create heat maps vvvvvvvvvvvvvvvvvvv
    y=1;
    k=1;
    for z=1:8
         q=z+1;
        if z==5 %So this only runs once when z is 5
           y=2;
           k=1;
           humData(y,k)=double(dataCurrTime(q,3));
           tempData(y,k)=double(dataCurrTime(q,2));
        else
           humData(y,k)=double(dataCurrTime(q,3));
           tempData(y,k)=double(dataCurrTime(q,2));
        end
        k=k+1;
    end
    %^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    
    %Update heat map data vvvvvvvvvvvvvvvvvvvvvvvv %
    tempCMap.ColorData =tempData;
    drawnow;
    humCMap.ColorData =humData;
    drawnow;
    %^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   
    sgtitle(f,['Last Measurements Taken at',datestr(t,'HH:MM:SS PM on ddd., mmm. dd, yyyy')]);
    sgtitle(sevenM,['Last Measurements Taken at',datestr(t,'HH:MM:SS PM on ddd., mmm. dd, yyyy')]);
    sgtitle(threeH,['Last Measurements Taken at',datestr(t,'HH:MM:SS PM on ddd., mmm. dd, yyyy')]);
    sgtitle(twenty4H,['Last Measurements Taken at',datestr(t,'HH:MM:SS PM on ddd., mmm. dd, yyyy')]);

    lookBack7min = sdate-7/1440; %lookBack7min is in days, sdate is in days
    lookBack3h = sdate-3/24; %lookBack3h is in days
    lookBack24h = sdate-1; %lookBack24h is in days
    
    xLFormat = 'HH:MM:SS PM';
    
    %Set the x axis limits for each plot to make sure they update every 15
    %seconds 7 min plots
    
    for z=1:15
        if z==1 || z==2 || z==3 || z==4 || z==13
            hAxes(z).XLim = [lookBack7min sdate];
            xticks(hAxes(z),[lookBack7min lookBack7min+1.75/1440 lookBack7min+3.5/1440 lookBack7min+5.25/1440 sdate]);
        elseif z==5 || z==6 || z==7 ||z==8 || z==14
            hAxes(z).XLim = [lookBack3h sdate];
            xticks(hAxes(z), [lookBack3h lookBack3h+.75/24 lookBack3h+1.5/24 lookBack3h+2.25/24  sdate]);
        elseif z==9 || z==10 || z==11 || z==12 ||z==15
            hAxes(z).XLim = [lookBack24h sdate];
            xticks(hAxes(z), [lookBack24h lookBack24h+6/24 lookBack24h+12/24 lookBack24h+18/24 sdate]);
        end
        datetick(hAxes(z),'x',xLFormat,'keeplimits','keepticks');
    end
    
    %vvvv preallocate arrays if this is the first time adding data to
    %animated lines vvvvvvvvvv
    
    if x==0
        
        tYest=t-hours(24);

yearT = year(t);

monthT = month(t);

dayT = day(t);

 

yearY = year(tYest);

monthY = month(tYest);

dayY = day(tYest);

 

yearT=num2str(yearT);

monthT=num2str(monthT);

dayT=num2str(dayT);

 

yearY=num2str(yearY);

monthY=num2str(monthY);

dayY=num2str(dayY);

 

if strlength(dayT)<=1

    dayT=append('0' , dayT);

end

 

if strlength(dayY)<=1

    dayY=append('0' , dayY);

end

 

if strlength(monthT)<=1

    monthT=append('0' , monthT);

end

 

if strlength(monthY)<=1

    monthY=append('0' , monthY);

end

 

fileT = strcat(yearT , monthT , dayT ,'.csv');

fileY = strcat(yearY , monthY , dayY ,'.csv');


todaysData= webread(strcat('http://',IPAdress,'/',fileT));
yestData=webread(strcat('http://',IPAdress,'/',fileY));

durT=duration(todaysData{:,1});%get time data
durY=duration(yestData{:,1});% get time data

%vvvvvv convert tables to matrices vvvvvvv
todaysData(:,1)=[]; %delete time stamp to be able to convert to matrix

todaysData = table2cell(todaysData);
todaysData=cell2mat(todaysData);

yestData(:,1)=[]; %delete time stamp to be able to convert to matrix

yestData = table2cell(yestData);
yestData=cell2mat(yestData);
dataTot=vertcat(yestData,todaysData);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

timeTot = datetime(dataTot(:,97),'ConvertFrom','epochtime'); %convert unix time array to datetime array

dateTimeTot=datenum(timeTot);
dateTimeNow=datenum(t); 
 
q=1;
sz7=32;
timePreA7=NaN(1,sz7);
temp7=NaN(sz7,8);
hum7=NaN(sz7,8);
press7=NaN(sz7,8);
accelX7=NaN(sz7,8);
accelY7=NaN(sz7,8);
accelZ7=NaN(sz7,8);

for ii=1:size(dateTimeTot,1)
    if (dateTimeNow-dateTimeTot(ii))<= 10*(1/60)*(1/24) %10 min converted to days
        timePreA7(q)=dateTimeTot(ii);
        
        %Now attempt to preallocate data
        tt=1;
        hh=2;
        pp=3;
        axx=4;
        ayy=5;
        azz=6;

        for i = 1:8
            temp7(q,i)=dataTot(ii,tt); 
            hum7(q,i)=dataTot(ii,hh);
            press7(q,i)=dataTot(ii,pp);
            accelX7(q,i)=dataTot(ii,axx);
            accelY7(q,i)=dataTot(ii,ayy);
            accelZ7(q,i)=dataTot(ii,azz);
  
             tt=tt+12;
             hh=hh+12;
             pp=pp+12;
            axx=axx+12;
            ayy=ayy+12;
            azz=azz+12;
        end
        q=q+1;
        
    end
end

sz3h=600;
timePreA3h=NaN(1,sz3h);
temp3=NaN(sz3h,8);
hum3=NaN(sz3h,8);
press3=NaN(sz3h,8);
accelX3=NaN(sz3h,8);
accelY3=NaN(sz3h,8);
accelZ3=NaN(sz3h,8);
q=1;
for ii=1:size(dateTimeTot,1)
    if (dateTimeNow-dateTimeTot(ii))<= 3.1*(1/24) %3.1h converted to days
        timePreA3h(q) = dateTimeTot(ii);
        
        %Now attempt to preallocate data
        tt=1;
        hh=2;
        pp=3;
        axx=4;
        ayy=5;
        azz=6;
        

        for i = 1:8
            temp3(q,i)=dataTot(ii,tt); 
            hum3(q,i)=dataTot(ii,hh);
            press3(q,i)=dataTot(ii,pp);
            accelX3(q,i)=dataTot(ii,axx);
            accelY3(q,i)=dataTot(ii,ayy);
            accelZ3(q,i)=dataTot(ii,azz);
  
             tt=tt+12;
             hh=hh+12;
             pp=pp+12;
            axx=axx+12;
            ayy=ayy+12;
            azz=azz+12;
        end
        q=q+1;
    end
end

sz24h=5300;
timePreA24h=NaN(1,sz24h);
temp24=NaN(sz24h,8);
hum24=NaN(sz24h,8);
press24=NaN(sz24h,8);
accelX24=NaN(sz24h,8);
accelY24=NaN(sz24h,8);
accelZ24=NaN(sz24h,8);
q=1;
for ii=1:size(dateTimeTot,1)
    if (dateTimeNow-dateTimeTot(ii))<= 1.1  %look back 1.1 day
        timePreA24h(q)=dateTimeTot(ii);
        %Now attempt to preallocate data
        tt=1;
        hh=2;
        pp=3;
        axx=4;
        ayy=5;
        azz=6;

        for i = 1:8
            temp24(q,i)=dataTot(ii,tt); 
            hum24(q,i)=dataTot(ii,hh);
            press24(q,i)=dataTot(ii,pp);
            accelX24(q,i)=dataTot(ii,axx);
            accelY24(q,i)=dataTot(ii,ayy);
            accelZ24(q,i)=dataTot(ii,azz);
  
             tt=tt+12;
             hh=hh+12;
             pp=pp+12;
            axx=axx+12;
            ayy=ayy+12;
            azz=azz+12;
        end
        
        q=q+1;
    end
end

%vvvvvvvvvvvv Load the pre existing data to the animated lines vvvvvvvvvvv

for z = 1:8
addpoints(h(z),timePreA7,hum7(:,z)) %humidity 7 min animated line
addpoints(t7(z),timePreA7,temp7(:,z)) %temp 7 min animated line
addpoints(p(z),timePreA7,press7(:,z)) %press 7 min animated line
addpoints(ax(z),timePreA7,accelX7(:,z)) %press 7 min animated line
addpoints(ay(z),timePreA7,accelY7(:,z)) %press 7 min animated line
addpoints(az(z),timePreA7,accelZ7(:,z)) %press 7 min animated line

addpoints(hH3(z),timePreA3h,hum3(:,z)) %humidity 3h animated line
addpoints(tH3(z),timePreA3h,temp3(:,z)) %temp 3h animated line
addpoints(pH3(z),timePreA3h,press3(:,z)) %press 3h animated line
addpoints(axH3(z),timePreA3h,accelX3(:,z)) %press 3h animated line
addpoints(ayH3(z),timePreA3h,accelY3(:,z)) %press 3h animated line
addpoints(azH3(z),timePreA3h,accelZ3(:,z)) %press 3h animated line

addpoints(hH24(z),timePreA24h,hum24(:,z)) %humidity 24h animated line
addpoints(tH24(z),timePreA24h,temp24(:,z)) %temp 24h animated line
addpoints(pH24(z),timePreA24h,press24(:,z)) %press 24h animated line
addpoints(axH24(z),timePreA24h,accelX24(:,z)) %press 24h animated line
addpoints(ayH24(z),timePreA24h,accelY24(:,z)) %press 24h animated line
addpoints(azH24(z),timePreA24h,accelZ24(:,z)) %press 24h animated line

%vvvvv add in code for formatting y-axes vvvvvvvvvvvv

hData7 = [hData7, transpose(hum7(:,z))]; %Holds y data from all animated lines for 7 min humidity
hData3h = [hData3h, transpose(hum3(:,z))]; %Holds y data from all animated lines for 3h humidity
hData24h = [hData24h, transpose(hum24(:,z))]; %Holds y data from all animated lines for 24h humidity
tData7= [tData7,transpose(temp7(:,z)) ]; %Holds y data from all animated lines for 7 min temp
tData3h = [tData3h,  transpose(temp3(:,z))]; %Holds y data from all animated lines for 3h temp
tData24h = [tData24h, transpose(temp24(:,z))]; %Holds y data from all animated lines for 24h temp
pData7= [pData7, transpose(press7(:,z))]; %Holds y data from all animated lines for 7 min press
pData3h = [pData3h, transpose(press3(:,z))]; %Holds y data from all animated lines for 3h press
pData24h = [pData24h, transpose(press24(:,z))]; %Holds y data from all animated lines for 24h press
aData7= [aData7,  transpose(accelX7(:,z)),transpose(accelY7(:,z))]; %Holds y data from all animated lines for 7 min accel x,y, and z
aData3h = [aData3h,  transpose(accelX3(:,z)),transpose(accelY3(:,z))]; %Holds y data from all animated lines for 3h accel x,y, and z
aData24h = [aData24h, transpose(accelX24(:,z)),transpose(accelY24(:,z))]; %Holds y data from all animated lines for 24h accel x,y, and z

aZData7= [aZData7,  transpose(accelZ7(:,z))]; %Holds y data from all animated lines for 7 min accel x,y, and z
aZData3h = [aZData3h, transpose(accelZ3(:,z))]; %Holds y data from all animated lines for 3h accel x,y, and z
aZData24h = [aZData24h, transpose(accelZ24(:,z))]; %Holds y data from all animated lines for 24h accel x,y, and z

%^^^^^end of code for formatting y-axes ^^^^^^^^^^^

end

%^^^^^^^^ end of code for pre loading the data to the animated lines ^^^^^ 

        x=2;
    end
    
    %^^^^^^^^^ end of preallocating animated lines ^^^^^^

    for z=1:8
         q=z+1;
        %Code for formatting the y-axes
        hData7 = [hData7, double(dataCurrTime(q,3))]; %Holds y data from all animated lines for 7 min humidity
        hData3h = [hData3h, double(dataCurrTime(q,3))]; %Holds y data from all animated lines for 3h humidity
        hData24h = [hData24h, double(dataCurrTime(q,3))]; %Holds y data from all animated lines for 24h humidity
        tData7= [tData7, double(dataCurrTime(q,2))]; %Holds y data from all animated lines for 7 min temp
        tData3h = [tData3h, double(dataCurrTime(q,2))]; %Holds y data from all animated lines for 3h temp
        tData24h = [tData24h, double(dataCurrTime(q,2))]; %Holds y data from all animated lines for 24h temp
        pData7= [pData7, double(dataCurrTime(q,4))]; %Holds y data from all animated lines for 7 min press
        pData3h = [pData3h, double(dataCurrTime(q,4))]; %Holds y data from all animated lines for 3h press
        pData24h = [pData24h, double(dataCurrTime(q,4))]; %Holds y data from all animated lines for 24h press
        aData7= [aData7, double(dataCurrTime(q,5)),double(dataCurrTime(q,6)) ]; %Holds y data from all animated lines for 7 min accel x,y, and z
        aData3h = [aData3h,  double(dataCurrTime(q,5)),double(dataCurrTime(q,6))]; %Holds y data from all animated lines for 3h accel x,y, and z
        aData24h = [aData24h, double(dataCurrTime(q,5)),double(dataCurrTime(q,6))]; %Holds y data from all animated lines for 24h accel x,y, and z
        
        aZData7= [aZData7, double(dataCurrTime(q,7))]; %Holds y data from all animated lines for 7 min accel x,y, and z
        aZData3h = [aZData3h, double(dataCurrTime(q,7))]; %Holds y data from all animated lines for 3h accel x,y, and z
        aZData24h = [aZData24h, double(dataCurrTime(q,7))]; %Holds y data from all animated lines for 24h accel x,y, and z

        
        addpoints(h(z),sdate,double(dataCurrTime(q,3))); %Add points to humidity 7 min plot 
        if z==8 
       legend(hAxes(1),'Sensor A1', 'Sensor A2','Sensor A3', 'Sensor A4','Sensor B1', 'Sensor B2',...
        'Sensor B3', 'Sensor B4','Location','southwest');
        end
        addpoints(hH3(z),sdate,double(dataCurrTime(q,3))); %Add points to 3h humidity plot
        if z==8 
       legend(hAxes(5),'Sensor A1', 'Sensor A2','Sensor A3', 'Sensor A4','Sensor B1', 'Sensor B2',...
        'Sensor B3', 'Sensor B4','Location','southwest');
        end
        addpoints(hH24(z),sdate,double(dataCurrTime(q,3))); %Add points to 24h humidity plot
         if z==8  
       legend(hAxes(9),'Sensor A1', 'Sensor A2','Sensor A3', 'Sensor A4','Sensor B1', 'Sensor B2',...
        'Sensor B3', 'Sensor B4','Location','southwest');
         end
         addpoints(t7(z),sdate,double(dataCurrTime(q,2)));     %Add points to temperature  7 min plot
         addpoints(tH3(z),sdate,double(dataCurrTime(q,2))); %Add points to temperature 3h plot
         addpoints(tH24(z),sdate,double(dataCurrTime(q,2))); %Add points to temp 24h plot
          addpoints(p(z),sdate,double(dataCurrTime(q,4))); %Add points to press 7m plot
           addpoints(pH3(z),sdate,double(dataCurrTime(q,4))); %Add points to press 3h plot
            addpoints(pH24(z),sdate,double(dataCurrTime(q,4))); %Add points to press 24h plot
            addpoints(ax(z),sdate,double(dataCurrTime(q,5))); %Add points to accel x 7m plot
            addpoints(axH3(z),sdate,double(dataCurrTime(q,5))); %Add points to accel x 3h plot
            addpoints(axH24(z),sdate,double(dataCurrTime(q,5))); %Add points to accel x 24h plot
            addpoints(ay(z),sdate,double(dataCurrTime(q,6))); %Add points to accel y 7m plot
            addpoints(ayH3(z),sdate,double(dataCurrTime(q,6))); %Add points to accel y 3h plot
            addpoints(ayH24(z),sdate,double(dataCurrTime(q,6))); %Add points to accel y 24h plot
            addpoints(az(z),sdate,double(dataCurrTime(q,7))); %Add points to accel z 7m plot
            addpoints(azH3(z),sdate,double(dataCurrTime(q,7))); %Add points to accel z 3h plot
            addpoints(azH24(z),sdate,double(dataCurrTime(q,7))); %Add points to accel z 24h plot
    end
    pctScrn = .15; %to multiply the range by to add x% of the range to the Ylim max and subtract x% of the range from the Ylim min
    rangeH7= max(hData7)-min(hData7); %ie if pctScrn =.1, then the lines from the sensors take up 80% of the screen
    rangeHh3= max(hData3h)-min(hData3h);
    rangeHh24 = max(hData24h)-min(hData24h);
        rangeT7= max(tData7)-min(tData7);
    rangeTh3= max(tData3h)-min(tData3h);
    rangeTh24 = max(tData24h)-min(tData24h);
        rangeP7= max(pData7)-min(pData7);
    rangePh3= max(pData3h)-min(pData3h);
    rangePh24 = max(pData24h)-min(pData24h);
        rangeA7= max(aData7)-min(aData7);
    rangeAh3= max(aData3h)-min(aData3h);
    rangeAh24 = max(aData24h)-min(aData24h);
    
    rangeAZ7=max(aZData7)-min(aZData7);
    rangeAZh3=max(aZData3h)-min(aZData3h);
    rangeAZh24=max(aZData24h)-min(aZData24h);
    
    hAxes(1).YLim = [min(hData7)-rangeH7*pctScrn max(hData7)+rangeH7*pctScrn];%Constantly reformat 7 min y axes so they always fit all of the data
    hAxes(2).YLim = [min(tData7)-rangeT7*pctScrn max(tData7)+rangeT7*pctScrn];
    hAxes(3).YLim = [min(pData7)-rangeP7*pctScrn max(pData7)+rangeP7*pctScrn];
    hAxes(4).YLim = [min(aData7)-rangeA7*pctScrn max(aData7)+rangeA7*pctScrn];
        hAxes(5).YLim = [min(hData3h)-rangeHh3*pctScrn max(hData3h)+rangeHh3*pctScrn]; %Constantly reformat 3h y axes so they always fit all of the data
    hAxes(6).YLim = [min(tData3h)-rangeTh3*pctScrn max(tData3h)+rangeTh3*pctScrn];
    hAxes(7).YLim = [min(pData3h)-rangePh3*pctScrn max(pData3h)+rangePh3*pctScrn];
    hAxes(8).YLim = [min(aData3h)-rangeAh3*pctScrn max(aData3h)+rangeAh3*pctScrn];
         hAxes(9).YLim = [min(hData24h)-rangeHh24*pctScrn max(hData24h)+rangeHh24*pctScrn]; %Constantly reformat 24h y axes so they always fit all of the data
    hAxes(10).YLim = [min(tData24h)-rangeTh24*pctScrn max(tData24h)+rangeTh24*pctScrn];
    hAxes(11).YLim = [min(pData24h)-rangePh24*pctScrn max(pData24h)+rangePh24*pctScrn];
    hAxes(12).YLim = [min(aData24h)-rangeAh24*pctScrn max(aData24h)+rangeAh24*pctScrn];
    
    hAxes(13).YLim=[min(aZData7)-rangeAZ7*pctScrn max(aZData7)+rangeAZ7*pctScrn];
    hAxes(14).YLim=[min(aZData3h)-rangeAZh3*pctScrn max(aZData3h)+rangeAZh3*pctScrn];
    hAxes(15).YLim=[min(aZData24h)-rangeAZh24*pctScrn max(aZData24h)+rangeAZh24*pctScrn];
 drawnow;
 
     if length(hData7)>=28*8 %Delete 1st array element if it has 28*8 elements for 7 min plots
         hData7(1:8) = [];
         tData7(1:8) = [];
         pData7(1:8) = [];
         aData7(1:2*8) = [];
         aZData7(1:8) = [];
     end
      
     if length(hData3h)>=720*8 %Delete 1st array element if it has 720*8 elements for 3h plots
         hData3h(1:8) = [];
         tData3h(1:8) = [];
         pData3h(1:8) = [];
         aData3h(1:2*8) = [];
         aZData3h(1:8) = [];
     end
     
      if length(hData24h)>=5760*8 %Delete 1st array element if it has 5760*8 elements for 24h plots
         hData24h(1:8) = [];
         tData24h(1:8) = [];
         pData24h(1:8) = [];
         aData24h(1:2*8) = [];
         aZData24h(1:8) = [];
      end

    timerVal = tic; %reset the time so elapsed time resets to 0 seconds
end
end