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

#define PINMOTORAIN         7
#define PINMOTORAENABLE     5
#define PINMOTORBIN         8
#define PINMOTORBENABLE     6

#define PINLIDSWITCH        11
#define PINACTIVITY         13
#define PINLOAD0ENABLE      4
#define PINLOAD1ENABLE      10

#define SAMPLES             10

/* ref http://www.ladyada.net/learn/sensors/thermistor.html */
#define THERMISTORNOMINAL   10000      
#define TEMPERATURENOMINAL  25   
#define BCOEFFICIENT        3950

#define MOTORSPEEDINC       5

#define STX         2
#define ETX         3
#define KV  'm'

#define DIRECTIONUP              1
#define DIRECTIONDOWN            -1

enum{F62500,F7813,F977,F244,F61};
/** Frequencies available
    timer 0 - pins 5,6 - 62500Hz
    1       F62500
    8       F7813
    64      F977
    256     F244
    1024    F61
*/

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
        double      getLoadDCCurrent();
        double      getLoadACCurrent();
        
        void        load0On();
        void        load0Off();
        boolean     getLoad0On();

        void        load1On();
        void        load1Off();
        boolean     getLoad1On();

        int8_t      motorASpeed(int8_t speed);
        int8_t      motorBSpeed(int8_t speed);
        void        setPwmFrequency(uint8_t frequency);

        void        activityToggle();

        double      ctof(double c);
        void        stepperSpeed(int32_t speed);
        void        stepperStep(int16_t steps);
        void        stepperEnable();
        void        stepperDisable();

        void        sendString(char *str);
        void        sendPacket(uint8_t address, char type, char *str);
        void        sendPacketKeyValue(uint8_t address, char type, char *key, char *value);
        void        loop();
        void        temperatureLoop();
        void        setTemperatureControl(boolean value);
        void        setTemperatureSetPoint(double value, int8_t hysteresis);
        double      getTemperatureSetPoint();
        double      getPIDOutput();
        void        debug();
        static int32_t     bencodercount;

    private:
        uint16_t    adcaverage(uint8_t pin, uint16_t samples);
        uint16_t    adcmax(uint8_t pin, uint16_t samples);
        double      adctotemp(uint16_t adc,double seriesResistance);
        double      seriesResistorHeatedDirt;
        double      seriesResistorPottedDirt;
        double      seriesResistorBoxInterior;
        double      seriesResistorBoxExterior;
        double      seriesResistorAux0;
        double      seriesResistorAux1;
        boolean     temperatureControl;  // should be persisted in EEPROM
        double      temperatureSetPoint; // should be persisted
        double      temperatureHysteresis; // should be persisted
        static void   countBUpdate();
        static int8_t bdirection;
};

#endif
