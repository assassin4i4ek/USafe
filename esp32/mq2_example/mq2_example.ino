#define NORMAL_VALUE 2250

const int gasInput = A7;

void setup() {
  Serial.begin(9600);
}

void loop() {
  int gasRaw = analogRead(gasInput);
  Serial.println(gasRaw);
  delay(1000);
}
