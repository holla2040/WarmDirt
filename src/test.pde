#include "WarmDirt.h"
#include <stdint.h>

#define STATUSPDATEINVTERVAL    2000
uint32_t nextIdleStatusUpdate;

WarmDirt wd;

void reset() {
    asm volatile("jmp 0x3E00"); /* dont know where I got this but it works on 328 */
}

void setup() {                
    Serial.begin(57600);
    Serial.println("warmdirt begin");
}

void commProcess(int c) {
    switch (c) {
        case 'R':
            reset();
            break;
    }
}

void commLoop() {
    int c;
    if (Serial.available()) {
        c = Serial.read();
        commProcess(c);
    }
}

void statusLoop() {
    uint32_t now = millis();
    if (now > nextIdleStatusUpdate) {
        Serial.print(wd.getHeatedDirtTemperature(),0);
        Serial.print(" ");
        Serial.print(wd.getPottedDirtTemperature(),0);
        Serial.print(" ");
        Serial.print(wd.getBoxInteriorTemperature(),0);
        Serial.print(" ");
        Serial.print(wd.getBoxExteriorTemperature(),0);
        Serial.print(" ");
        Serial.print(wd.getLightSensor());
        Serial.print(" ");
        Serial.print(wd.getDHTTemperature(),0);
        Serial.print(" ");
        Serial.print(wd.getDHTHumidity(),0);
        Serial.println();
        nextIdleStatusUpdate = now + STATUSPDATEINVTERVAL;
    }
}

void loop() {
    statusLoop();
    commLoop();
}

