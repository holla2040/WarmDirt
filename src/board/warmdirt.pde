#include <stdint.h>
#include "WarmDirt.h"

#define STATUSUPDATEINVTERVAL   15000
#define ACTIVITYUPDATEINVTERVAL 500

#define KV  'm'
#define STX         2
#define ETX         3

char *ftoa(char *a, double f, int precision) {
  long p[] = {0,10,100,1000,10000,100000,1000000,10000000,100000000};

  char *ret = a;
  long heiltal = (long)f;
  itoa(heiltal, a, 10);
  while (*a != '\0') a++;
  *a++ = '.';
  long desimal = abs((long)((f - heiltal) * p[precision]));
  itoa(desimal, a, 10);
  return ret;
}

uint32_t nextIdleStatusUpdate;
uint32_t nextActivityUpdate;

int8_t   speedA = 0;
int8_t   speedB = 0;

char     address = '1';

WarmDirt wd;

void reset() {
    asm volatile("jmp 0x3E00"); /* dont know where I got this but it works on 328 */
}

void setup() {                
    Serial.begin(57600);
    wd.sendPacketKeyValue(address,KV,"/data/setup","1");
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
            int i;
            Serial.println("stepper backward");
            wd.stepperSpeed(10);
            wd.stepperEnable();
            delay(10);
            wd.stepperStep(100);
            /*
            for (i = 0; i < 10; i++) { 
                wd.stepperStep(1);
                delay(10);
            }
            */
            delay(10);
            wd.stepperDisable();
            break;
        case 'r':
            Serial.println("stepper forward");
            wd.stepperSpeed(10);
            wd.stepperEnable();
            delay(10);
            wd.stepperStep(100);
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
    char buffer[30];
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

/*
        sprintf(buffer,"%ld",now);
        wd.sendPacketKeyValue(address,KV,"/data/uptime",buffer);
        delay(200);

        ftoa(buffer,hd,1);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureheateddirt=",buffer);
        delay(200);
*/

        Serial.write(STX);
        Serial.print("/data/uptime=");
        Serial.println(now);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/temperatureheateddirt=");
        Serial.println(hd,1);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/temperaturepotteddirt=");
        Serial.println(pd,1);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/temperatureboxinterior=");
        Serial.println(bi,1);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/temperatureboxexterior=");
        Serial.println(be,1);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/lightlevel=");
        Serial.println(wd.getLightSensor());
//        Serial.write(ETX);
        delay(200);

/*
        Serial.write(STX);
        Serial.print("/data/humidity=");
        Serial.println(hum,1);
        Serial.write(ETX);
        delay(200);
*/

        Serial.write(STX);
        Serial.print("/data/lidswitch=");
        Serial.println(wd.getLidSwitchClosed(),DEC);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/load0on=");
        Serial.println(wd.getLoad0On(),DEC);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/load1on=");
        Serial.println(wd.getLoad1On(),DEC);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/loadcurrent=");
        Serial.println(lc,1);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/motoraspeed=");
        Serial.println(speedA,DEC);
//        Serial.write(ETX);
        delay(200);

        Serial.write(STX);
        Serial.print("/data/motorbspeed=");
        Serial.println(speedB,DEC);
//        Serial.write(ETX);
        delay(200);

        nextIdleStatusUpdate = millis() + STATUSUPDATEINVTERVAL;
    }
}

void loop() {
    statusLoop();
    commLoop();
}

