%{

 
 *  Documentation: https://drive.google.com/drive/folders/1KO-BbYIWLT3vGuHTHezoEGocm-yG4Wc9

 *  Required Hardware Parts List: https://docs.google.com/document/d/1zNLYMNLZTGmoZ9-0ag7mZ5a84KvkOMSjKftjlTZL42o/edit#
 
 *  Instructions for Putting Hardware together: https://docs.google.com/presentation/d/1c655EPxgbJqD-ze0mLTKCqgfO5gB6cGL3y8jaUUU26Q/edit#slide=id.g3fed37a16b_0_40
  

Modified and Created Summer, 2021
by Cole Kappel

This program displays the environmental data from a user
specified start date to a user specified end date

If you call this function and have requested data
that could not be found on the arduino, it will not be plotted and
the names of the files that couldn't be found will be displayed in the
command window.

To use the program:
type: OctoprogramTimeCheckFunc(startYear, startMo, startDay, startHr, endY, endM, endD, endH)
into the command window and press enter to run the program. 

Example: if you want to look at data from August 1st, 2021 at 5pm to August 4th,
 2021 at 3am you would type into the command window:

OctoprogramTimeCheckFunc(2021, 08, 1, 17, 2021, 08, 4, 3).

IMPORTANT: It won't run unless you are in the documents folder/same location as this script!!
%}

function OctoprogramTimeCheckFunc(sY, sM, sD, sH, eY, eM, eD, eH)

IPAdress='192.168.1.3'; %KPIC - define your IP address here. For HCST it should be 192.168.1.3

sMn=0;
sS=0;
eMn=0;
eS=0;

startTime=datetime(sY,sM,sD,sH,sMn,sS);
endTime = datetime(eY,eM,eD,eH,eMn,eS);

%Format is year month day
tt= datetime(sY,sM,sD):datetime(eY,eM,eD);

mNum=month(tt); %Array of months
yNum=year(tt); %Array of years
dNum=day(tt); %Array of days

%vvvvvv change months to 07 if 7 etc... vvvvvvvv
mStr=string(mNum);

lmStr=length(mStr);
m=strings(1,lmStr);
for i = 1:lmStr
    if strlength(mStr(i))==1
        m(i)= append("0",mStr(i));
    else
        m(i)=mStr(i);
    end
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

%vvvvvv change days to 07 if 7 etc... vvvvvvvv
dStr=string(dNum);

ldStr=length(dStr);
d=strings(1,ldStr);
for i = 1:ldStr
    if strlength(dStr(i))==1
        d(i)= append("0",dStr(i));
    else
        d(i)=dStr(i);
    end
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

y=string(yNum); %Convert years to a string
files=strings(1,length(d));
for i=1:length(d)
   files(i)= y(i)+m(i)+d(i)+".csv"; 
end

%Now i need to create an array from all of this data and figure out how to
%start at the specified start hour, now ill do this
z=1;
for i =1:length(files)
    try
        dataD = webread(strcat('http://',IPAdress,'/', files(i)));
    catch
        disp(["Error!: File does not exist: ", files(i)]);
    end
end

for i =1:length(files)
        dataD = webread(strcat('http://',IPAdress,'/', files(i)));
        dur=duration(dataD{:,1});
        
        szDur=size(dur,1);
        b=1;
    
        for pp = z:(z+szDur-1)
            time(pp)=tt(i)+dur(b);
            data(pp,:)=dataD(b,:);
            b=b+1;
        end
    
        z= z+ szDur;
        
end


szTime=size(time,2);
cc=0;
for oo = 1:(szTime-1)
    if time(oo)>time(oo+1)
        disp(" ");
        disp(["Warning!: Data anomaly found in data requested at ",datestr(time(oo))]);
        cc=1;
        break
    end
end

if cc==1
    disp(["      The plots may not reflect the data corresponding to the desired time span"]);
    disp(" ");
end

rowsToDelete = time<startTime;
time(rowsToDelete)=[];
data(rowsToDelete,:)=[];

rowsToDelete2 = time>endTime;
time(rowsToDelete2)=[];
data(rowsToDelete2,:)=[];

data(:,1)=[]; %delete time stamp to be able to convert to matrix

data = table2cell(data);
data=cell2mat(data);

tt=1;
hh=2;
pp=3;
axx=4;
ayy=5;
azz=6;

%preallocate arrays
temp=zeros(size(data,1),8);
hum=zeros(size(data,1),8);
press=zeros(size(data,1),8);
accelX=zeros(size(data,1),8);
accelY=zeros(size(data,1),8);
accelZ=zeros(size(data,1),8);

for i = 1:8
  temp(:,i)=(data(:,tt)); 
  hum(:,i)=(data(:,hh));
  press(:,i)=(data(:,pp));
  accelX(:,i)=(data(:,axx));
  accelY(:,i)=(data(:,ayy));
  accelZ(:,i)=(data(:,azz));
  
  tt=tt+12;
  hh=hh+12;
  pp=pp+12;
  axx=axx+12;
  ayy=ayy+12;
  azz=azz+12;
end

nameOfFig=['Environmental Data from ', datestr(time(1)),' to ', datestr(time(end))];
figure('NumberTitle','off','Name',nameOfFig);
colorArray = ["r","b","g","c","m","y","k","#D95319"];
for i = 1:8
subplot(3,2,1);
plot(time,temp(:,i),'color',colorArray(i))
hold on 
end
xlim([time(1) time(end)]);
title('Temperature vs Time');
xlabel('Army Time');
ylabel('Temperature in Degrees Celsius');
legend('Sensor A1','Sensor A2','Sensor A3', 'Sensor A4',...
    'Sensor B1','Sensor B2','Sensor B3', 'Sensor B4');

for i = 1:8
subplot(3,2,2);
plot(time,hum(:,i),'color',colorArray(i))
hold on 
end
xlim([time(1) time(end)]);
title('Percent Humidity vs Time');
xlabel('Army Time');
ylabel('Percent Humidity (%)');

for i = 1:8
subplot(3,2,3);
plot(time,press(:,i),'color',colorArray(i))
hold on 
end
xlim([time(1) time(end)]);
title('Pressure vs Time');
xlabel('Army Time');
ylabel('Pressure in hPa or millibar');

for i = 1:8
subplot(3,2,4);
plot(time,accelX(:,i),'color',colorArray(i))
hold on 
plot(time,accelY(:,i),'--','color',colorArray(i))
hold on 
end
xlim([time(1) time(end)]);
title('Acceleration vs Time (Ax=solid, Ay=dashed)');
xlabel('Army Time');
ylabel('Acceleration in (m/s^2)');

for i = 1:8
subplot(3,2,5);
plot(time,accelZ(:,i),'color',colorArray(i))
hold on
end
xlim([time(1) time(end)]);
title('Z-Acceleration vs Time');
xlabel('Army Time');
ylabel('Acceleration in (m/s^2)');

%KPIC delete these lines or add a pic of your sensor layout? vvvvvvvvvvv 

SensorLayout= imread('C:\Users\ET\Desktop\HCST_SensorLayout.png'); %Pic of sensor layout
SensorLayoutBg = imresize(SensorLayout,2);
subplot(3,2,6)
imagesc(SensorLayoutBg) %Show the image in the figure
axis off; %Turn of the axis on the image
title('Sensor Layout in the HCST');

%KPIC delete these lines or add a pic of your sensor layout? ^^^^^^^^^^^^

sgtitle(['Measurements Taken from: ',datestr(time(1)), ' to ',datestr(time(end))],...
    'fontweight', 'bold');
end