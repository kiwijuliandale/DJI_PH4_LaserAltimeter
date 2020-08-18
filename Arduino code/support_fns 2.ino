

// USB Serial port versions:
#ifdef USB_CONNECTED
void print_gps_date() {
  if (gps.date.isValid()) {
    Serial.print(gps.date.year());
    Serial.print(F("/"));
    if (gps.date.month() < 10)
      Serial.print(F("0"));
    Serial.print(gps.date.month());
    Serial.print(F("/"));
    if (gps.date.day() < 10)
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

void print_imu_data(struct imu_data imu_results) {
  Serial.print(imu_results.Grav_x, 4);
  Serial.print(F("\t"));
  Serial.print(imu_results.Grav_y, 4);
  Serial.print(F("\t"));
  Serial.print(imu_results.Grav_z, 4);

  Serial.print(F("\t"));

  Serial.print(imu_results.Gyro_x, 3);
  Serial.print(F("\t"));
  Serial.print(imu_results.Gyro_y, 3);
  Serial.print(F("\t"));
  Serial.print(imu_results.Gyro_z, 3);
}
#endif


// SD card versions:
void write_gps_date() {
  if (gps.date.isValid()) {
    logfile.print(gps.date.year());
    logfile.print(F("/"));
    if (gps.date.month() < 10)
      logfile.print(F("0"));
    logfile.print(gps.date.month());
    logfile.print(F("/"));
    if (gps.date.day() < 10)
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


/* TODO, run after we have GPS lock
  // SD card file timestamp callback function
  void FileDateTime(uint16_t *date, uint16_t *time) {
  DateTime now = rtc.now();
   date = FAT_DATE(now.year(), now.month(), now.day());
   time = FAT_TIME(now.hour(), now.minute(), now.second());
  }
*/

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


void write_imu_data(struct imu_data imu_results) {
  logfile.print(imu_results.Grav_x, 4);
  logfile.print(F("\t"));
  logfile.print(imu_results.Grav_y, 4);
  logfile.print(F("\t"));
  logfile.print(imu_results.Grav_z, 4);

  logfile.print(F("\t"));

  logfile.print(imu_results.Gyro_x, 3);
  logfile.print(F("\t"));
  logfile.print(imu_results.Gyro_y, 3);
  logfile.print(F("\t"));
  logfile.print(imu_results.Gyro_z, 3);
}



/// **** if build fails with unknown Serial1, make sure board is set to SparkFun Pro Micro **** ///

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
  while (1) {   //lock it up, blinking forever
    digitalWrite(RX_LED, HIGH);
    TXLED0;
    delay(500);
    digitalWrite(RX_LED, LOW);
    TXLED1;
    delay(500);
  }
}


struct imu_data get_IMU_readings() {
  struct imu_data results;

  int i;
  long sample_sum_xAc, sample_sum_yAc, sample_sum_zAc;
  long sample_sum_xGy, sample_sum_yGy, sample_sum_zGy;
  float reading_xAc, reading_yAc, reading_zAc;
  float reading_xGy, reading_yGy, reading_zGy;
  float Grav_x, Grav_y, Grav_z, Gyro_x, Gyro_y, Gyro_z;
  float horiz_mag;
  //unsigned long millisec1;

  sample_sum_xAc = 0;
  sample_sum_yAc = 0;
  sample_sum_zAc = 0;
  sample_sum_xGy = 0;
  sample_sum_yGy = 0;
  sample_sum_zGy = 0;

  //millisec1 = millis();

  digitalWrite(RX_LED, LOW);   // set the Rx LED on
  for (i = 0; i < NUMSAMPLES; i++) {
    imu.read();
    sample_sum_xAc += imu.a.x;
    sample_sum_yAc += imu.a.y;
    sample_sum_zAc += imu.a.z;
    sample_sum_xGy += imu.g.x;
    sample_sum_yGy += imu.g.y;
    sample_sum_zGy += imu.g.z;
  }
  digitalWrite(RX_LED, HIGH);   // set the Rx LED off

  reading_xAc = (float)sample_sum_xAc / NUMSAMPLES;
  reading_yAc = (float)sample_sum_yAc / NUMSAMPLES;
  reading_zAc = (float)sample_sum_zAc / NUMSAMPLES;
  reading_xGy = (float)sample_sum_xGy / NUMSAMPLES;
  reading_yGy = (float)sample_sum_yGy / NUMSAMPLES;
  reading_zGy = (float)sample_sum_zGy / NUMSAMPLES;

  //Serial.println(millis() - millisec1);

  // 0.061 milli-g per LSB. /1000 to get in terms of 1g of gravity
  //  see start of this file, datasheet page 15
  // for m/sec^2 value they used for g would need to be known   ..?
  results.Grav_x = reading_xAc * 0.061 / 1000.0;
  results.Grav_y = reading_yAc * 0.061 / 1000.0;
  results.Grav_z = reading_zAc * 0.061 / 1000.0;

  horiz_mag = sqrt(results.Grav_x*results.Grav_x + results.Grav_y*results.Grav_y);
  results.tilt_deg = abs(atan(horiz_mag / results.Grav_z) * 180./M_PI);
  //Serial.println(results.tilt_deg);

  // at gain level of +-245 deg/sec 1 bit is 8.75 mdps/LSB
  //  see same datasheet as gravity above page 15
  results.Gyro_x = reading_xGy * 8.75 / 1000.0;
  results.Gyro_y = reading_yGy * 8.75 / 1000.0;
  results.Gyro_z = reading_zGy * 8.75 / 1000.0;

  return results;
}

