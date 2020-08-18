// Program to talk to GlobalSat EM-506 GPS and lightware SF-11 laser rangefinder
// and log to SparkFun SDcard board.
// HB 14 June 2016

/*
GPS hardware:
 Hardware serial Rx,Tx are on pins 0,1 on the ProMicro, but 'Serial1' already
 knows that.  The serial Rx LED is pin 17 and can be used independently, the
 Tx pin needs to be treated differently- see the ProMicro hookup guide example.

 The GPS doesn't seem to have a long memory and resets its programming after
 being off for a couple days. So it seems that we have to reprogram it at
 startup. I'd like to have it at 19200 baud instead of the default of 4800
 but rerunning Serial1.begin() after reprogramming the baud rate and then
 sleeping for 1 sec doesn't seem to work well and is probably too risky to
 trust anyway.
    Serial1.print("$PSRF100,1,19200,8,1,0*38\r\n");   // set baud rate to 19200, N81
    Serial1.print("$PSRF100,1,9600,8,1,0*0D\r\n");    // set baud rate to 9600, N81
    Serial1.print("$PSRF100,1,4800,8,1,0*0E\r\n");    // set baud rate to 4800, N81

    Serial1.begin(19200);
    delay(1000);


 State machine:  (incompatible with always listening to the GPS stream, see below)
    unsigned long prev_millisec = 0;
    long interval = 1000;
    ...
    unsigned long current_millisec;
    // wait a minimum of 1 second between iterations
    current_millisec = millis();
    if(current_millisec - prev_millisec < interval)
        return;    //  (->low power mode?)

    prev_millisec = current_millisec;
    Serial.println(".");


GPS library:
  TinyGPS++ (LGPL>=2.1)  http://arduiniana.org/libraries/tinygpsplus/
  Because the GPS is always coming in and the input buffer on the UART is
  only 64 bytes(?), we can't just delay() or go to sleep between outputs,
  we constantly have to read() & digest the NMEA sentences coming in. The
  TinyGPS++ examples have a smartDelay() function to aid with this.

  The "isValid" result is refering to the last checksum **NOT** the GPS fix.
  The "isUpdated" result is true if a new valid (both checksum and fix) NMEA
  message has come through and the memory field has been touched since the
  last time you QUERIED it. So the date fields will be "updated" once per
  second by $GPRMC, not once per day when the date changes.
  Use the "age()" result to query for the last good fix (1500 ms is suggested).

  TinyGPS++ mainly works on GGA and RMC, so we turn off the other NMEA sentences.

  Lat/Lon floating point values are restricted to 32bit precision; so a total
  of 7 or 8 significant digits including those before the decimal point.
  1e-5 * 1852 * 60 = 1.11 meters.  The GPS unit outputs decimal minutes to
  0.0001 precision, (0.0001 / 60) * 1852 * 60 =  0.18520 meters. The TinyGPS++
  library gives us "raw" billionths of a degree output we can reassemble later.
  [ Perhaps use the NeoGPS library for better precision?
     https://github.com/SlashDevin/NeoGPS ]


LiDAR:
 I2C SDA,CLK on the ProMicro are pins 2 and 3. The unit is preprogrammed at
 the 7-bit address 0x55. It returns two bytes of data to make the integer
 number of centimeters distance. The result is ordered big-endian.
    ////// get laser value //////
    // get 2 bytes from the SF-11 range finder
    Wire.requestFrom(I2C_ADR, 2);
    if (Wire.available() >= 2) {
        byteH = Wire.read();
        byteL = Wire.read();
        // combine in big endian order
        distance_cm = byteH * 256 + byteL;
        Serial.print("\tlidar (cm): ");
        Serial.println(distance_cm);
    }

SDcard:
 The SD card should be formatted using the SD card foundation's official formatting
 tool. Note the SDcard reader must be fed 3.3v for VCC, as 5v will damage it.

*/

#include <SPI.h>
#include <Wire.h>    // Wire.h provides I2C bus
#include <TinyGPS++.h>
#include "SD.h"


#define USB_CONNECTED


// LiDAR I2C pins
//#define I2C_SDA  2
//#define I2C_CLK  3
#define I2C_ADR  0x55

// SDcard SPI pins
#define SPI_CS   10
//#define SPI_CLK  15
//#define SPI_MISO 14
//#define SPI_MOSI 16
#define RX_LED   17


// The TinyGPS++ object
TinyGPSPlus gps;

// write out to sd card at least every 60 seconds
unsigned long prev_millisec = 0;
long interval = 60000;


// the logging file
File logfile;


////////////////////////////////////////////////////////////

int freeRam () {
    extern int __heap_start, *__brkval;
    int v;
    return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval);
}

////////////////////////////////////////////////////////////


void setup(void)
{

#ifdef USB_CONNECTED
    //// Start the USB-serial, for debugging
    Serial.begin(9600);
    /** Careful with this next line, if computer isn't attatched it will hang **/
    while(!Serial) {   // loop while ProMicro takes a moment to get itself together
        if (millis() > 6000)   // give up waiting for USB cable plugin after 6 sec
            break;
    }

    Serial.print(F("Free RAM: "));
    Serial.println(freeRam());
#endif

    //// GPS is on the ProMicro's UART (Serial1)
    Serial1.begin(4800);
    while(!Serial1);   // wait for it   (** NOTE this will hang the logger if GPS is not connected **)
    // Turn off messages we don't want
    Serial1.print(F("$PSRF103,02,00,00,01*26\r\n"));      // GSA off
    delay(20);
    Serial1.print(F("$PSRF103,03,00,00,01*27\r\n"));      // GSV off
    delay(20);

    //// startup I2C bus for the LiDAR
    Wire.begin();


    /////////////////////////////////////////
#ifdef USB_CONNECTED
    Serial.print(F("Initializing SD card..."));
#endif
    // see if the card is present and can be initialized:
    if (!SD.begin(SPI_CS)) {
#ifdef USB_CONNECTED
        Serial.println(F("ERROR: SD card failed, or not present. Halting."));
#endif
        lock_and_blink();  // lock it up
        //or,  return;
    }
#ifdef USB_CONNECTED
    Serial.println(F("SD card initialized."));
#endif

    // create a new file
    char filename[] = "LOG_0000.CSV";
    for (uint8_t i = 0; i < 10000; i++) {
        filename[4] = i/1000 + '0';
        filename[5] = i/100 + '0';
        filename[6] = i/10 + '0';
        filename[7] = i%10 + '0';
        //Serial.print("Trying ");
        //Serial.println(filename);
        if (! SD.exists(filename)) {
            // only open a new file if it doesn't exist
            logfile = SD.open(filename, FILE_WRITE); 
            break;  // leave the loop!
        }
        //else {   // tidy up
        //   SD.remove(filename);
        //}
    }

    delay(500); // give it a chance to catch up before testing if it's ok.
    if (! logfile) {
#ifdef USB_CONNECTED
        Serial.println(F("ERROR: couldn't create log file. Halting"));
#endif
        lock_and_blink();  // lock it up
    }

#ifdef USB_CONNECTED
    Serial.print(F("Logging to: "));
    Serial.println(filename);
    Serial.println();

    ////////////////////////////////////

    Serial.println(F("# GPS and Laser Rangefinder logging with Pro Micro Arduino 3.3v"));
    Serial.print(F("#gmt_date\tgmt_time\tnum_sats\tlongitude\tlatitude\t"));
    Serial.println(F("gps_altitude_m\tSOG_kt\tCOG\tHDOP\tlaser_altitude_cm"));
#endif
    logfile.println(F("# GPS and Laser Rangefinder logging with Pro Micro Arduino 3.3v"));
    logfile.print(F("#gmt_date\tgmt_time\tnum_sats\tlongitude\tlatitude\t"));
    logfile.println(F("gps_altitude_m\tSOG_kt\tCOG\tHDOP\tlaser_altitude_cm"));

    // should we wait a while for GPS to get a fix?
    wakeful_sleep(2000);

    // blink 10 times, we're good to go
    for (int i = 0; i < 10; i++) {
        digitalWrite(RX_LED, LOW);
        TXLED1;
        wakeful_sleep(100);
        digitalWrite(RX_LED, HIGH);
        TXLED0;
        wakeful_sleep(100);
    }
}


///////////////////////////////////////////////////

void loop(void)
{

#ifdef DEBUG_NMEA
    // Echo GPS to USB-serial port for debugging:
    char c = 'x';    //gps
    while(Serial1.available() > 0) {
        c = Serial1.read();
        if(c == '\r')
            continue;
        else if(c == '\n')
            Serial.println();
        else
            Serial.print(c);
    }
#endif

    ////// get GPS string //////
    while(Serial1.available() > 0)
        gps.encode(Serial1.read());

    // perhaps output all NaNs every 10 sec if no fix, just to show something is happening?
    if(!gps.date.isUpdated() || gps.location.age() > 1750)
        return;
//    /* Debug */
//    if(!gps.date.isUpdated())
//        return;


    //// Printout to USB-serial
#ifdef USB_CONNECTED
    print_gps_date();
    Serial.print(F("\t"));
    print_gps_time(); 
    Serial.print(F("\t"));

    Serial.print(gps.satellites.value());
    Serial.print(F("\t"));
    if (gps.location.isValid()) {
	Serial.print(gps.location.lng(), 6);
	Serial.print(F("\t"));
	Serial.print(gps.location.lat(), 6);
    }
    else {
	Serial.print(F("NaN\tNaN"));
    }
    Serial.print(F("\t"));

    if (gps.altitude.isValid())
	Serial.print(gps.altitude.meters());
    else
	Serial.print(F("NaN"));
    Serial.print(F("\t"));

    if (gps.speed.isValid())
	Serial.print(gps.speed.knots());
    else
	Serial.print(F("NaN"));
    Serial.print(F("\t"));

    if (gps.course.isValid())
	Serial.print(gps.course.deg());
    else
	Serial.print(F("NaN"));
    Serial.print(F("\t"));
    if (gps.hdop.isValid())
	Serial.print(gps.hdop.value());
    else
	Serial.print(F("NaN"));
    Serial.print(F("\t"));

    // lidar
    print_lidar_alt();	      
    Serial.println();

    // clear the pipes
    wakeful_sleep(0);
#endif

    ///// write to SD card /////
    TXLED1;   // The Tx LED is not tied to a normally controlled pin so we use this macro

    write_gps_date();
    logfile.print(F("\t"));
    write_gps_time(); 
    logfile.print(F("\t"));

    logfile.print(gps.satellites.value());
    logfile.print(F("\t"));
    if (gps.location.isValid()) {
        logfile.print(gps.location.lng(), 6);
        logfile.print(F("\t"));
        logfile.print(gps.location.lat(), 6);
    }
    else {
        logfile.print(F("NaN\tNaN"));
    }
    logfile.print(F("\t"));

    if (gps.altitude.isValid())
        logfile.print(gps.altitude.meters());
    else
        logfile.print(F("NaN"));
    logfile.print(F("\t"));

    if (gps.speed.isValid())
        logfile.print(gps.speed.knots());
    else
        logfile.print(F("NaN"));
    logfile.print(F("\t"));

    if (gps.course.isValid())
        logfile.print(gps.course.deg());
    else
        logfile.print(F("NaN"));
    logfile.print(F("\t"));
    if (gps.hdop.isValid())
        logfile.print(gps.hdop.value());
    else
        logfile.print(F("NaN"));
    logfile.print(F("\t"));

    // lidar
    write_lidar_alt();        
    logfile.println();

    TXLED0;    // Tx LED off


    // The following line will 'save' the file to the SD card after every
    // 60 seconds of data - this will use more power but it's safer!
    // If you want to speed up the system, remove the call to flush() and it
    // will save the file only every 512 bytes - every time a sector on the 
    // SD card is filled with data. (about every 6 seconds)
    // The flush() may still be needed to update the FAT?
    unsigned long current_millisec;
    current_millisec = millis();
    if(current_millisec - prev_millisec > interval) {
        prev_millisec = current_millisec;
#ifdef USB_CONNECTED
        Serial.println("flushing to SDcard.");
#endif
        digitalWrite(RX_LED, LOW);   // set the Rx LED on
        logfile.flush();
        digitalWrite(RX_LED, HIGH);   // set the Rx LED off
        //wakeful_sleep(20);
    }

    // checking to see if the 1Hz $GPRMC date is updated seems to be enough for a delay.
}


// USB Serial port versions:
#ifdef USB_CONNECTED
void print_gps_date() {
    if (gps.date.isValid()) {
        Serial.print(gps.date.year());
        Serial.print(F("/"));
        if(gps.date.month() < 10)
            Serial.print(F("0"));
        Serial.print(gps.date.month());
        Serial.print(F("/"));
        if(gps.date.day() < 10)
            Serial.print(F("0"));
        Serial.print(gps.date.day());
    }
    else {
        Serial.print(F("INVALID"));
    }
}

void print_gps_time() {
    if (gps.time.isValid()) {
        if (gps.time.hour() < 10)
            Serial.print(F("0"));
        Serial.print(gps.time.hour());
        Serial.print(F(":"));
        if (gps.time.minute() < 10)
            Serial.print(F("0"));
        Serial.print(gps.time.minute());
        Serial.print(F(":"));
        if (gps.time.second() < 10)
            Serial.print(F("0"));
        Serial.print(gps.time.second());
    }
    else {
        Serial.print(F("INVALID"));
    }
}

void print_lidar_alt() {
    int distance_cm;
    int byteH, byteL;  // low and high bytes (reading is 16bit int)

    ////// get laser value (centimeters) //////
    // get 2 bytes from the SF-11 range finder
    Wire.requestFrom(I2C_ADR, 2);
    if (Wire.available() >= 2) {
        byteH = Wire.read();
        byteL = Wire.read();
        // combine in big endian order
        distance_cm = byteH * 256 + byteL;
        //Serial.print("\tlidar (cm): ");
        Serial.print(distance_cm);
    }
    else
        Serial.print(F("NaN"));
}
#endif


// SD card versions:
void write_gps_date() {
    if (gps.date.isValid()) {
        logfile.print(gps.date.year());
        logfile.print(F("/"));
        if(gps.date.month() < 10)
            logfile.print(F("0"));
        logfile.print(gps.date.month());
        logfile.print(F("/"));
        if(gps.date.day() < 10)
            logfile.print(F("0"));
        logfile.print(gps.date.day());
    }
    else {
        logfile.print(F("INVALID"));
    }
}

void write_gps_time() {
    if (gps.time.isValid()) {
        if (gps.time.hour() < 10)
            logfile.print(F("0"));
        logfile.print(gps.time.hour());
        logfile.print(F(":"));
        if (gps.time.minute() < 10)
            logfile.print(F("0"));
        logfile.print(gps.time.minute());
        logfile.print(F(":"));
        if (gps.time.second() < 10)
            logfile.print(F("0"));
        logfile.print(gps.time.second());
    }
    else {
        logfile.print(F("INVALID"));
    }
}


void write_lidar_alt() {
    int distance_cm;
    int byteH, byteL;  // low and high bytes (reading is 16bit int)

    ////// get laser value (centimeters) //////
    // get 2 bytes from the SF-11 range finder
    Wire.requestFrom(I2C_ADR, 2);
    if (Wire.available() >= 2) {
        byteH = Wire.read();
        byteL = Wire.read();
        // combine in big endian order
        distance_cm = byteH * 256 + byteL;
        //Serial.print("\tlidar (cm): ");
        logfile.print(distance_cm);
    }
    else
        logfile.print(F("NaN"));
}


// From the TinyGPS++ library smartDelay() example:
// This custom version of delay() ensures that the gps object is being "fed".
static void wakeful_sleep(unsigned long ms)
{
  unsigned long start = millis();
  do 
  {
    while (Serial1.available())
      gps.encode(Serial1.read());
  } while (millis() - start < ms);
}


void lock_and_blink() {
    while(1) {    //lock it up, blinking forever
        digitalWrite(RX_LED, HIGH);
        TXLED0;
        delay(500);
        digitalWrite(RX_LED, LOW);
        TXLED1;
        delay(500);
    }
}
