const int vibrationInput = 32;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(vibrationInput, INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  // long rawVibrationAnalog = analogRead(vibrationInput);
  long rawVibration = pulseIn(vibrationInput, HIGH);
  Serial.println(rawVibration);    
  delay(100);
}
