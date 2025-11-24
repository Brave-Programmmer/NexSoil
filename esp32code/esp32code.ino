/*
  ✅ ESP32-CAM Bluetooth Frame Streamer + LED Control (Power-Optimized)
  --------------------------------------------------------------------
  - Streams JPEG frames via Bluetooth SPP
  - Accepts LED_ON / LED_OFF commands from app
  - All unnecessary Wi-Fi / background tasks disabled
  - Low power + stable + minimal delay
*/

#include "esp_camera.h"
#include "BluetoothSerial.h"
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "esp_wifi.h"
#include "esp_bt.h"

// ======= CAMERA CONFIG (AI Thinker Board) =======
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22
#define LED_PIN            4   // Onboard Flash LED

BluetoothSerial SerialBT;

// =======================================================
// ✅ CAMERA INIT
// =======================================================
bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0       = Y2_GPIO_NUM;
  config.pin_d1       = Y3_GPIO_NUM;
  config.pin_d2       = Y4_GPIO_NUM;
  config.pin_d3       = Y5_GPIO_NUM;
  config.pin_d4       = Y6_GPIO_NUM;
  config.pin_d5       = Y7_GPIO_NUM;
  config.pin_d6       = Y8_GPIO_NUM;
  config.pin_d7       = Y9_GPIO_NUM;
  config.pin_xclk     = XCLK_GPIO_NUM;
  config.pin_pclk     = PCLK_GPIO_NUM;
  config.pin_vsync    = VSYNC_GPIO_NUM;
  config.pin_href     = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn     = PWDN_GPIO_NUM;
  config.pin_reset    = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if (psramFound()) {
    config.frame_size   = FRAMESIZE_QVGA; // 320x240
    config.jpeg_quality = 12;
    config.fb_count     = 2;
  } else {
    config.frame_size   = FRAMESIZE_QQVGA; // 160x120
    config.jpeg_quality = 20;
    config.fb_count     = 1;
  }

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("❌ Camera init failed (0x%x)\n", err);
    return false;
  }

  sensor_t *s = esp_camera_sensor_get();
  s->set_brightness(s, 1);
  s->set_contrast(s, 1);
  s->set_saturation(s, 1);
  s->set_hmirror(s, 1);
  s->set_vflip(s, 0);

  Serial.println("✅ Camera initialized");
  return true;
}

// =======================================================
// ✅ BLUETOOTH INIT (Minimal + Safe)
// =======================================================
void initBluetooth() {
  // Disable Wi-Fi & BT discovery to reduce power and lag
  esp_wifi_stop();
  esp_wifi_deinit();
  btStop();           // Ensure no old BT stack active
  btStart();          // Restart clean BT stack
  esp_bt_dev_set_device_name("ESP32CAM_BT");

  if (!SerialBT.begin("ESP32CAM_BT", true)) {
    Serial.println("❌ Bluetooth init failed!");
    delay(3000);
    ESP.restart();
  }

  Serial.println("✅ Bluetooth ready: ESP32CAM_BT");
  Serial.println("📱 Commands: LED_ON / LED_OFF");
}

// =======================================================
// ✅ FRAME STREAM FUNCTION
// =======================================================
void sendFrame() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("⚠️ Frame capture failed");
    return;
  }

  SerialBT.printf("FRAME_START:%u\n", fb->len);
  const size_t CHUNK = 512;
  size_t sent = 0;

  while (sent < fb->len) {
    if (!SerialBT.hasClient()) break;
    size_t n = min(CHUNK, fb->len - sent);
    SerialBT.write(fb->buf + sent, n);
    sent += n;
    delay(1);
  }

  SerialBT.println("FRAME_END");
  esp_camera_fb_return(fb);
}

// =======================================================
// ✅ COMMAND HANDLER (LED ON/OFF)
// =======================================================
void handleCommand(String cmd) {
  cmd.trim();
  cmd.toUpperCase();

  if (cmd == "LED_ON") {
    digitalWrite(LED_PIN, HIGH);
    SerialBT.println("💡 LED ON");
  } 
  else if (cmd == "LED_OFF") {
    digitalWrite(LED_PIN, LOW);
    SerialBT.println("💡 LED OFF");
  }
}

// =======================================================
// ✅ SETUP
// =======================================================
void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.println("\n🚀 ESP32-CAM Bluetooth Streamer (Optimized)");

  if (!initCamera()) {
    Serial.println("Restarting...");
    delay(2000);
    ESP.restart();
  }

  initBluetooth();

  // Disable power-hungry services
  esp_bt_gap_set_scan_mode(ESP_BT_NON_CONNECTABLE, ESP_BT_NON_DISCOVERABLE);
  esp_bt_sleep_enable(); // enable BT light sleep
  Serial.println("⚙️ Power-saving active");
}

// =======================================================
// ✅ MAIN LOOP
// =======================================================
void loop() {
  static unsigned long lastFrame = 0;

  if (SerialBT.available()) {
    String cmd = SerialBT.readStringUntil('\n');
    handleCommand(cmd);kj
  }

  if (SerialBT.hasClient()) {
    unsigned long now = millis();
    if (now - lastFrame > 700) {
      sendFrame();
      lastFrame = now;
    }
  } else {
    delay(200);
  }
}
