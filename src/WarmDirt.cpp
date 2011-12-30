#include "WProgram.h"
#include <stdint.h>

#include "WarmDirt.h"

WarmDirt::WarmDirt(double srhd, double srpd, double srbi, double srbe, double sra0, double sra1) {
    _seriesResistorHeatedDirt   = srhd;
    _seriesResistorPottedDirt   = srpd;
    _seriesResistorBoxInterior  = srbi;
    _seriesResistorBoxExterior  = srbe;
    _seriesResistorAux0         = sra0;
    _seriesResistorAux1         = sra1;

    pinMode(PINLIDSWITCH,INPUT);
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
 
    steinhart = thermalr / THERMISTORNOMINAL;              // (R/Ro)
    steinhart = log(steinhart);                       // ln(R/Ro)
    steinhart /= BCOEFFICIENT;                        // 1/B * ln(R/Ro)
    steinhart += 1.0 / (TEMPERATURENOMINAL + 273.15); // + (1/To)
    steinhart = 1.0 / steinhart;                      // Invert
    steinhart -= 273.15;                              // convert to C
    steinhart = 9.0*steinhart/5.0+32.0;               // convert to F
    return steinhart;
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

boolean WarmDirt::getLidSwitch() {
    return digitalRead(PINLIDSWITCH);
}

double  WarmDirt::getDHT12Temperature() {
    return 0.00;
}

double  WarmDirt::getDHT12Humidity() {
    return 0.00;
}

double  WarmDirt::getLoadCurrent() {
    return 0.00;
}

void    WarmDirt::setLoad0Enable(uint8_t enable) {
}

void    WarmDirt::setLoad1Enable(uint8_t enable) {
}

