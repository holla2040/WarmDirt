#!/usr/bin/python

import mosquitto,sys,random

host = "hd"

subscribetopic="us/co/montrose/1001s2nd/#"

data = {}

def showdata(topic):
    #print "\x1b[H\x1b[2J" #home and clear
    print "\x1b[0;0H" #home no clear
    keys = data.keys()
    keys.sort()
    for k in keys:
        if k == topic:
            print "\x1b[K%-65s\x1b[7m%s\x1b[0m"%(k,data[k])
        else:
            print "\x1b[K%-65s%s"%(k,data[k])



def on_connect(rc):
    print "\x1b[H\x1b[2JConnected",host, subscribetopic #home and clear

def on_message(msg):
    data[msg.topic] = msg.payload
    showdata(msg.topic)

mqttc = mosquitto.Mosquitto("mqttsubtable%d"%random.randrange(0, 10001, 2))

mqttc.on_message = on_message
mqttc.on_connect = on_connect

mqttc.connect(host, 1883, 60, True)
mqttc.subscribe(subscribetopic, 0)


#keep connected to broker
while mqttc.loop(1) == 0:
    pass

