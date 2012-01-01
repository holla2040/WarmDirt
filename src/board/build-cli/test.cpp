#include "WProgram.h"
#include <stdint.h>
#include "WarmDirt.h"

#define STATUSUPDATEINVTERVAL   5000
#define ACTIVITYUPDATEINVTERVAL 500

uint32_t nextIdleStatusUpdate;
uint32_t nextActivityUpdate;

int8_t   speedA = 0;
int8_t   speedB = 0;

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
        case 'a':
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
        case 'i':
            speedB += MOTORSPEEDINC; 
            speedB = wd.motorBSpeed(speedB);
            Serial.print("b = ");
            Serial.println(speedB);
            break;
        case 'k':
            speedB -= MOTORSPEEDINC; 
            speedB = wd.motorBSpeed(speedB);
            Serial.print("b = ");
            Serial.println(speedB);
            break;
        case 'j':
            speedA += MOTORSPEEDINC; 
            speedA = wd.motorASpeed(speedA);
            Serial.print("a = ");
            Serial.println(speedA);
            break;
        case 'l':
            speedA -= MOTORSPEEDINC; 
            speedA = wd.motorASpeed(speedA);
            Serial.print("a = ");
            Serial.println(speedA);
            break;
        case ' ':
            Serial.println("full stop");
            speedA = 0;
            speedB = 0;
            wd.motorASpeed(speedA);
            wd.motorBSpeed(speedB);
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
    double hd,pd,bi,be,lc,hum;
    if (now > nextActivityUpdate) {
        wd.activityToggle();
        nextActivityUpdate = now + ACTIVITYUPDATEINVTERVAL;
    }

    if (now > nextIdleStatusUpdate) {
        hd  = wd.getHeatedDirtTemperature();
        pd  = wd.getPottedDirtTemperature();
        bi  = wd.getBoxInteriorTemperature();
        be  = wd.getBoxExteriorTemperature();
        lc  = wd.getLoadCurrent();
        hum = wd.getDHTHumidity();


        Serial.print(now,DEC);
        Serial.print(" ");
        Serial.print(hd,0);
        Serial.print(" ");
        Serial.print(pd,0);
        Serial.print(" ");
        Serial.print(bi,0);
        Serial.print(" ");
        Serial.print(be,0);
        Serial.print(" ");
        Serial.print(wd.getLightSensor());
        Serial.print(" ");
//        Serial.print(wd.getDHTTemperature(),0);
//        Serial.print(" ");
        Serial.print(hum,0);
        Serial.print(" ");
        Serial.print(wd.getLidSwitchClosed(),DEC);
        Serial.print(" ");
        Serial.print(wd.getLoad0On(),DEC);
        Serial.print(" ");
        Serial.print(wd.getLoad1On(),DEC);
        Serial.print(" ");
        Serial.print(lc,0);
        Serial.print(" ");
        Serial.print(speedA,DEC);
        Serial.print(" ");
        Serial.print(speedB,DEC);

        Serial.println();
        nextIdleStatusUpdate = now + STATUSUPDATEINVTERVAL;
    }
}

void loop() {
    statusLoop();
    commLoop();
}

