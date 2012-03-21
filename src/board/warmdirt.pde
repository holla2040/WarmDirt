#include <stdint.h>
#include "WarmDirt.h"
#include "PID_v1.h"

#define STATUSUPDATEINVTERVAL   30000
#define ACTIVITYUPDATEINVTERVAL 500

int lightstate;
#define LIGHTONDURATION             72000L
#define LIGHTTHRESHOLD              500
#define STATELIGHTABOVETHRESHOLD    'a'
#define STATELIGHTON                '1'
#define STATELIGHTOFF               '0'
#define STATELIGHTTEMPON            't'
#define STATELIGHTTEMPONDURATION    600000L

#define LIDUPTHRESHOLD              44.0 
#define LIDDOWNTHRESHOLD            42.5
#define LIDMOVINGTIME               400000L
#define LIDSTATEDOWN                'd'
#define LIDSTATEMOVINGDOWN          'v'
#define LIDSTATEMOVINGUP            '^'
#define LIDSTATEUP                  'u'
uint8_t lidstate;
uint32_t lidMovingTimeout;

uint32_t lightUpdate;

extern PID pid;
double settemp = 55.0;

double pdpidsetpoint, pdpidinput, pdpidoutput;
PID pdpid(&pdpidinput, &pdpidoutput, &pdpidsetpoint,5,0.001,0.01,DIRECT);


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
    wd.setTemperatureSetPoint(settemp,1);
    lightstate = STATELIGHTOFF;
    pdpid.SetOutputLimits(50,65);
    pdpid.SetMode(AUTOMATIC);
    pdpidsetpoint = 48.0;
    lidstate = LIDSTATEDOWN;
}



void commProcess(int c) {
    switch (c) {
        case 's':
            nextIdleStatusUpdate = 0;
            break;
        case 'R':
            reset();
            break;
        case '5':
            settemp -= 1;
            wd.setTemperatureSetPoint(settemp,1);
            nextIdleStatusUpdate = 0;
            break;
        case '6':
            settemp += 1;
            wd.setTemperatureSetPoint(settemp,1);
            nextIdleStatusUpdate = 0;
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
                        lightstate = STATELIGHTOFF;
                    }
                    if (c == '1') {
                        wd.load1On();
                        lightstate = STATELIGHTTEMPON;
                        lightUpdate = millis() + STATELIGHTTEMPONDURATION;
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
        case 'd':
            speedB = -100;
            speedB = wd.motorBSpeed(speedB);
            lidMovingTimeout = millis() + LIDMOVINGTIME;
            lidstate = LIDSTATEMOVINGDOWN;
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
    uint32_t temp;
    uint32_t now = millis();
    double hd,pd,bi,be,lc,hum,ot;
    if (now > nextActivityUpdate) {
        wd.activityToggle();
        nextActivityUpdate = now + ACTIVITYUPDATEINVTERVAL;
    }

    if (now > nextIdleStatusUpdate) {
        hd  = wd.getHeatedDirtTemperature();
        pd  = wd.getPottedDirtTemperature();
        bi  = wd.getBoxInteriorTemperature();
        be  = wd.getBoxExteriorTemperature();
        ot  = wd.getAux0Temperature();
        lc  = wd.getLoadACCurrent();
//      hum = wd.getDHTHumidity();

        sprintf(buffer,"%ld",now);
        wd.sendPacketKeyValue(address,KV,"/data/uptime",buffer);

        ftoa(buffer,wd.getTemperatureSetPoint(),2);
        wd.sendPacketKeyValue(address,KV,"/data/temperaturesetpoint",buffer);
        delay(100);

        ftoa(buffer,hd,2);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureheateddirt",buffer);
        delay(100);

        ftoa(buffer,pd,2);
        wd.sendPacketKeyValue(address,KV,"/data/temperaturepotteddirt",buffer);
        delay(100);

        ftoa(buffer,bi,2);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureboxinterior",buffer);
        delay(100);

        ftoa(buffer,be,2);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureboxexterior",buffer);
        delay(100);

        ftoa(buffer,ot,2);
        wd.sendPacketKeyValue(address,KV,"/data/temperatureoutside",buffer);
        delay(100);


        sprintf(buffer,"%d",wd.getLightSensor());
        wd.sendPacketKeyValue(address,KV,"/data/lightlevel",buffer);
        delay(100);


        sprintf(buffer,"%d",wd.getLidSwitchClosed());
        wd.sendPacketKeyValue(address,KV, "/data/lidclosed",buffer);
        delay(100);

        if ((lidstate == LIDSTATEMOVINGUP) || (lidstate == LIDSTATEMOVINGDOWN)) {
            temp = lidMovingTimeout - millis();
            sprintf(buffer,"%ld", temp);
            wd.sendPacketKeyValue(address,KV,"/data/lidmovingtimeout",buffer);
            delay(100);
        }

        switch (lidstate) {
            case LIDSTATEDOWN:
                sprintf(buffer,"closed");
                break;
            case LIDSTATEMOVINGUP:
                sprintf(buffer,"opening %ds",temp/1000);
                break;
            case LIDSTATEUP:
                sprintf(buffer,"open");
                break;
            case LIDSTATEMOVINGDOWN:
                sprintf(buffer,"closing %ds",temp/1000);
                break;
        }
        wd.sendPacketKeyValue(address,KV,"/data/lidstate",buffer);
        delay(100);
        
        sprintf(buffer,"%d",wd.bencodercount);
        wd.sendPacketKeyValue(address,KV, "/data/lidencodercount",buffer);
        delay(100);


        sprintf(buffer,"%d",speedB);
        wd.sendPacketKeyValue(address,KV,"/data/lidmotorspeed",buffer);
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

        ftoa(buffer,wd.getPIDOutput(),2);
        wd.sendPacketKeyValue(address,KV,"/data/pidoutput",buffer);
        delay(100);

/*
        ftoa(buffer,pid.ppart,2);
        wd.sendPacketKeyValue(address,KV,"/data/pidp",buffer);
        delay(100);

        ftoa(buffer,pid.ipart,2);
        wd.sendPacketKeyValue(address,KV,"/data/pidi",buffer);
        delay(100);

        ftoa(buffer,pid.dpart,2);
        wd.sendPacketKeyValue(address,KV,"/data/pidd",buffer);
        delay(100);

        ftoa(buffer,pdpidoutput,2);
        wd.sendPacketKeyValue(address,KV,"/data/pdpidoutput",buffer);
        delay(100);

        ftoa(buffer,pdpid.ppart,2);
        wd.sendPacketKeyValue(address,KV,"/data/pdpidp",buffer);
        delay(100);

        ftoa(buffer,pdpid.ipart,2);
        wd.sendPacketKeyValue(address,KV,"/data/pdpidi",buffer);
        delay(100);

        ftoa(buffer,pdpid.ipartraw,2);
        wd.sendPacketKeyValue(address,KV,"/data/pdpidiraw",buffer);
        delay(100);

        ftoa(buffer,pdpid.dpart,2);
        wd.sendPacketKeyValue(address,KV,"/data/pdpidd",buffer);
        delay(100);
*/

        switch (lightstate) {
            case STATELIGHTON:
                sprintf(buffer,"timed on %ds",(lightUpdate - millis())/1000);
                break;
            case STATELIGHTOFF:
                sprintf(buffer,"off");
                break;
            case STATELIGHTTEMPON:
                sprintf(buffer,"temp on %ds",(lightUpdate - millis())/1000);
                break;
            case STATELIGHTABOVETHRESHOLD:
                sprintf(buffer,"sunlight %d",wd.getLightSensor());
                break;
        }
        wd.sendPacketKeyValue(address,KV,"/data/lightstate",buffer);
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

void lightLoop() {
    int l = wd.getLightSensor();
    if (l > (LIGHTTHRESHOLD + 150)) { // 150 is larger than light contribution
        lightstate = STATELIGHTABOVETHRESHOLD;
        wd.load1Off();
        return;
    }
    if (lightstate == STATELIGHTABOVETHRESHOLD) {
        if (l < LIGHTTHRESHOLD) {
            wd.load1On();
            lightstate = STATELIGHTON;
            lightUpdate = millis() + LIGHTONDURATION;
        }
    }
    if (lightstate == STATELIGHTON || lightstate == STATELIGHTTEMPON) {
        if (millis() > lightUpdate) {
            wd.load1Off();
            lightstate = STATELIGHTOFF;
        }
    }
}

void temperatureLoop() {
    pdpidinput = wd.getPottedDirtTemperature();
    pdpid.Compute();
    wd.setTemperatureSetPoint(pdpidoutput,1);
}

void lidLoop() {
    double be  = wd.getBoxExteriorTemperature();
    switch (lidstate) {
        case LIDSTATEDOWN:
            if ( be > LIDUPTHRESHOLD ) {
                speedB = 100;
                speedB = wd.motorBSpeed(speedB);
                lidMovingTimeout = millis() + LIDMOVINGTIME;
                lidstate = LIDSTATEMOVINGUP;
            }
            break;
        case LIDSTATEMOVINGUP:
            if (millis() > lidMovingTimeout) {
                speedB = 0;
                speedB = wd.motorBSpeed(speedB);
                lidstate = LIDSTATEUP;
            }
            break;
        case LIDSTATEUP:
            if ( be < LIDDOWNTHRESHOLD ) {
                speedB = -100;
                speedB = wd.motorBSpeed(speedB);
                lidMovingTimeout = millis() + LIDMOVINGTIME;
                lidstate = LIDSTATEMOVINGDOWN;
            }
            break;
        case LIDSTATEMOVINGDOWN:
            if (millis() > lidMovingTimeout) {
                speedB = 0;
                speedB = wd.motorBSpeed(speedB);
                lidstate = LIDSTATEDOWN;
            }
            break;
    }
}

void loop() {
    statusLoop();
    commLoop();
    wd.loop();
    lightLoop();
    temperatureLoop();
    lidLoop();
}
