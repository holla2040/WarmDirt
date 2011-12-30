#ifndef WARMDIRT_H
#define WARMDIRT_H 1

#include "WProgram.h"
#include <stdint.h>

#define PINHEATEDDIRT       A0
#define PINPOTTEDDIRT       A1
#define PINBOXINTERIOR      A2
#define PINBOXEXTERIOR      A3
#define PINAUX0             A4
#define PINAUX1             A5
#define PINLIGHTSENSOR      A6
#define PINLOADCURRENT      A7

#define PINLIDSWITCH        11
#define PINACTIVITY         13
#define PINLOAD0ENABLE      4
#define PINLOAD1ENABLE      10

#define SAMPLES             10

/* ref http://www.ladyada.net/learn/sensors/thermistor.html */
#define THERMISTORNOMINAL   10000      
#define TEMPERATURENOMINAL  25   
#define BCOEFFICIENT        3950

class WarmDirt {
    public:
        WarmDirt(double srhd = 10000, double srpd = 10000, double srbi = 10000, double srbe = 10000, double sra0 = 10000, double sra1 = 10000);
        double      getHeatedDirtTemperature();
        double      getPottedDirtTemperature();
        double      getBoxInteriorTemperature();
        double      getBoxExteriorTemperature();
        double      getAux0Temperature();
        double      getAux1Temperature();
        uint16_t    getLightSensor();
        boolean     getLidSwitchClosed();
        double      getDHTTemperature();
        double      getDHTHumidity();
        double      getLoadCurrent();
        
        void        load0On();
        void        load0Off();
        boolean     getLoad0On();

        void        load1On();
        void        load1Off();
        boolean     getLoad1On();

        void        activityToggle();

        double      ctof(double c);
    private:
        uint16_t    adcaverage(uint8_t pin, uint16_t samples);
        double      adctotemp(uint16_t adc,double seriesResistance);
        double      _seriesResistorHeatedDirt;
        double      _seriesResistorPottedDirt;
        double      _seriesResistorBoxInterior;
        double      _seriesResistorBoxExterior;
        double      _seriesResistorAux0;
        double      _seriesResistorAux1;
};

#endif
