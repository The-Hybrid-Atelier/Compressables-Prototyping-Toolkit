#include <JSONWebsocket.h>

char ssid[] = WIFI_SSID;     //  your network SSID (name)
char pass[] = WIFI_PASS; // your network password  
char serverAddress[] = WS_ADDR;  // server address
int port = WS_PORT;

WiFiClient wifi;
WebSocketClient client_ = WebSocketClient(wifi, serverAddress, port);

DynamicJsonDocument server_json(1024);
DynamicJsonDocument feather_json(1024);

void JSONWebsocket::send(DynamicJsonDocument* json){
  client_.beginMessage(TYPE_TEXT);
  // Serial.println("Sending");
  serializeJson(*json, client_);
  // Serial.println("Sent");
  client_.endMessage();
  json->clear();
}

void JSONWebsocket::init(){
  WiFi.setPins(8,7,4,2);
  while ( status != WL_CONNECTED) {
    port_.print("Attempting to connect to Network named: ");
    port_.println(ssid);                   // print the network name (SSID);
    status = WiFi.begin(ssid, pass);
  }
  port_.print("SSID: ");
  port_.println(WiFi.SSID());
  ip = WiFi.localIP();
  port_.print("IP Address: ");
  port_.println(ip);	
}

void JSONWebsocket::greet(){
  feather_json["name"] = name_;
  feather_json["event"] = "greeting"; 
  feather_json["data"] = count;
  count ++; 
  
  // Registering with Server
  client_.beginMessage(TYPE_TEXT);
  serializeJson(feather_json, client_);
  client_.endMessage();
  feather_json.clear();
}

void JSONWebsocket::battery(){
  float measuredvbat = analogRead(VBATPIN);
  measuredvbat *= 2;    // we divided by 2, so multiply back
  measuredvbat *= 3.3;  // Multiply by 3.3V, our reference voltage
  measuredvbat /= 1024; // convert to voltage
  port_.print("VBat: " ); 
  port_.println(measuredvbat);
  
  feather_json["event"] = "battery";
  feather_json["time"] = millis();
  feather_json["data"] = measuredvbat;
  
  client_.beginMessage(TYPE_TEXT);
  serializeJson(feather_json, client_);
  client_.endMessage();
  feather_json.clear();
}

void JSONWebsocket::listen(){
  while(! client_.connected()){
    port_.print("\tAttempting connection to ");
    port_.print(serverAddress);
    port_.print(" from ");
    port_.println(ip);
    client_.begin();
    port_.println(client_.connected());
    delay(500); 
  }
  
  greet();


  while (client_.connected()) {
    int messageSize = client_.parseMessage(); 
    if (messageSize > 0) {
      port_.println("Received a message:");
      
      String response = client_.readString();
      port_.println(response);

      deserializeJson(server_json, response);
      JsonObject obj = server_json.as<JsonObject>();
      
      if(obj.containsKey("api")){
        obj = obj[String("api")];
        if(obj.containsKey("command")){
          String command = obj[String("command")];
          obj = obj[String("params")];
          port_.print("API CALL: ");
          port_.println(command);
          api_(client_, command, obj);
          
        }
      }
      server_json.clear();
      port_.println("Message processing complete.");
    }
    loop_();
    // wait 5 seconds
    // delay(0);
  }

  port_.println("disconnected");
}