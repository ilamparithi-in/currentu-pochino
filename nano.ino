const uint8_t sensePin = 6;        // D6 digital input
const uint8_t ledPin   = 13;       // Indicator LED
const unsigned long debounce = 50; // milliseconds

// false = OFF, true = ON
bool lastStableState = false;
bool lastRawState    = false;
unsigned long lastChangeTime = 0;

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(sensePin, INPUT); 
  Serial.begin(115200); // Start Serial Connection

  // Startup Chime! [onboard LED]
  digitalWrite(ledPin, HIGH); delay(500); digitalWrite(ledPin, LOW);
  for (int i = 0; i < 10; i++) {
    delay(20); digitalWrite(13, HIGH); delay(50); digitalWrite(13, LOW);
  }
  delay(500); digitalWrite(13, HIGH); delay(100); digitalWrite(13, LOW);

  Serial.println("HI"); // Initial message
}

void loop() {
  bool rawState = digitalRead(sensePin);
  unsigned long now = millis();

  if (rawState != lastRawState) {
    lastChangeTime = now;
    lastRawState = rawState;
  }

  if ((now - lastChangeTime) >= debounce) {
    if (lastStableState != rawState) {
      lastStableState = rawState;

      digitalWrite(ledPin, lastStableState ? HIGH : LOW);
      Serial.println(lastStableState ? "ON" : "OFF");
    }
  }
}