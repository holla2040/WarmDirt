#include "WProgram.h"
#include <stdint.h>

#include "WarmDirt.h"

WarmDirt::WarmDirt() {
}

double  WarmDirt::getHeatedDirtTemperature() {
    return 0.00;
}

double  WarmDirt::getPottedDirtTemperature() {
    return 0.00;
}

double  WarmDirt::getBoxInteriorTemperature() {
    return 0.00;
}

double  WarmDirt::getBoxExteriorTemperature() {
    return 0.00;
}

double  WarmDirt::getAux0Temperature() {
    return 0.00;
}

double  WarmDirt::getAux1Temperature() {
    return 0.00;
}

double  WarmDirt::getLightSensor() {
    return 0.00;
}

boolean WarmDirt::getLidSwitch() {
    return true;
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

