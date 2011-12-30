#include "WProgram.h"
#include <stdint.h>

#include "WarmDirt.h"
#include "DHT.h"

#define DHTPIN  9
#define DHTTYPE DHT11 

DHT dht(DHTPIN, DHTTYPE);

WarmDirt::WarmDirt(double srhd, double srpd, double srbi, double srbe, double sra0, double sra1) {
    _seriesResistorHeatedDirt   = srhd;
    _seriesResistorPottedDirt   = srpd;
    _seriesResistorBoxInterior  = srbi;
    _seriesResistorBoxExterior  = srbe;
    _seriesResistorAux0         = sra0;
    _seriesResistorAux1         = sra1;

    pinMode(PINLIDSWITCH,   INPUT);
    pinMode(PINACTIVITY,    OUTPUT);

    pinMode(PINLOAD0ENABLE, OUTPUT);
    pinMode(PINLOAD1ENABLE, OUTPUT);

    digitalWrite(PINACTIVITY, HIGH);

    load0Off(); 
    load1Off(); 

    dht.begin();
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
    return adctotemp(adcaverage(PINHEATEDDIRT,SAMPLES),_seriesResistorHeatedDirt);
}

double  WarmDirt::getPottedDirtTemperature() {
    return adctotemp(adcaverage(PINPOTTEDDIRT,SAMPLES),_seriesResistorPottedDirt);
}

double  WarmDirt::getBoxInteriorTemperature() {
    return adctotemp(adcaverage(PINBOXINTERIOR,SAMPLES),_seriesResistorBoxInterior);
}

double  WarmDirt::getBoxExteriorTemperature() {
    return adctotemp(adcaverage(PINBOXEXTERIOR,SAMPLES),_seriesResistorBoxExterior);
}

double  WarmDirt::getAux0Temperature() {
    return adctotemp(adcaverage(PINAUX0,SAMPLES),_seriesResistorAux0);
}

double  WarmDirt::getAux1Temperature() {
    return adctotemp(adcaverage(PINAUX1,SAMPLES),_seriesResistorAux1);
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

