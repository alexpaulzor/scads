// Pendulum pulse: drives a DC solid-state relay (SSR) on pin 8 with a fixed period and on-time.
// Wiring: pin 8 -> SSR IN+, GND -> SSR IN-.
// Tune live from the Serial Monitor (9600 baud, "Newline" line ending):
//   p2030  -> period 2030 ms        o500 -> on-time 500 ms        ?  -> print the settings
// When it's dialled in, copy the numbers into the two defaults below so it starts that way.

const int SSR_PIN = 8;
unsigned long periodMs = 2000;   // one push per full swing
unsigned long onMs = 500;        // 25 % of 2000

unsigned long cycleStart = 0;

void report() {
  Serial.print("period "); Serial.print(periodMs);
  Serial.print(" ms, on "); Serial.print(onMs);
  Serial.print(" ms ("); Serial.print(100.0 * onMs / periodMs, 1); Serial.println(" %)");
}

void setup() {
  pinMode(SSR_PIN, OUTPUT);
  Serial.begin(9600);
  report();
}

void loop() {
  if (Serial.available()) {
    char cmd = Serial.read();
    long v = Serial.parseInt();
    if (cmd == 'p' && v > 0) periodMs = v;
    if (cmd == 'o' && v >= 0) onMs = v;
    if (onMs > periodMs) onMs = periodMs;
    if (cmd == 'p' || cmd == 'o' || cmd == '?') report();
  }
  unsigned long t = millis() - cycleStart;
  if (t >= periodMs) { cycleStart += periodMs; t -= periodMs; }
  digitalWrite(SSR_PIN, t < onMs ? HIGH : LOW);
}
