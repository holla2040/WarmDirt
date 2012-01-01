#include <SPI.h>
#include <Ethernet.h>
#include <PubSubClient.h>
#include <string.h>
#include "NewSoftSerial.h"

#define MQTTUSER    "1001warmdirt1"
#define MQTTPREFIX  "us/co/montrose/1001s2nd/warmdirt"

/* 
    print debug log connect usb-ftdi-RX to A0 at 9600 8N1
*/


byte mac[] =        { 0xDE, 0xAD, 0x33, 0xEF, 0xFE, 0xED };
byte ip[] =         { 192,168,0,10  };
byte mqttserver[] = { 192,168,0,117 };
byte gateway[] =    { 192,168,0,1   };

char line[100];
char key[100];
char lineindex;
char c;

char mqttconnected; 

NewSoftSerial debug(A1,A0);

void mqttprocess(char *topic, byte * payload, int length) {
    char *topicwithoutprefix = topic + strlen(MQTTPREFIX) + 1; // +1 for trailing '/'
    payload[length] = 0; // payload is a pointer in 'buffer[128]'
    Serial.print(topicwithoutprefix);
    Serial.print("=");
    Serial.println((char *)payload);
    debug.print("mrecieved ");
    debug.print(topicwithoutprefix);
    debug.print("=");
    debug.println((char *)payload);
}

PubSubClient mqtt(mqttserver, 1883, mqttprocess);

unsigned long next;

void publish(char *k,char *v) {
    sprintf(key,"%s/%s",MQTTPREFIX,k);
    mqtt.publish(key,v);
    sprintf(key,"published %s/%s=%s",MQTTPREFIX,k,v);
    debug.println(key);
}


void mqttconnect() {
    sprintf(line,"mqtt connect %s@%d.%d.%d.%d:1883 ",MQTTUSER,mqttserver[0],mqttserver[1],mqttserver[2],mqttserver[3]);
    debug.print(line);
    if (mqtt.connect(MQTTUSER)) {
        debug.println("success");

        sprintf(line,"%s/+/config/#",MQTTPREFIX);
        mqtt.subscribe(line);
        debug.print("subscribed to ");
        debug.println(line);

        publish("gateway","startup");

        mqttconnected = 1;
    } else {
        debug.println("failure");
        mqttconnected = 0;
    }
}

void setup() {
    Serial.begin(57600);
    debug.begin(9600);
    debug.println("\n\nwarmdirtgatewaymqtt begin");

    Ethernet.begin(mac, ip, gateway);
    lineindex = 0;
    mqttconnect();
}

void mqttloop() {
    if (mqtt.loop() == 0) {
        mqtt.disconnect();
        mqttconnect();
    }
}

void commloop() {
    int c;
    if (Serial.available()) {
        c = Serial.read();
        if (c == '\n') {
            line[lineindex] = 0;
            debug.print("srecieved ");
            debug.println(line);
            publish(strtok(line,"="),strtok(NULL,"="));
            lineindex = 0;
            return;
        }
        line[lineindex++] = c;
    }
}
        

void loop() {
    mqttloop();
    commloop();
}
