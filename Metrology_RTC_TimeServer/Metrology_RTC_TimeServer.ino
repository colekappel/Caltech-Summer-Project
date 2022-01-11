/* Environment Sensing
 
 *  Documentation: https://drive.google.com/drive/folders/1KO-BbYIWLT3vGuHTHezoEGocm-yG4Wc9

 *  Required Hardware Parts List: https://docs.google.com/document/d/1zNLYMNLZTGmoZ9-0ag7mZ5a84KvkOMSjKftjlTZL42o/edit#
 
 *  Instructions for Putting Hardware together: https://docs.google.com/presentation/d/1c655EPxgbJqD-ze0mLTKCqgfO5gB6cGL3y8jaUUU26Q/edit#slide=id.g3fed37a16b_0_40
  
   Program to set the RTC time with a time server. If the program doesn't work, use Metrology_RTC_only.ino which doesn't use a time server but you will need to follow complicated instructions to set the time with that program.
   
   For KPIC FIU and HCST-R.
   
   Feather M0 Adalogger w/ Ethernet FeatherWing
   connected via I2C to TCA9548A I2C multiplexer
   Each I2C channel on the mux has one BME680 and one LSM9DS1.
   
   Modified July 2, 2019
   by Grady Morrissey
   
   Modified August 23, 2018
   by Milan Roberson

   Updated in the Summer of 2021 
   by Cole Kappel and Tobias Schofield
   
   Cole's Notes: 

   - Sometimes if the serial port won't open but the sketch is running, you can just unplug the arduino from power and then replug it in to power a couple times to get the serial port back.

   - Make sure to read the documentation.

*/


//A fair amount of this code seems identical to https://github.com/PaulStoffregen/Time/blob/master/examples/TimeNTP/TimeNTP.ino
//-grady


#include "RTClib.h" //added by cole
#include <Wire.h>
#include <Adafruit_BME680.h>
#include <Adafruit_LSM9DS1.h>
#include <SPI.h>
//#include <Ethernet2.h>
#include <Ethernet.h>
#include <SdFat.h>
#include <TimeLib.h>
#include <avr/dtostrf.h>
#include <math.h>

#define _TASK_PRIORITY
#define _TASK_WDT_IDS
#include <TaskScheduler.h>

#define MUXADDR 0x74

#define NUMPORTS 8

#define CADENCE_SECONDS 1
// Cadence at which to save data to the sd card. Time in milliseconds (s * 1000)
#define SAVE_CADENCE 15000

RTC_DS3231 rtc;

//needed for saving data every 15 seconds
int startTime = millis();

// uncomment #define DEBUG to get prints for debugging.
//BUT keep  #define DEBUG commented when you're ready to run the debugged program! If you uncomment and then run and powercycle the program, then the program will crash.
//if you keep it commented then the power can be disconnected and reconnected wihout killing the program.
//#define DEBUG //IMPORTANT  ^^^ make sure you read the above notes!! ^^^

//#define SETTIME //uncomment to set the time on the arduino. Note that no data will be saved if you uncomment it.

#ifdef DEBUG
#define Sprint(a) (Serial.print(a))
#define Sprintln(a) (Serial.println(a))
#define Sbegin(a) {Serial.begin(a); while (!Serial) delay(1000);}
#else
#define Sprint(a)  (Serial.print(a))
#define Sprintln(a) (Serial.println(a))
#define Sbegin(a) Serial.begin(a)
#endif

Adafruit_BME680 bme[NUMPORTS];
Adafruit_LSM9DS1 lsm[NUMPORTS];

// Web server globals.
// mac addresss is unique to every Ethernet FeatherWing.
uint8_t mac[] = {0x98, 0x76, 0xB6, 0x10, 0xB4, 0x1A}; //commented by cole to test whether a different mac address should be used

/* NTP code */
const int NTP_PACKET_SIZE = 48; // NTP time is in the first 48 bytes of message
byte packetBuffer[NTP_PACKET_SIZE]; //buffer to hold incoming & outgoing packets

EthernetServer server(80);

// NTP globals
// NTP Servers:
//IPAddress timeServer(128, 171, 3, 3); //Keck NTP server - I changed this for you 
 IPAddress timeServer(132, 163, 97, 1); // time-a-www.nist.gov
// IPAddress timeServer(132, 163, 97, 2); // time-b-www.nist.gov
// IPAddress timeServer(132, 163, 97, 3); // time-c-www.nist.gov

//Define time zone and time zone string - make sure to uncomment the corresponding time zone string too or the program won't run! vvvvvvvvvvvvvvvvvvv

// const int timeZone = -8;  // Pacific Standard Time PST (USA)
//char timeZoneSTR[] ="PST";

const int timeZone = -7;  // Pacific Daylight Time PDT (USA) (california)
char timeZoneSTR[] ="PDT"; 

// const int timeZone = -10; // Hawaii Standard Time (USA)
//char timeZoneSTR[] ="Hawaii Standard Time";

//const int timeZone = 0; // UTC
//char timeZoneSTR[] ="UTC";

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


EthernetUDP Udp;
const unsigned int localPort = 8888;

// Data is held here
bool isSetUp[NUMPORTS];
float temps[NUMPORTS];
float hums[NUMPORTS];
float pressure[NUMPORTS];
float accx[NUMPORTS];
float accy[NUMPORTS];
float accz[NUMPORTS];
float gyrox[NUMPORTS];
float gyroy[NUMPORTS];
float gyroz[NUMPORTS];
float magx[NUMPORTS];
float magy[NUMPORTS];
float magz[NUMPORTS];

// SD card stuff
#define cardSelect 4

char rootFileName[] = "index.htm";

SdFat card;
SdFile file;

void handleRequest();
void takeMeasurements();

//Grady Note
Scheduler r, hpr;
Task serve(TASK_SECOND / 2, TASK_FOREVER, &handleRequest, &r);
//Task serve(TASK_SECOND / 2, 1, &handleRequest, &r);
Task sense(TASK_SECOND * CADENCE_SECONDS, TASK_FOREVER, &takeMeasurements, &hpr);

void tcaselect(uint8_t i) {
  if (i > 7) return;

  Wire.beginTransmission(MUXADDR);
  Wire.write(1 << i);
  Wire.endTransmission();
}

void printHeader(Print &f) {
  
  char text[141];
  digitalWrite(8, HIGH); // turns LED on
  //Grady Note - print filename with /now to easily find filename
  DateTime t = DateTime(rtc.now());
  char fnow[15];
  getFileName(fnow, t);
  f.write(fnow);
  //f.write("# Time"); //unneccessary line 
  for (uint8_t i = 0; i < NUMPORTS; i++) {
    snprintf(text, 140, ", Temp %d, Humidity %d, Pressure %d, Accel X %d, Accel Y %d, Accel Z %d, Gyro X %d, Gyro Y %d, Gyro Z %d, Mag X %d, Mag Y %d, Mag Z %d", i, i, i, i, i, i, i, i, i, i, i, i);
    f.write(text);
  }
  f.write(", Unix Time Stamp"); //code added by cole
  f.write("\n# Time Zone is "); 
  f.write(timeZoneSTR); // added by cole on 8/16 to display current time zone in header
  f.write(", Temp is *C, Humidity is %, Pressure is hPa or millibar, Accel is m/s^2, Gyro is degrees/s, Mag is gauss\n");
  digitalWrite(8, LOW);
}

//This is where the header is written
//Grady Note - this should return the current time, but the time() function returns 0 so year is displayed as 2106
void getFileName(char *filename, DateTime t) {
  snprintf(filename, 13, "%04d%02d%02d.csv", t.year(), t.month(), t.day());
}

void writeData(Print &f) {
  //for error testing vvvvvvvvvvv show the current RTC time in the serial port when data is written to the file
    DateTime t = DateTime(rtc.now());
    Serial.print("Data written to file with the following time stamp: yyyy/mm/dd hh:mm:ss: ");
    Serial.print(t.year(), DEC);
    Serial.print("/");
    Serial.print(t.month(), DEC);
    Serial.print("/");
    Serial.print(t.day(), DEC);
    Serial.print(" ");
    Serial.print(t.hour(), DEC);
    Serial.print(':');
    Serial.print(t.minute(), DEC);
    Serial.print(':');
    Serial.print(t.second(), DEC);
    Serial.println();

  //for error testing ^^^^^^^^^^^


  
  char data[11];
  data[0] = '\0'; // make sure our string is initialized empty

  digitalWrite(8, HIGH); // turns LED on

  snprintf(data, 10, "%02d:%02d:%02d", t.hour(), t.minute(), t.second());
  f.write(data);
  for (uint8_t i = 0; i < NUMPORTS; i++) {
    f.write(",");
    dtostrf(temps[i], 6, 2, data);
    f.write(data);
    f.write(",");
    dtostrf(hums[i], 5, 2, data);
    f.write(data);
    f.write(",");
    dtostrf(pressure[i], 6, 2, data);
    f.write(data);
    f.write(",");
    dtostrf(accx[i], 6, 3, data);
    f.write(data);
    f.write(",");
    dtostrf(accy[i], 6, 3, data);
    f.write(data);
    f.write(",");
    dtostrf(accz[i], 6, 3, data);
    f.write(data);
    f.write(",");
    dtostrf(gyrox[i], 6, 2, data);
    f.write(data);
    f.write(",");
    dtostrf(gyroy[i], 6, 2, data);
    f.write(data);
    f.write(",");
    dtostrf(gyroz[i], 6, 2, data);
    f.write(data);
    f.write(",");
    dtostrf(magx[i], 6, 3, data);
    f.write(data);
    f.write(",");
    dtostrf(magy[i], 6, 3, data);
    f.write(data);
    f.write(",");
    dtostrf(magz[i], 6, 3, data);
    f.write(data);
  }
  
  //added code by cole to get the unix time stamp for preallocating previous data with MATLAB programs
  dtostrf(rtc.now().unixtime(), 6, 3, data);
  f.write(",");
  f.write(data);
  // end of added code
  
  f.write("\n");
  digitalWrite(8, LOW);
}

void setup() {

  // put your setup code here, to run once:
  // for debugging
  Sbegin(9600); //so if debug is defined - the program waits to connect to the serial port to print to it. If not it doesn't.


    //check that rtc is connected
    if (! rtc.begin()) {
    while (!Serial) delay(1000); // wait to connect to serial port because this is important
    Serial.println("Couldn't find RTC");
    // NOTE: this infinite loop, this program WILL NOT RUN
    //  without an rtc attached
    while (1);
  }

 
//code to set time on the arduino vvvvv only runs if #define SETTIME is uncommented
#ifdef SETTIME
  // start Ethernet and UDP
  while(!Serial); //wait to connect to the serial port
  if (Ethernet.begin(mac) == 0) {
    Serial.println("Failed to configure Ethernet using DHCP");
    // Check for Ethernet hardware present
    if (Ethernet.hardwareStatus() == EthernetNoHardware) {
      Serial.println("Ethernet shield was not found.  Sorry, can't run without hardware. :(");
    } else if (Ethernet.linkStatus() == LinkOFF) {
      Serial.println("Ethernet cable is not connected.");
    }
    // no point in carrying on, so do nothing forevermore:
    while (true) {
      delay(1);
    }
  }

  Serial.println("started");

  // Set up NTP
  Udp.begin(localPort);

  Serial.println("hi");
  unsigned long tInit = getNtpTime();
  Serial.println(tInit);
  
  if(tInit != 0){
  time_t t= time_t(tInit);
  
  rtc.adjust( DateTime(year(t), month(t), day(t), hour(t), minute(t),second(t)) ); 
  
  Sprintln("RTC time set");
  }
  else{
    Serial.println("Error setting the time");
  }
//vv create infinite loop that only displays current arduino time
  while(1){
    DateTime t = DateTime(rtc.now());
    Serial.print("Current RTC Time: yyyy/mm/dd hh:mm:ss: ");
    Serial.print(t.year(), DEC);
    Serial.print("/");
    Serial.print(t.month(), DEC);
    Serial.print("/");
    Serial.print(t.day(), DEC);
    Serial.print(" ");
    Serial.print(t.hour(), DEC);
    Serial.print(':');
    Serial.print(t.minute(), DEC);
    Serial.print(':');
    Serial.print(t.second(), DEC);
    Serial.println();
    Serial.println();
    delay(3000);
  }
  //^^^ end of infinite loop
  
  #endif
  //end of code to set time on arduino ^^^^^^^^^^^^
 
  // Set up communication with Mux
  Wire.begin();
  Sprintln("I2C mux scanner ready");

  // Check that sensors are connected
  for (uint8_t t = 0; t < NUMPORTS; t++) {
    tcaselect(t);
    Sprint("mux port #"); Sprintln(t);
    if (bme[t].begin()) {
      bme[t].setGasHeater(0, 0); // disable gas reading

      lsm[t].begin();
      isSetUp[t] = true;
      Sprint("Setting up sensors "); Sprintln(t);
    } else {
      isSetUp[t] = false;
      Sprint("Failed to set up sensor "); Sprintln(t); //line added by cole for debugging
    }
  }
  
  // Needed for Ethernet
  pinMode(13, OUTPUT);
  pinMode(8, OUTPUT);

  // Set up SD card
  pinMode(10, OUTPUT);
  digitalWrite(10, HIGH);
  if (!card.begin(cardSelect, SPI_FULL_SPEED)) {
    Sprintln("card.init failed");
    setup();
  } else {
    card.vwd()->rewind();
    card.chdir();
    Sprintln("Files found in root:");
#ifdef DEBUG
    card.ls(LS_DATE | LS_SIZE);
    Sprintln();
    Sprintln("Files found in all dirs:");
    card.ls(LS_R);
    Sprintln();
    Sprintln("Done");
#endif

    file.open("config.txt", O_READ);
    char ip_s[25];

    file.read(ip_s, 12);
    if (ip_s[11] == '1') {
      // read in string
      file.read(ip_s, 24);
      IPAddress gateway;
      gateway.fromString((ip_s + 9));

      file.read(ip_s, 24);
      IPAddress subnet;
      subnet.fromString((ip_s + 9));

      file.read(ip_s, 20);
      IPAddress ip;
      ip_s[20] = '\0';
      ip.fromString((ip_s + 5));
      Ethernet.begin(mac, ip, gateway, subnet);
    } else {
      Ethernet.begin(mac);
    }
    
    file.close();
  }

  server.begin();
  Sprint("server is at "); Sprintln(Ethernet.localIP()); //line to show website/IP data is uploaded to DEBUG must be uncommenter

  r.setHighPriorityScheduler(&hpr);
  r.enableAll(true);

  r.execute();
}

void loop() {
  r.execute();
  // since we're using a task manager, we don't need anything in our loop

}

// send an NTP request to the time server at the given address
void sendNTPpacket(IPAddress address) {
  // set all bytes in the buffer to 0
  memset(packetBuffer, 0, NTP_PACKET_SIZE);
  // Initialize values needed to form NTP request
  // (see URL above for details on the packets)
  packetBuffer[0] = 0b11100011;   // LI, Version, Mode
  packetBuffer[1] = 0;     // Stratum, or type of clock
  packetBuffer[2] = 6;     // Polling Interval
  packetBuffer[3] = 0xEC;  // Peer Clock Precision
  // 8 bytes of zero for Root Delay & Root Dispersion
  packetBuffer[12]  = 49;
  packetBuffer[13]  = 0x4E;
  packetBuffer[14]  = 49;
  packetBuffer[15]  = 52;

  // all NTP fields have been given values, now
  // you can send a packet requesting a timestamp:
  if(Udp.beginPacket(address, 123) == 1){
    Serial.println("packet made");
    Udp.write(packetBuffer, NTP_PACKET_SIZE);
    Serial.println("packet sent");
    if (Udp.endPacket() != 1) {
      Serial.println("Error sending UDP packet");
    }
  } else {
    Serial.println("Error sending packet");
  }
  Serial.println("done");
}

unsigned long getNtpTime() {
  while (Udp.parsePacket() > 0) ; // discard any previously received packets
  Serial.println("Transmit NTP Request");
  sendNTPpacket(timeServer);
  uint32_t beginWait = millis();
  while (millis() - beginWait < 1500) {
    if (Udp.parsePacket()) {
      Serial.println("Receive NTP Response");
      Udp.read(packetBuffer, NTP_PACKET_SIZE);
      unsigned long secsSince1900;
      // convert four bytes starting at location 40 to a long integer
      unsigned long highWord = word(packetBuffer[40], packetBuffer[41]);
      unsigned long lowWord = word(packetBuffer[42], packetBuffer[43]);
      secsSince1900 = highWord << 16 | lowWord;
      return secsSince1900 - 2208988800UL + timeZone * 3600;
    }
  }
  Serial.println("No NTP Response :-(");
  return 0; // return 0 if unable to get the time
}

void takeMeasurements() {
  DateTime t = DateTime(rtc.now());
  for (uint8_t i = 0; i < NUMPORTS; i++) {
    tcaselect(i);
    if (!isSetUp[i] && bme[i].begin()) {
      bme[i].setGasHeater(0, 0); // disable gas reading
      lsm[i].begin();
    }
    isSetUp[i] = bme[i].performReading();
    if (isSetUp[i]) {
      temps[i] = bme[i].temperature;
      hums[i] = bme[i].humidity;
      pressure[i] = bme[i].pressure / 100; // convert Pa to hPa

      lsm[i].read();
      sensors_event_t a, m, g, temp;
      lsm[i].getEvent(&a, &m, &g, &temp);
      accx[i] = a.acceleration.x;
      accy[i] = a.acceleration.y;
      accz[i] = a.acceleration.z;

      magx[i] = m.magnetic.x;
      magy[i] = m.magnetic.y;
      magz[i] = m.magnetic.z;

      gyrox[i] = g.gyro.x;
      gyroy[i] = g.gyro.y;
      gyroz[i] = g.gyro.z;
    } else {
      temps[i] = NAN;
      hums[i] = NAN;
      pressure[i] = NAN;

      accx[i] = NAN;
      accy[i] = NAN;
      accz[i] = NAN;

      magx[i] = NAN;
      magy[i] = NAN;
      magz[i] = NAN;

      gyrox[i] = NAN;
      gyroy[i] = NAN;
      gyroz[i] = NAN;
    }
  }

  // append to today's file
  char filename[13];
  getFileName(filename, t);
  file.close();
  if (!file.open(filename, O_WRITE | O_APPEND)) {
    file.open(rootFileName, O_WRITE);
    file.seekEnd(-25);
    file.write("<tr>\n<td><a href='");
    file.write(filename);
    file.write("'>");
    file.write(filename);
    file.write("</a></td>\n<td>");
    snprintf(filename, 11, "%04d-%02d-%02d", t.year(), t.month(), t.day());
    file.write(filename);
    file.write("</td>\n</tr>\n</table>\n</body>\n</html>");
    file.close();
    getFileName(filename, t);

    file.open(filename, O_CREAT | O_WRITE | O_APPEND);
    printHeader(file);
  }
  //Grady note - here is where save interval is determined

  //Write data to file every SAVE_CADENCE/1000 seconds
  if ( (millis()-startTime) >= SAVE_CADENCE ) {
    writeData(file);
    startTime=millis();
  }

  file.sync();
  file.close();

}

void handleRequest() {
  Ethernet.maintain();
  EthernetClient client = server.available();
  if (client) {
    uint8_t bufindex = 0;
    const uint8_t maxbyte = 255;
    uint8_t buf[maxbyte];

    char *filename;
    char c;

    Sprintln("new client");
    while (client.connected()) {
      if (client.available()) {
        c = client.read();
        Sprint(c);
        if (c != '\n' && c != '\r') {
          buf[bufindex++] = c;
          if (bufindex >= maxbyte) {
            bufindex--;
          }
          continue;
        }
        buf[bufindex] = 0;
        filename = 0;
        Sprintln();
        Sprintln((char *)buf);
        if (strstr((char *)buf, "GET / ") != 0 || strstr((char *)buf, "HEAD / ") != 0) {
          filename = rootFileName;
        }
        if (strstr((char *)buf, "GET /") != 0 || strstr((char *)buf, "HEAD /") != 0) {
          if (strstr((char *)buf, "GET /now") != 0) {
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type: text/csv");
            // client.println("Content-type: text/plain");
            client.println("Connection: close");
            client.println();
            //grady Note
            printHeader(client);
            writeData(client);
          } else if (strstr((char *)buf, "GET /start") != 0) {
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type: text/plain");
            client.println("Connection: close");
            client.println();
            sense.enable();
            client.println("Sensing started.");
          } else if (strstr((char *)buf, "GET /stop") != 0) {
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type: text/plain");
            client.println("Connection: close");
            client.println();
            sense.disable();
            client.println("Sensing stopped.");
          } else if (strstr((char *)buf, "GET /delete") != 0) {
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type: text/plain");
            client.println("Connection: close");
            client.println();
            deleteData();
            client.println("Data deleted.");
          } else {
            if (!filename) filename = (char *)buf + 5;
            (strstr((char *)buf, " HTTP"))[0] = 0;
            Sprintln(filename);
            // card.chdir();
            Sprintln(FreeRam());
            if (! file.open(filename, O_READ)) {
              Sprintln("404 not found");
              client.println("HTTP/1.1 404 Not Found");
              client.println("Content-type: text/html");
              client.println("Connection: close");
              client.println();
              if (strstr((char *)buf, "GET")) {
                file.open("404error.htm", O_READ);
                bufindex = 0;
                while ((bufindex = file.read(buf, maxbyte)) == maxbyte) {
                  client.write(buf, maxbyte);
                }
                file.close();
                client.write(buf, bufindex);
              }
              break;
            } // 404 not found
            client.println("HTTP/1.1 200 OK");
            Sprintln("Opened!");

            if (strstr(filename, ".htm") != 0) {
              client.println("Content-type: text/html");
            } else if (strstr(filename, ".css") != 0) {
              client.println("Content-type: text/css");
            } else if (strstr(filename, ".csv") != 0) {
              client.println("Content-type: text/csv");
            } else if (strstr(filename, ".ico") != 0) {
              client.println("Content-type: image/x-icon");
            } else {
              client.println("Content-type: text/plain");
            }
            client.println("Connection: close");
            client.println();
            if (strstr((char *)buf, "GET")) {
              bufindex = 0;
              while ((bufindex = file.read(buf, maxbyte)) == maxbyte) {
                client.write(buf, maxbyte);
              }
              file.close();
              client.write(buf, bufindex);
            }
            file.close();
          }
        } else {
          client.println("HTTP/1.1 404 Not Found");
          client.println("Content-type: text/html");
          client.println("Connection: close");
          client.println();
          file.open("404error.htm", O_READ);
          bufindex = 0;
          while ((bufindex = file.read(buf, maxbyte)) == maxbyte) {
            client.write(buf, maxbyte);
          }
          file.close();
          client.write(buf, bufindex);
        }
        break;
      }
    }
    delay(1);
    client.stop();
  }
}

void deleteData() {
  char fname[15];
  char cur_fname[15];
  uint8_t buf[255];
  int16_t index;

  SdFile file2;
  card.vwd()->rewind();
  card.chdir();

  DateTime t = DateTime(rtc.now());
  getFileName(cur_fname, t);
  // while there are more files
  while (file.openNext(card.vwd(), O_READ)) {
    file.getName(fname, 15);
    if (strstr(fname, ".csv") != 0) {
      if (strstr(fname, cur_fname) == 0) {
        // if it is a .csv file and it's not the current file we're writing to, delete it.
        file.close();
        card.remove(fname);
      }
    }
    file.close();
  }
  // delete the old index.htm file
  file.open(rootFileName, O_RDWR);
  file.remove();
  file.close();
  file.open(rootFileName, O_WRITE | O_CREAT);
  file2.open("index_ar.htm", O_READ);
  // copy the archived index file to index.htm
  while ((index = file2.read(buf, 255)) == 255) {
    file.write(buf, 255);
  }
  file.write(buf, index);
  // write the current file into the index.
  file.seekEnd(-25);
  file.write("<tr>\n<td><a href='");
  file.write(cur_fname);
  file.write("'>");
  file.write(cur_fname);
  file.write("</a></td>\n<td>");
  snprintf(cur_fname, 11, "%04d-%02d-%02d", t.year(), t.month(), t.day());
  file.write(cur_fname);
  file.write("</td>\n</tr>\n</table>\n</body>\n</html>");
  file.close();
  file2.close();
}



extern "C" char *sbrk(int i);
int FreeRam () {
  char stack_dummy = 0;
  return &stack_dummy - sbrk(0);
}

// TODO: write documentation
