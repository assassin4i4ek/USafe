#include "WiFi.h"
#include "PubSubClient.h"

#define WIFI_SSID "Dozen"
#define WIFI_PASSWORD "qwertyui"
#define MQTT_SERVER "m24.cloudmqtt.com"
#define MQTT_PORT 11714
#define MQTT_USER "qeozciql"
#define MQTT_PASSWORD "rL4GWKmt99KZ"

WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi..");
  }
 
  Serial.println("Connected to the WiFi network");
 
  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
 
  while (!mqttClient.connected()) {
    Serial.println("Connecting to MQTT...");
 
    if (mqttClient.connect("ESP32Client", MQTT_USER, MQTT_PASSWORD )) {
 
      Serial.println("connected");
 
    } else {
 
      Serial.print("failed with state ");
      Serial.print(mqttClient.state());
      delay(2000);
 
    }
  }
 
  mqttClient.publish("esp/test", "Hello from ESP32");
}

void loop() {
  mqttClient.loop();
}
