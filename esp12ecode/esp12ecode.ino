/*
  ✅ NexSoil Rover (Stable ESP8266 Version)
  -----------------------------------------
  - Wi-Fi Access Point Mode
  - DHT11 (Temp/Humidity)
  - Soil Moisture Sensor (Analog)
  - L298N Motor Driver (Dual Motor)
  - Safe pins, stable boot, no resets
*/

#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <DHT.h>

// ========================= CONFIG =========================
const char AP_SSID[] = "NexSoil_Rover";
const char AP_PASS[] = "12345678";

#define DHTPIN 2  // D4 (safe for DHT11)
#define DHTTYPE DHT11
#define SOIL_PIN A0

DHT dht(DHTPIN, DHTTYPE);
ESP8266WebServer server(80);

// ========================= L298N Motor Pins =========================
// ⚙️ Safe GPIOs for boot and motor
#define IN1 5   // D1 - Left Forward
#define IN2 4   // D2 - Left Backward
#define ENA 14  // D5 - Left Enable (PWM)
#define IN3 12  // D6 - Right Forward
#define IN4 13  // D7 - Right Backward
#define ENB 16  // D0 - Right Enable (no PWM, ON/OFF only)

// ========================= Motor Helper =========================
void setMotor(int in1, int in2, int en, int dir) {
  if (dir == 1) {  // Forward
    digitalWrite(in1, HIGH);
    digitalWrite(in2, LOW);
  } else if (dir == -1) {  // Backward
    digitalWrite(in1, LOW);
    digitalWrite(in2, HIGH);
  } else {  // Stop
    digitalWrite(in1, LOW);
    digitalWrite(in2, LOW);
  }

  // Enable line handling
  if (en == 16) digitalWrite(en, HIGH);  // D0 has no PWM
  else analogWrite(en, 1023);            // Full speed PWM
}

// ========================= Movement =========================
void stopAll() {
  setMotor(IN1, IN2, ENA, 0);
  setMotor(IN3, IN4, ENB, 0);
}

void forward() {
  setMotor(IN1, IN2, ENA, 1);
  setMotor(IN3, IN4, ENB, 1);
}

void backward() {
  setMotor(IN1, IN2, ENA, -1);
  setMotor(IN3, IN4, ENB, -1);
}

void leftTurn() {
  setMotor(IN1, IN2, ENA, -1);
  setMotor(IN3, IN4, ENB, 1);
}

void rightTurn() {
  setMotor(IN1, IN2, ENA, 1);
  setMotor(IN3, IN4, ENB, -1);
}

// ========================= Sensor Helpers =========================
float readStableTemp() {
  float t = 0;
  int count = 0;
  for (int i = 0; i < 5; i++) {
    float v = dht.readTemperature();
    if (!isnan(v)) {
      t += v;
      count++;
    }
    delay(30);
  }
  return (count > 0) ? t / count : -99.0;
}

float readStableHum() {
  float h = 0;
  int count = 0;
  for (int i = 0; i < 5; i++) {
    float v = dht.readHumidity();
    if (!isnan(v)) {
      h += v;
      count++;
    }
    delay(30);
  }
  return (count > 0) ? h / count : -99.0;
}

int readStableSoil() {
  long sum = 0;
  for (int i = 0; i < 5; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  int soil = sum / 5;
  soil = constrain(map(soil, 1023, 300, 0, 100), 0, 100);
  return soil;
}

// ========================= Web Handlers =========================
void handleRoot() {
  String html = "<html><head><title>NexSoil Rover</title>"
                "<meta name='viewport' content='width=device-width, initial-scale=1.0'></head>"
                "<body style='font-family:sans-serif;text-align:center;'>"
                "<h2>🚜 NexSoil Rover Control</h2>"
                "<p><a href='/control?cmd=FORWARD'><button>FORWARD</button></a></p>"
                "<p><a href='/control?cmd=LEFT'><button>LEFT</button></a>"
                "<a href='/control?cmd=STOP'><button>STOP</button></a>"
                "<a href='/control?cmd=RIGHT'><button>RIGHT</button></a></p>"
                "<p><a href='/control?cmd=BACKWARD'><button>BACKWARD</button></a></p>"
                "<hr><p><a href='/status'><button>Check Sensors</button></a></p>"
                "</body></html>";
  server.send(200, "text/html", html);
}

void handleControl() {
  if (!server.hasArg("cmd")) {
    server.send(400, "text/plain", "Missing cmd argument");
    return;
  }

  String cmd = server.arg("cmd");
  cmd.toUpperCase();

  if (cmd == "FORWARD") forward();
  else if (cmd == "BACKWARD") backward();
  else if (cmd == "LEFT") leftTurn();
  else if (cmd == "RIGHT") rightTurn();
  else stopAll();

  server.send(200, "text/plain", "CMD: " + cmd);
}

void handleStatus() {
  float t = readStableTemp();
  float h = readStableHum();
  int s = readStableSoil();

  String data = "{\"temp\":" + String(t, 1) + ",\"hum\":" + String(h, 1) + ",\"soil\":" + String(s) + "}";
  server.send(200, "application/json", data);
}

// ========================= Setup =========================
void setup() {
  Serial.begin(115200);
  delay(100);

  // Motor pins
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENB, OUTPUT);
  stopAll();

  // DHT & Wi-Fi
  dht.begin();
  Serial.println("\n🌐 Starting AP...");
  WiFi.softAP(AP_SSID, AP_PASS);
  delay(500);
  Serial.print("IP Address: ");
  Serial.println(WiFi.softAPIP());

  // Web handlers
  server.on("/", handleRoot);
  server.on("/control", handleControl);
  server.on("/status", handleStatus);
  server.begin();
  Serial.println("✅ Rover Server Ready!");
}

// ========================= Loop =========================
void loop() {
  server.handleClient();
}
