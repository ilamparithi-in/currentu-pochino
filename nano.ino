const uint8_t SENSE_PIN = 6; // D6 digital input
const uint8_t LED_INDICATE   = LED_BUILTIN; // Indicator LED
const unsigned long DEBOUNCE = 50;          // milliseconds

// false = OFF, true = ON
bool lastStableState = false;
bool lastRawState    = false;
unsigned long lastChangeTime = 0;

void startup_chime() {
  digitalWrite(LED_BUILTIN, HIGH); delay(500); digitalWrite(LED_BUILTIN, LOW);
  for (int i = 0; i < 10; i++) {
    delay(20); digitalWrite(LED_BUILTIN, HIGH); delay(50); digitalWrite(LED_BUILTIN, LOW);
  }
  delay(500); digitalWrite(LED_BUILTIN, HIGH); delay(100); digitalWrite(LED_BUILTIN, LOW);
}

void setup() {
  pinMode(LED_INDICATE, OUTPUT);
  pinMode(SENSE_PIN, INPUT); 
  Serial.begin(115200); // Start Serial Connection

  startup_chime();

  // Initialize state
  bool initial = digitalRead(SENSE_PIN);
  lastRawState    = initial;
  lastStableState = initial;

  digitalWrite(LED_INDICATE, initial ? HIGH : LOW);

  Serial.println("HI"); // Initial message
}

void loop() {
  bool rawState = digitalRead(SENSE_PIN);
  unsigned long now = millis();

  if (rawState != lastRawState) {
    lastChangeTime = now;
    lastRawState = rawState;
  }

  if ((now - lastChangeTime) >= DEBOUNCE) {
    if (lastStableState != rawState) {
      lastStableState = rawState;

      digitalWrite(LED_INDICATE, lastStableState ? HIGH : LOW);
      Serial.println(lastStableState ? "ON" : "OFF");
    }
  }
}