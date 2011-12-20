TARGET                  = arduino
MCU                     = atmega328p
#MCU                    = atmega1280
#MCU                    = atmega2560
DEVICE_FILE             = ttyUSB0
#DEVICE_FILE            = ttyACM0
#DEVICE_FILE             = rfcomm4

CONSOLE_BAUDRATE        = 57600
AVRDUDE_ARD_BAUDRATE    = 57600
#AVRDUDE_ARD_BAUDRATE   = 115200

ARDUINO_DIR             = /opt/arduino
AVR_TOOLS_PATH          = /usr/bin
AVRDUDE_ARD_PROGRAMMER  = stk500v1
AVRDUDE                 = /opt/arduino/hardware/tools/avrdude
                                            
F_CPU                   = 16000000
ARDUINO_PORT            = /dev/$(DEVICE_FILE)
                                            
ARDUINO_LIBS            = 
                                            
include ./Arduino.mk

runold:	reset all raw_upload
	make con

run: all
	stty -F $(ARDUINO_PORT) $(CONSOLE_BAUDRATE)
	echo -en "R" > $(ARDUINO_PORT)
	sleep 0.5
	make raw_upload
	make con

con:
	rm -rf /var/lock/LCK..$(DEVICE_FILE)
	microcom -p $(ARDUINO_PORT) -s $(CONSOLE_BAUDRATE)
