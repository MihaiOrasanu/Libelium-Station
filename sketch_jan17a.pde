/*
    ------ WIFI Example --------
    Explanation: This example shows how to perform HTTP GET requests
    Copyright (C) 2021 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    Version:           3.0
    Implementation:    Luis Miguel Martí
*/


#include <WaspSensorCities_PRO.h>
#include <WaspFrame.h>
#include <WaspPM.h>
#include <WaspWIFI_PRO_V3.h>


/*
   Define objects for sensors
   Imagine we have a P&S! with the next sensors:
    - SOCKET_A: BME280 sensor (temperature, humidity & pressure)
    - SOCKET_B: Electrochemical gas sensor (O3)
    - SOCKET_C: Electrochemical gas sensor (NO2)
    - SOCKET_D: Particle matter sensor (dust)
    - SOCKET_E: Luxes sensor
    - SOCKET_F: Pellistor sensor (CO2)
*/
bmeCitiesSensor bme(SOCKET_E);
luxesCitiesSensor luxes(SOCKET_A);
Gas sensor_so2(SOCKET_B);
Gas sensor_no2(SOCKET_C);
Gas sensor_co(SOCKET_F);


// define vars for sensor values
float temperature;
float humidity;
float pressure;
uint32_t luminosity;
float concentration_so2;
float concentration_no2;
float concentration_co;
int OPC_status;
int OPC_measure;

// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket = SOCKET0;
///////////////////////////////////////


// choose HTTP server settings
///////////////////////////////////////
char type[] = "http";
char host[] = "82.78.81.178";
uint16_t port = 80;
///////////////////////////////////////

uint8_t error;
uint8_t status;

// define the Waspmote ID
char moteID[] = "mihai_orasanu";

void setup()
{
  USB.ON();
  USB.println(F("Frame Utility Example for Cities Pro Board"));
  USB.println(F("Sensors used:"));
  USB.println(F("- SOCKET_A: Luxes sensor"));
  USB.println(F("- SOCKET_C: Electrochemical gas sensor (NO2)"));
  USB.println(F("- SOCKET_B: Electrochemical gas sensor (SO2)"));
  USB.println(F("- SOCKET_D: Particle matter sensor (dust)"));
  USB.println(F("- SOCKET_E: BME280 sensor (temperature, humidity & pressure)"));
  USB.println(F("- SOCKET_F: NDIR sensor (CO)"));

  // Set the Waspmote ID
  frame.setID(moteID);
}



void loop()
{
  ///////////////////////////////////////////
  // 1. Read BME and luxes sensors
  ///////////////////////////////////////////

  // switch off all gas sensors for better performance
  sensor_so2.OFF();
  sensor_no2.OFF();
  sensor_co.OFF();

  // switch on BME sensor
  // read temperature, humidity and pressure
  // switch off BME sensor
  bme.ON();
  temperature = bme.getTemperature();
  humidity = bme.getHumidity();
  pressure = bme.getPressure();
  bme.OFF();

  // switch on luxes sensor
  // read luminosity
  // switch off luxes sensor
  luxes.ON();
  luminosity = luxes.getLuminosity();
  luxes.OFF();

  // switch on all gas sensor again
  sensor_so2.ON();
  sensor_no2.ON();
  sensor_co.ON();


  ///////////////////////////////////////////
  // 2. Wait heating time
  ///////////////////////////////////////////

  // Sensors need time to warm up and get a response from gas
  // To reduce the battery consumption, use deepSleep instead delay
  // After 2 minutes, Waspmote wakes up thanks to the RTC Alarm
  USB.println();
  USB.println(RTC.getTime());
  USB.println(F("Enter deep sleep mode to wait for sensors heating time..."));
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  USB.ON();
  USB.println(F("wake up!!\r\n"));
  USB.println(RTC.getTime());

  ///////////////////////////////////////////
  // 3. Read gas sensors
  ///////////////////////////////////////////

  // Read the sensors and compensate with the temperature internally
  concentration_so2 = sensor_so2.getConc(temperature);
  concentration_no2 = sensor_no2.getConc(temperature);
  concentration_co = sensor_co.getConc(temperature);


  // switch off CO2 sensor
  // Pellistor and NDIR sensors must be switched off after
  // reading because they present a high power consumption
  


  ///////////////////////////////////////////
  // 4. Read particle matter sensor
  ///////////////////////////////////////////

  


  ///////////////////////////////////////////
  // 5. Print sensor values
  ///////////////////////////////////////////

  USB.println(F("***********************************************"));
  USB.print(F("SOCKET_E -- > Temperature : "));
  USB.printFloat(temperature, 2);
  USB.println(F(" Celsius degrees"));
  USB.print(F("SOCKET_E -- > Humidity : "));
  USB.printFloat(humidity, 2);
  USB.println(F(" % "));
  USB.print(F("SOCKET_E -- > Pressure : "));
  USB.printFloat(pressure, 2);
  USB.println(F(" Pa"));
  USB.print(F("SOCKET_C -- > SO2 concentration : "));
  USB.printFloat(concentration_so2, 3);
  USB.println(F(" ppm"));
  USB.print(F("SOCKET_B -- > NO2 concentration : "));
  USB.printFloat(concentration_no2, 3);
  USB.println(F(" ppm"));
  USB.print(F("SOCKET_A -- > Luminosity : "));
  USB.print(luminosity);
  USB.println(F(" luxes"));
  USB.print(F("SOCKET_F -- > CO concentration : "));
  USB.printFloat(concentration_co, 3);
  USB.println(F(" ppm"));
  USB.println(F("***********************************************"));



  ///////////////////////////////////////////
  // 6. Create ASCII frame
  ///////////////////////////////////////////

  // Create new frame (ASCII)
  frame.createFrame(BINARY);

  // Add sensor values
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel() );
  frame.addSensor(SENSOR_CITIES_PRO_TC, temperature);
  frame.addSensor(SENSOR_CITIES_PRO_HUM, humidity);
  frame.addSensor(SENSOR_CITIES_PRO_PRES, pressure);
  frame.addSensor(SENSOR_CITIES_PRO_SO2, concentration_so2);
  frame.addSensor(SENSOR_CITIES_PRO_NO2, concentration_no2);
  frame.addSensor(SENSOR_CITIES_PRO_CO, concentration_co);
  frame.addSensor(SENSOR_CITIES_PRO_LUXES, luminosity);
  
  // Show the frame
  frame.showFrame();


  ///////////////////////////////////////////
  // 7. Sleep
  ///////////////////////////////////////////

  //////////////////////////////////////////////////
  // 1. Switch ON
  //////////////////////////////////////////////////
  error = WIFI_PRO_V3.ON(socket);

  if (error == 0)
  {
    USB.println(F("WiFi switched ON"));
  }
  else
  {
    USB.println(F("WiFi did not initialize correctly"));
  }

  // check connectivity
  status =  WIFI_PRO_V3.isConnected();

  // check if module is connected
  if (status == true)
  {
    //    ///////////////////////////////
    //    // 3.1. Create a new Frame
    //    ///////////////////////////////
    //
    //    // create new frame (only ASCII)
    //    frame.createFrame(ASCII);
    //
    //    // add sensor fields
    //    frame.addSensor(SENSOR_STR, "this_is_a_string");
    //    frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
    //
    //    // print frame
    //    frame.showFrame();


    ///////////////////////////////
    // 3.2. Send Frame to Meshlium
    ///////////////////////////////

    // http frame
    error = WIFI_PRO_V3.sendFrameToMeshlium( type, host, port, frame.buffer, frame.length);

    // check response
    if (error == 0)
    {
      USB.println(F("Send frame to meshlium done"));
    }
    else
    {
      USB.println(F("Error sending frame"));
      if (WIFI_PRO_V3._httpResponseStatus)
      {
        USB.print(F("HTTP response status: "));
        USB.println(WIFI_PRO_V3._httpResponseStatus);
      }
    }
  }
  else
  {
    USB.print(F("2. WiFi is connected ERROR"));
  }
  //////////////////////////////////////////////////
  // 3. Switch OFF
  //////////////////////////////////////////////////
  WIFI_PRO_V3.OFF(socket);
  USB.println(F("WiFi switched OFF\n\n"));
  USB.println(F("---------------------------------"));
  USB.println(F("...Enter deep sleep mode 2 min"));
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
  USB.ON();
  USB.print(F("...wake up!! Date: "));
  USB.println(RTC.getTime());

  //  RTC.setWatchdog(720); // 12h in minutes
  //  USB.print(F("...Watchdog :"));
  //  USB.println(RTC.getWatchdog());
  USB.println(F("****************************************"));
}
