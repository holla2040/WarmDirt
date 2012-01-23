#include "WProgram.h"
#include <stdint.h>
#include <util/crc16.h>
#include <avr/eeprom.h>

#include "WarmDirt.h"
#include "DHT.h"
#include "Stepper.h"

#define DHTPIN  9
#define DHTTYPE DHT11 

#define STX         2
#define ETX         3

enum {EETC,EETSP,EETH};

DHT dht(DHTPIN, DHTTYPE);
Stepper stepper(15,PINMOTORAIN,PINMOTORBIN);

WarmDirt::WarmDirt(double srhd, double srpd, double srbi, double srbe, double sra0, double sra1) {
    seriesResistorHeatedDirt   = srhd;
    seriesResistorPottedDirt   = srpd;
    seriesResistorBoxInterior  = srbi;
    seriesResistorBoxExterior  = srbe;
    seriesResistorAux0         = sra0;
    seriesResistorAux1         = sra1;

    pinMode(PINLIDSWITCH,   INPUT);
    pinMode(PINACTIVITY,    OUTPUT);

    pinMode(PINLOAD0ENABLE, OUTPUT);
    pinMode(PINLOAD1ENABLE, OUTPUT);

/* motor driver can drive 2 servos or 1 stepper */
    pinMode(PINMOTORAIN,        OUTPUT);
    pinMode(PINMOTORAENABLE,    OUTPUT); /* pwm */
    pinMode(PINMOTORBIN,        OUTPUT); 
    pinMode(PINMOTORBENABLE,    OUTPUT); /* pwm */

    digitalWrite(PINACTIVITY, HIGH);

    load0Off(); 
    load1Off(); 

    motorASpeed(0);
    motorBSpeed(0);
    stepperSpeed(100);

    setPwmFrequency(F977); /* arduino code sets to F977 for millis and delay to function, change at your own risk */

    dht.begin();

    //eeprom_write_byte(0, '2');
    //id = eeprom_read_byte(0);
}

uint16_t WarmDirt::adcaverage(uint8_t pin, uint16_t samples) {
    uint32_t sum = 0;
    uint16_t i;

    for (i = 0; i < samples; i++) {
        sum += analogRead(pin);
        delay(5);
    }
    return sum / samples;
}

double  WarmDirt::adctotemp(uint16_t adc, double seriesResistance) {
    double steinhart;
    double thermalr;

    thermalr = 1023.0 / float(adc) - 1;
    thermalr = seriesResistance / thermalr;
 
    steinhart = thermalr / THERMISTORNOMINAL;         // (R/Ro)
    steinhart = log(steinhart);                       // ln(R/Ro)
    steinhart /= BCOEFFICIENT;                        // 1/B * ln(R/Ro)
    steinhart += 1.0 / (TEMPERATURENOMINAL + 273.15); // + (1/To)
    steinhart = 1.0 / steinhart;                      // Invert
    steinhart -= 273.15;                              // convert to C
    steinhart = ctof(steinhart);                      // convert to f
    return steinhart;
}

double WarmDirt::ctof(double c) {
    return 9.0*c/5.0+32.0; 
}

double  WarmDirt::getHeatedDirtTemperature() {
    return adctotemp(adcaverage(PINHEATEDDIRT,SAMPLES),seriesResistorHeatedDirt);
}

double  WarmDirt::getPottedDirtTemperature() {
    return adctotemp(adcaverage(PINPOTTEDDIRT,SAMPLES),seriesResistorPottedDirt);
}

double  WarmDirt::getBoxInteriorTemperature() {
    return adctotemp(adcaverage(PINBOXINTERIOR,SAMPLES),seriesResistorBoxInterior);
}

double  WarmDirt::getBoxExteriorTemperature() {
    return adctotemp(adcaverage(PINBOXEXTERIOR,SAMPLES),seriesResistorBoxExterior);
}

double  WarmDirt::getAux0Temperature() {
    return adctotemp(adcaverage(PINAUX0,SAMPLES),seriesResistorAux0);
}

double  WarmDirt::getAux1Temperature() {
    return adctotemp(adcaverage(PINAUX1,SAMPLES),seriesResistorAux1);
}

/* ref http://www.ladyada.net/learn/sensors/cds.html */
uint16_t  WarmDirt::getLightSensor() {
    return adcaverage(PINLIGHTSENSOR,SAMPLES);
}

boolean WarmDirt::getLidSwitchClosed() {
    return !digitalRead(PINLIDSWITCH);
}

/* ref http://www.ladyada.net/learn/sensors/dht.html */
double  WarmDirt::getDHTTemperature() {
    return ctof(dht.readTemperature());
}

double  WarmDirt::getDHTHumidity() {
    return dht.readHumidity();
}

double  WarmDirt::getLoadCurrent() {
    return adcaverage(PINLOADCURRENT,SAMPLES);
}

void    WarmDirt::load0Off() {
    digitalWrite(PINLOAD0ENABLE,HIGH);
}

void    WarmDirt::load0On() {
    digitalWrite(PINLOAD0ENABLE,LOW);
}

boolean WarmDirt::getLoad0On() {
    return !digitalRead(PINLOAD0ENABLE);
}

void    WarmDirt::load1Off() {
    digitalWrite(PINLOAD1ENABLE,HIGH);
}

void    WarmDirt::load1On() {
    digitalWrite(PINLOAD1ENABLE,LOW);
}

boolean WarmDirt::getLoad1On() {
    return !digitalRead(PINLOAD1ENABLE);
}

void    WarmDirt::activityToggle() {
    digitalWrite(PINACTIVITY,!digitalRead(PINACTIVITY));
}

int8_t  WarmDirt::motorASpeed(int8_t speed) {
    uint8_t duty;
    if (speed > 100) {
        speed = 100;
    }
    if (speed < -100) {
        speed = -100;
    }

    if (speed == 0) {
        digitalWrite(PINMOTORAENABLE,LOW);
    } else {
        if (speed > 0) {
            digitalWrite(PINMOTORAIN,HIGH);
        } else {
            digitalWrite(PINMOTORAIN,LOW);
        }
        duty = map(abs(speed), 0, 100, 0, 255);
        //Serial.println(duty,DEC);
        analogWrite(PINMOTORAENABLE,duty);
    }
    return speed;
}
    

int8_t  WarmDirt::motorBSpeed(int8_t speed) {
    uint8_t duty;
    if (speed > 100) {
        speed = 100;
    }
    if (speed < -100) {
        speed = -100;
    }

    if (speed == 0) {
        digitalWrite(PINMOTORBENABLE,LOW);
    } else {
        if (speed > 0) {
            digitalWrite(PINMOTORBIN,HIGH);
        } else {
            digitalWrite(PINMOTORBIN,LOW);
        }
        duty = map(abs(speed), 0, 100, 0, 255);
        //Serial.println(duty,DEC);
        analogWrite(PINMOTORBENABLE,duty);
    }
    return speed;
}

void    WarmDirt::setPwmFrequency(uint8_t frequency) {
    uint8_t mode;
    // timer 0 - 5,6  62500Hz
    switch (frequency) {
        case F62500:
            mode = 0x01;
            break;
        case F7813:
            mode = 0x02;
            break;
        case F977:
            mode = 0x03;
            break;
        case F244:
            mode = 0x04;
            break;
        case F61:
            mode = 0x05;
            break;
    }
    TCCR0B = (TCCR0B & 0b11111000) | mode; // Timer 0
}

void WarmDirt::stepperSpeed(int32_t speed) {
    stepper.setSpeed(speed);
}

void WarmDirt::stepperStep(int16_t steps) {
    stepper.step(steps);
}

void WarmDirt::stepperEnable() {
    analogWrite(PINMOTORAENABLE,200);
    analogWrite(PINMOTORBENABLE,200);
    //digitalWrite(PINMOTORAENABLE,HIGH);
    //digitalWrite(PINMOTORBENABLE,HIGH);
}

void WarmDirt::stepperDisable() {
    analogWrite(PINMOTORAENABLE,0);
    analogWrite(PINMOTORBENABLE,0);
    //digitalWrite(PINMOTORAENABLE,LOW);
    //digitalWrite(PINMOTORBENABLE,LOW);
}

void WarmDirt::sendString(char *str) {
    Serial.print(str);
}

/* packet - simple
   STX LENGTH ADDRESS TYPE str CHECKSUM ETX
    LENGTH 
        str length only
    TYPE
        b broadcast
        r reply
        m message 
    CHECKSUM
        sum of all bytes except STX and ETX
*/
void WarmDirt::sendPacket(uint8_t address, char type, char *str) {
    uint8_t checksum = address;
    char *ptr = str;

    Serial.print(">");
    Serial.print(str);
    Serial.println("<");
    
    delay(100);

    Serial.print(STX);
    Serial.print(strlen(str)+2);
    Serial.print(address);
    Serial.print(type);
    while (*ptr) {
        Serial.write(*ptr);
        checksum += *ptr;
        ptr++;
    }
    Serial.print(checksum);
    Serial.print(ETX);
    Serial.println(); // make it readable
}

void WarmDirt::sendPacketKeyValue(uint8_t address, char type, char *key, char *value) {
    char buffer[100];
    sprintf(buffer,"%s=%s",key,value);
    sendPacket(address,type,buffer);
} 

void WarmDirt::temperatureLoop() {
    double pd = getPottedDirtTemperature();

    if (temperatureControl) {
        if (pd < (temperatureSetPoint - temperatureHysteresis)) {
            load0On();
        }
        if (pd > (temperatureSetPoint + temperatureHysteresis)) {
            load0Off();
        }

    }
}

void WarmDirt::loop() {
    temperatureLoop();
} 


void WarmDirt::setTemperatureControl(boolean value){
    temperatureControl = value;
}

void WarmDirt::setTemperatureSetPoint(int8_t value, int8_t hysteresis) {
    temperatureControl = 1;
    temperatureSetPoint = value;
    temperatureHysteresis = hysteresis;
}

int8_t WarmDirt::getTemperatureSetPoint() {
    return temperatureSetPoint;
}
