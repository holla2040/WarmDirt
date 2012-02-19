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

ARDUINO_DIR             = /opt/arduino-0022
AVR_TOOLS_PATH          = /usr/bin
AVRDUDE_ARD_PROGRAMMER  = stk500v1
AVRDUDE                 = /opt/arduino-0022/hardware/tools/avrdude
                                            
F_CPU                   = 16000000
ARDUINO_PORT            = /dev/$(DEVICE_FILE)
#TCP_PORT                = net:192.168.0.10:1055
TCP_PORT                = net:10.210.211.249:1055
                                            
ARDUINO_LIBS            = Stepper
                                            
include ./Arduino.mk

runold:	reset all raw_upload
	make con

run: all
	stty -F $(ARDUINO_PORT) $(CONSOLE_BAUDRATE)
	make reset
	echo -en "R" > $(ARDUINO_PORT)
	sleep 0.5
	make raw_upload
	#make con
	../console/console.py

tcp: all
	#stty -F $(ARDUINO_PORT) $(CONSOLE_BAUDRATE)
	#echo -en "R" > $(ARDUINO_PORT)
	#echo -n 'R0 ' | nc 192.168.0.10 1055
	make tcp_upload
	make con

con:
	rm -rf /var/lock/LCK..$(DEVICE_FILE)
	microcom -p $(ARDUINO_PORT) -s $(CONSOLE_BAUDRATE)
