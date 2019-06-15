#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

//SOPHISTICATED SECTION
#define DEVICE_ID "helmet1"
//  ACCELERATION
#define ACCELERATION_X_OFFSET 1808
#define ACCELERATION_X_GAIN 402
#define ACCELERATION_Y_OFFSET 1826
#define ACCELERATION_Y_GAIN 402
#define ACCELERATION_Z_OFFSET 1904
#define ACCELERATION_Z_GAIN 416

//COMMON SECTION
//  BLE
#define SERVICE_UUID "39b8f144-d224-49d4-9226-23d857ce200c"
#define ACCELERATION_CHARACTERSTIC_UUID "e2a996df-1601-4a70-a61c-56791f2ec236"
#define GAS_CHARACGERISTIC_UUID "57d63d58-4e7d-4327-9832-dfc284d2fc89"
#define VIBRATION_CHARACTERISTIC_UUID "3e887a0d-f703-489d-a701-8dbec9298649"
//  INPUTS
#define ACCELERATION_X_INPUT 36
#define ACCELERATION_Y_INPUT 39
#define ACCELERATION_Z_INPUT 34
#define VIBRATION_INPUT 32
#define GAS_INPUT 35
//GLOBAL SETTINGS
#define VIBRATION_TIMEOUT 1000000


BLECharacteristic *pAccelerationCharacteristic;
BLECharacteristic *pGasCharacteristic;
BLECharacteristic *pVibrationCharacteristic;

void setup() {
  Serial.begin(115200);
  //INIT BLE
  Serial.println("Starting BLE...");
  
  BLEDevice::init(DEVICE_ID);
  Serial.println("Init BLE...");

  BLEServer *pServer = BLEDevice::createServer();
  Serial.println("Server BLE...");
  BLEService *pService = pServer->createService(SERVICE_UUID);
  Serial.println("Service BLE...");
  pAccelerationCharacteristic = pService->createCharacteristic(
                                  ACCELERATION_CHARACTERSTIC_UUID, 
                                  BLECharacteristic::PROPERTY_READ);
  pGasCharacteristic = pService->createCharacteristic(
                                  GAS_CHARACGERISTIC_UUID, 
                                  BLECharacteristic::PROPERTY_READ);
  pVibrationCharacteristic = pService->createCharacteristic(
                                  VIBRATION_CHARACTERISTIC_UUID, 
                                  BLECharacteristic::PROPERTY_READ);
  Serial.println("Characteristics BLE...");
  pService->start();
  Serial.println("Service start BLE...");
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  Serial.println("Advertising BLE...");
  BLEDevice::startAdvertising();
  
  Serial.println("Started Advertising");
  
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
  return pulseIn(VIBRATION_INPUT, HIGH, VIBRATION_TIMEOUT);
}

int readGas() {
  return analogRead(GAS_INPUT);
}

void loop() {
  static char buf[100];
  
//  //ACCELERATION
  float * acceleration = readAcceleration();
  sprintf(buf, "{\"type\": \"acceleration\", \"raw_value\": {\"x\": %.3f,\"y\": %.3f,\"z\": %.3f}}", acceleration[0], acceleration[1], acceleration[2]);
  pAccelerationCharacteristic->setValue(buf);
  //GAS
  int gas = readGas();
  sprintf(buf, "{\"type\": \"gas\", \"raw_value\": %d}", gas);
  pGasCharacteristic->setValue(buf);
  //VIBRATION
  long vibration = readVibration(); //has 1 second delay
  sprintf(buf, "{\"type\": \"vibration\", \"raw_value\": %ld}", vibration);
  pVibrationCharacteristic->setValue(buf);
  
  delay(1000);
}
