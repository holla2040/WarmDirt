#include "WarmDirt.h"
#include <stdint.h>

#define STATUSUPDATEINVTERVAL   5000
#define ACTIVITYUPDATEINVTERVAL 500

uint32_t nextIdleStatusUpdate;
uint32_t nextActivityUpdate;

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
        case 'l':
            Serial.print("l");
            while (!Serial.available()) ;
            c = Serial.read();
            Serial.print((char)c);
            if (c == '0') {
                while (!Serial.available()) ;
                c = Serial.read();
                Serial.print((char)c);
                if (c == '0') {
                    wd.load0Off();
                }
                if (c == '1') {
                    wd.load0On();
                }
            } else {
                if (c == '1') {
                    while (!Serial.available()) ;
                    c = Serial.read();
                    Serial.print((char)c);
                    if (c == '0') {
                        wd.load1Off();
                    }
                    if (c == '1') {
                        wd.load1On();
                    }
                }
            }
            Serial.println();
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
    if (now > nextActivityUpdate) {
        wd.activityToggle();
        nextActivityUpdate = now + ACTIVITYUPDATEINVTERVAL;
    }

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
//        Serial.print(wd.getDHTTemperature(),0);
//        Serial.print(" ");
        Serial.print(wd.getDHTHumidity(),0);
        Serial.print(" ");
        Serial.print(wd.getLidSwitchClosed(),DEC);
        Serial.print(" ");
        Serial.print(wd.getLoad0On(),DEC);
        Serial.print(" ");
        Serial.print(wd.getLoad1On(),DEC);
        Serial.print(" ");
        Serial.print(wd.getLoadCurrent(),0);

        Serial.println();
        nextIdleStatusUpdate = now + STATUSUPDATEINVTERVAL;
    }
}

void loop() {
    statusLoop();
    commLoop();
}

