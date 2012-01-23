#!/usr/bin/env python

import serial
import os,sys
import sys
import termios
import socket
import mosquitto, time

def on_connect(rc):
    if rc == 0:
        print "mqtt connected successfully."
    else:
        print "mqtt onnected unsuccessfully."

mqtt = mosquitto.Mosquitto("warmdirt")
mqtt.connect("localhost")
mqtt.on_connect = on_connect

print "console.py"

def getchar():
    fd = sys.stdin.fileno()

    if os.isatty(fd):
        old = termios.tcgetattr(fd)
        new = termios.tcgetattr(fd)
        new[3] = new[3] & ~termios.ICANON & ~termios.ECHO
        new[6] [termios.VMIN] = 1
        new[6] [termios.VTIME] = 0

        try:
            termios.tcsetattr(fd, termios.TCSANOW, new)
            termios.tcsendbreak(fd,0)
            ch = os.read(fd,7)

        finally:
            termios.tcsetattr(fd, termios.TCSAFLUSH, old)
    else:
        ch = os.read(fd,7)

    return(ch)


ser = serial.Serial('/dev/ttyUSB0', 57600,timeout=1)

sum = 0
line = ""
while True:
    if ser.inWaiting():
        c = ser.read()
        u = ord(c)
        if u == 2:
            sum = 0
            line = ""
        else:
            if u == 3:
                if (sum&0xff) == 0:
                    #print "/%c%s"%(line[1],line[3:-1])
                    (k,v) = line[3:-1].split("=")
                    k = "us/co/montrose/1001s2nd/warmdirt/%c%s"%(line[1],k)
                    mqtt.publish(k,v, qos=0, retain=False)
                    print "%40s %s"%(k,v)
            else:
                sum += u
                line += c
#        if u > 29 and u < 123:
#            print "%-4d %c"%(u,c)
#        else:
#            print "%-4d   "%(u)
    mqtt.loop(0)

