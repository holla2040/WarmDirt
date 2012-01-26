#include <stdint.h>
#include "WarmDirt.h"

#define STATUSUPDATEINVTERVAL   30000
#define ACTIVITYUPDATEINVTERVAL 500


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
    wd.setTemperatureSetPoint(53.0,1);
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
        lc  = wd.getLoadACCurrent();
//        hum = wd.getDHTHumidity();

        sprintf(buffer,"%ld",now);
        wd.sendPacketKeyValue(address,KV,"/data/uptime",buffer);

        sprintf(buffer,"%d",wd.getTemperatureSetPoint());
        wd.sendPacketKeyValue(address,KV,"/data/temperaturesetpoint",buffer);
        delay(100);

        ftoa(buffer,hd,1);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureheateddirt",buffer);
        delay(100);

        ftoa(buffer,pd,1);
        wd.sendPacketKeyValue(address,KV,"/data/temperaturepotteddirt",buffer);
        delay(100);

        ftoa(buffer,bi,1);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureboxinterior",buffer);
        delay(100);

        ftoa(buffer,be,1);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureboxexterior",buffer);
        delay(100);

        sprintf(buffer,"%d",wd.getLightSensor());
        wd.sendPacketKeyValue(address,KV,"/data/lightlevel",buffer);
        delay(100);




        sprintf(buffer,"%d",wd.getLidSwitchClosed());
        wd.sendPacketKeyValue(address,KV, "/data/lidswitch",buffer);
        delay(100);

        sprintf(buffer,"%d",wd.getLoad0On());
        wd.sendPacketKeyValue(address,KV,"/data/load0on",buffer);
        delay(100);

        sprintf(buffer,"%d",wd.getLoad1On());
        wd.sendPacketKeyValue(address,KV,"/data/load1on",buffer);
        delay(100);

        ftoa(buffer,lc,1);
        wd.sendPacketKeyValue(address,KV,"/data/loadcurrent",buffer);
        delay(100);

        ftoa(buffer,wd.getPIDOutput(),1);
        wd.sendPacketKeyValue(address,KV,"/data/pidoutput",buffer);
        delay(100);



/*
        ftoa(buffer,hum,1);
        wd.sendPacketKeyValue(address,KV,"/data/humidity",buffer);

        sprintf(buffer,"%d",speedA);
        wd.sendPacketKeyValue(address,KV,"/data/motoraspeed",buffer);

        sprintf(buffer,"%d",speedB);
        wd.sendPacketKeyValue(address,KV,"/data/motorbspeed",buffer);
*/


        nextIdleStatusUpdate = millis() + STATUSUPDATEINVTERVAL;
    }
}

void loop() {
    statusLoop();
    commLoop();
    wd.loop();
}

