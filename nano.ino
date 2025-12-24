const int analogPin = A5;
const int threshold = 532;  // ≈ 2.6V
// false = OFF, true = ON
bool prevState = false;
bool curState = false;

void setup() {
  pinMode(13, OUTPUT);
  Serial.begin(115200); // Start Serial Connection

  // Startup Chime!
  digitalWrite(13, HIGH); delay(500); digitalWrite(13, LOW);
  for (int i = 0; i < 10; i++) {
    delay(20); digitalWrite(13, HIGH); delay(50); digitalWrite(13, LOW);
  }
  delay(500); digitalWrite(13, HIGH); delay(200); digitalWrite(13, LOW);

  Serial.println("HI"); // Initial message
}

void loop() {
  int adcValue = analogRead(analogPin);

  curState = (adcValue >= threshold); 

  if (curState != prevState) {
    if (curState) {
      digitalWrite(13, HIGH);
      Serial.println("ON");
    } else {
      digitalWrite(13, LOW);
      Serial.println("OFF");
    }
    prevState = curState;
  }

  delay(1000);
}
