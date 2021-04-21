/* Be sure to add an arduino_secrets.h to your library src
 * ~/Documents/Arduino/library/JSONWebsocket/src < arduino_secrets.h
 */
 
#include <JSONWebsocket.h>
#define BAUD 115200
#define DEVICE_NAME "programmable-air"
#define DATA_SIZE 8

/* Function Prototypes */
void apiCall(WebSocketClient client, String prefix, JsonObject obj);
void apiLoop(); 

/* Websocket Server Buffer and Object */
DynamicJsonDocument json(4096*4);
JSONWebsocket jws (DEVICE_NAME, Serial, BAUD, apiCall, apiLoop);

/* --------------   AIR_API -------------- */
char c;
bool pressure_on = false;
void air_setup() { Serial1.begin(BAUD); }

void pressure_read(){
  int c = 0; // buffer for Serial1
  json["event"] = "read-pressure";
  json["time"] = millis();
  JsonArray data = json.createNestedArray("data");
  for(int i = 0; i< DATA_SIZE; i++){
    while(c <= 0){ c = Serial1.read();} // Wait until a pressure reading
    data.add(c); 
  }
//  Serial.println(c);
  jws.send(&json);
}

void pump_on(int pumpNumber, int pwm)
{
  c = '1';
  Serial1.write(c);
  delay(10);
  Serial1.write(pumpNumber);
  delay(10);
  Serial1.write(pwm);
  delay(10);
  Serial1.write('\n');
  }

void pump_off(int pumpNumber)
{
  c = '2';  
  Serial1.write(c);
  delay(10);
  Serial.println(pumpNumber);
  Serial1.write(pumpNumber);
  delay(10);
  Serial1.write('\n');
}


/* --------------  END OF AIR_API  -------------- */

/* Server Logic */
void manifest(){  
  json["event"] = "manifest";
  json["time"] = millis();

  JsonArray data = json.createNestedArray("data");
  data.add("PRESSURE_ON");
  data.add("PRESSURE_OFF");
  data.add("BATTERY");
  data.add("MANIFEST");

  jws.send(&json); 
}

/* Routing */
void apiCall(WebSocketClient client, String prefix, JsonObject obj){
  char c = '\0';
  Serial.print("API CALL: ");
  Serial.println(prefix);
  
  if (prefix == "PUMP_ON"){ pump_on(obj[String("pumpNumber")], obj[String("PWM")]);}
  else if (prefix == "PUMP_OFF"){pump_off(obj[String("pumpNumber")]);}
  else if (prefix == "ALL_PUMP_OFF"){c = '3';}
  else if (prefix == "PULSE_ON"){c = '4';}
  else if (prefix == "PULSE_OFF"){c = '5';}
  else if (prefix == "PRESSURE_ON"){ c = '6';  pressure_on = true; }
  else if (prefix == "PRESSURE_OFF"){c = '7';  pressure_on = false;}
  else if (prefix == "BLOW"){c = '8';}
  else if (prefix == "SUCK"){c = '9';}
  else if (prefix == "VENT"){c = 'a';}
  else if (prefix == "SEAL"){c = 'b';}
  else if (prefix == "RELEASE"){c = 'c';}
  else if (prefix == "BATTERY") { jws.battery();   }
  else if (prefix == "MANIFEST"){ manifest();     }
  else { Serial.println("COMMAND NOT FOUND");     }

  if(c != '\0'){
    Serial1.write(c);
    Serial1.write('\n');
  }
}

void apiLoop() { 
  if(pressure_on  && Serial1.available()){pressure_read();}
}

/* ARDUINO LOGIC */
void setup() {
  
  //while(!Serial);
  Serial.begin(BAUD);
  
  // Websocket Setup
  jws.init();
  
  // Programmable Air Setup
  air_setup();
}

void loop() { jws.listen();}
