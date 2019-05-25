#define X_OFFSET 1808
#define X_GAIN 402
#define Y_OFFSET 1826
#define Y_GAIN 402
#define Z_OFFSET 1904
#define Z_GAIN 416

const int xInput = 36;
const int yInput = 39;
const int zInput = 34;

// initialize minimum and maximum Raw Ranges for each axis
int RawMin = 0;
int RawMax = 4095;

// Take multiple samples to reduce noise
const int sampleSize = 1;

void setup() 
{
  Serial.begin(9600);
}

void loop() 
{
  //Read raw values
  int xRaw = analogRead(xInput);
  delay(1);
  int yRaw = analogRead(yInput);
  delay(1);
  int zRaw = analogRead(zInput);
  
  float xScaled = ((float)xRaw - X_OFFSET) / X_GAIN;
  float yScaled = ((float)yRaw - Y_OFFSET) / Y_GAIN;
  float zScaled = ((float)zRaw - Z_OFFSET) / Z_GAIN;

  Serial.print("X, Y, Z  :: ");
  Serial.print(xRaw);
  Serial.print(", ");
  Serial.print(yRaw);
  Serial.print(", ");
  Serial.println(zRaw);
  Serial.print("\t");
  Serial.print(xScaled, 4);
  Serial.print(", ");
  Serial.print(yScaled, 4);
  Serial.print(", ");
  Serial.println(zScaled, 4);
  delay(1000);
}
