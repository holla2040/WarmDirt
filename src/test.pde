#include "WarmDirt.h"
#include <stdint.h>

WarmDirt wd;

void setup() {                
    Serial.begin(57600);
    Serial.println("warmdirt begin");
}

void loop() {
    Serial.print(wd.getHeatedDirtTemperature(),0);
    Serial.print(" ");
    Serial.print(wd.getPottedDirtTemperature(),0);
    Serial.print(" ");
    Serial.print(wd.getBoxInteriorTemperature(),0);
    Serial.print(" ");
    Serial.print(wd.getBoxExteriorTemperature(),0);
    Serial.print(" ");
    Serial.println(wd.getLightSensor());
    delay(500);
}

