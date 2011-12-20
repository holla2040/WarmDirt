#ifndef WARMDIRT_H
#define WARMDIRT_H 1

#include "WProgram.h"
#include <stdint.h>

class WarmDirt {
    public:
        WarmDirt();
        double  getHeatedDirtTemperature();
        double  getPottedDirtTemperature();
        double  getBoxInteriorTemperature();
        double  getBoxExteriorTemperature();
        double  getAux0Temperature();
        double  getAux1Temperature();
        double  getLightSensor();
        boolean getLidSwitch();
        double  getDHT12Temperature();
        double  getDHT12Humidity();
        double  getLoadCurrent();
        
        void    setLoad0Enable(uint8_t enable);
        void    setLoad1Enable(uint8_t enable);
    private:
        uint8_t _load0Enabled;
        uint8_t _load1Enabled;
};

#endif
