#include "WiFi.h"
#include "PubSubClient.h"

//SOPHISTICATED
//  MQTT
#define MQTT_CLIENT_ID "ESP32Client"
#define DEVICE_ID "helmet1"
//  ACCELERATION
#define ACCELERATION_X_OFFSET 1808
#define ACCELERATION_X_GAIN 402
#define ACCELERATION_Y_OFFSET 1826
#define ACCELERATION_Y_GAIN 402
#define ACCELERATION_Z_OFFSET 1904
#define ACCELERATION_Z_GAIN 416

//COMMON SECTION
//  WIFI
#define WIFI_SSID "Dozen"
#define WIFI_PASSWORD "qwertyui"
//  MQTT
#define MQTT_SERVER "m24.cloudmqtt.com"
#define MQTT_PORT 11714
#define MQTT_USER "qeozciql"
#define MQTT_PASSWORD "rL4GWKmt99KZ"
#define MQTT_VIBRATION_TOPIC DEVICE_ID "/vibration/raw"
#define MQTT_GAS_TOPIC DEVICE_ID "/gas/raw"
#define MQTT_ACCELERATION_TOPIC DEVICE_ID "/acceleration/raw"
//  INPUTS
#define ACCELERATION_X_INPUT 36
#define ACCELERATION_Y_INPUT 39
#define ACCELERATION_Z_INPUT 34
#define VIBRATION_INPUT 32
#define GAS_INPUT 35

WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

void setup() {
  Serial.begin(115200);
  //INIT WIFI
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi..");
  }
 
  Serial.println("Connected to the WiFi network");
  
  //INIT MQTT CONNECTION
  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
 
  while (!mqttClient.connected()) {
    Serial.println("Connecting to MQTT...");
 
    if (mqttClient.connect(MQTT_CLIENT_ID, MQTT_USER, MQTT_PASSWORD )) {
      Serial.println("Connected");
    } 
    else {
      Serial.print("failed with state ");
      Serial.print(mqttClient.state());
      delay(2000);
    }
  }

  //INIT INPUTS
  pinMode(VIBRATION_INPUT, INPUT);
}

float * readAcceleration() {
  static float xyz[3];
  int xRaw = analogRead(ACCELERATION_X_INPUT);
  xyz[0] = ((float)xRaw - ACCELERATION_X_OFFSET) / ACCELERATION_X_GAIN;
  int yRaw = analogRead(ACCELERATION_Y_INPUT);
  xyz[1] = ((float)yRaw - ACCELERATION_Y_OFFSET) / ACCELERATION_Y_GAIN;
  int zRaw = analogRead(ACCELERATION_Z_INPUT);
  xyz[2] = ((float)zRaw - ACCELERATION_Z_OFFSET) / ACCELERATION_Z_GAIN;
  return xyz;
}

long readVibration() {
  return pulseIn(VIBRATION_INPUT, HIGH);
}

int readGas() {
  return analogRead(GAS_INPUT);
}

void loop() {
  mqttClient.loop();
  static char buf[32];
  
  //ACCELERATION
  float * acceleration = readAcceleration();
  sprintf(buf, "{\"x\":%.3f,\"y\":%.3f,\"z\":%.3f}", acceleration[0], acceleration[1], acceleration[2]);
  mqttClient.publish(MQTT_ACCELERATION_TOPIC, buf);
  //GAS
  int gas = readGas();
  sprintf(buf, "%d", gas);
  mqttClient.publish(MQTT_GAS_TOPIC, buf);
  //VIBRATION
  long vibration = readVibration(); //has 1 second delay
  sprintf(buf, "%ld", vibration);
  mqttClient.publish(MQTT_VIBRATION_TOPIC, buf);
  
  delay(1000);
}
