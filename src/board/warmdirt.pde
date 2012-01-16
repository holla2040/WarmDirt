#include <stdint.h>
#include "WarmDirt.h"

#define STATUSUPDATEINVTERVAL   15000
#define ACTIVITYUPDATEINVTERVAL 500

#define STX         2
#define ETX         3

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
    Serial.write(STX);
    Serial.println("1/data/begin=1");
    Serial.write(ETX);
}

void commProcess(int c) {
    switch (c) {
        case 's':
            nextIdleStatusUpdate = 0;
            break;
        case 'R':
            reset();
            break;
        case 'a':
            Serial.print("a");
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
            wd.stepperDisable();
            break;
        case '0': // avrdude sends 0-space 
            while (!Serial.available()) ;
            c = Serial.read();
            if (c == ' ') {
                reset();
            }
            break;
        case 'w':
            Serial.println("stepper backward");
            wd.stepperSpeed(100);
            wd.stepperEnable();
            delay(10);
            wd.stepperStep(-237);
            delay(10);
            wd.stepperDisable();
            break;
        case 'r':
            Serial.println("stepper forward");
            wd.stepperSpeed(100);
            wd.stepperEnable();
            delay(10);
            wd.stepperStep(237);
            delay(10);
            wd.stepperDisable();
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

        Serial.write(STX);
        Serial.print("1/data/uptime=");
        Serial.println(now,DEC);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/temperatureheateddirt=");
        Serial.println(hd,1);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/temperaturepotteddirt=");
        Serial.println(pd,1);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/temperatureboxinterior=");
        Serial.println(bi,1);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/temperatureboxexterior=");
        Serial.println(be,1);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/lightlevel=");
        Serial.println(wd.getLightSensor());
        Serial.write(ETX);
        delay(200);
/*
        Serial.write(STX);
        Serial.print("1/data/humidity=");
        Serial.println(hum,1);
        Serial.write(ETX);
        delay(200);
*/

        Serial.write(STX);
        Serial.print("1/data/lidswitch=");
        Serial.println(wd.getLidSwitchClosed(),DEC);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/load0on=");
        Serial.println(wd.getLoad0On(),DEC);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/load1on=");
        Serial.println(wd.getLoad1On(),DEC);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/loadcurrent=");
        Serial.println(lc,1);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/motoraspeed=");
        Serial.println(speedA,DEC);
        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("1/data/motorbspeed=");
        Serial.println(speedB,DEC);
        Serial.write(ETX);
        delay(200);

        nextIdleStatusUpdate = millis() + STATUSUPDATEINVTERVAL;
    }
}

void loop() {
    statusLoop();
    commLoop();
}

