#include <SPI.h>
#include <Ethernet.h>
#include <PubSubClient.h>
#include <string.h>
#include "NewSoftSerial.h"
#include "socket.h"

#define UPTIMEUPDATEINVTERVAL 55000

#define LOCATION 0

#if LOCATION == 0

#define MQTTUSER    "121warmdirt1"
#define MQTTPREFIX  "us/co/montrose/121 Apollo/warmdirt"
#define MQTTLOC     "us/co/montrose/121 Apollo"

#else

#define MQTTUSER    "1001warmdirt1"
#define MQTTPREFIX  "us/co/montrose/1001s2nd/warmdirt"
#define MQTTLOC     "us/co/montrose/1001s2nd"

#endif

uint32_t nextUptimeUpdate;
uint32_t tcpTimeout;

/* 
    print debug log connect usb-ftdi-RX to A0 at 9600 8N1
*/


byte mac[] =        { 0xDE, 0xAD, 0x42, 0xEF, 0xFE, 0xED };

#if LOCATION == 0
byte ip[] =         { 10,210,211,249 };
byte mqttserver[] = { 10,210,211,231 };
byte gateway[] =    { 10,210,211,1   };
#else
byte ip[] =         { 192,168,0,10  };
byte mqttserver[] = { 192,168,0,117 };
byte gateway[] =    { 192,168,0,1   };
#endif

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

Server tcpserver(1055);

void publish(char *prefix, char *k,char *v) {
    sprintf(key,"%s/%s",prefix,k);
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

        publish(MQTTLOC,"gateway/begin","1");

        mqttconnected = 1;
    } else {
        debug.println("failure");
        mqttconnected = 0;
    }
}

void setup() {
    Serial.begin(57600);
    debug.begin(38400);
    debug.println("\n\nwarmdirtgatewaymqtt setup");

    Ethernet.begin(mac, ip, gateway);
    delay(2500); // wait a bit for wiz to come up
    tcpserver.begin();
    lineindex = 0;
    nextUptimeUpdate = 0;
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
    char tcpc;
    uint32_t now = millis();

    Client client = tcpserver.available();
    if (client) {
        tcpTimeout = now + 30000;
        for (;;) {
            if (client) {
                tcpc = client.read();
                if (tcpc != -1) {
                    Serial.print(tcpc);
                    //debug.print(">");
                    //debug.println(tcpc,HEX);
                }
                if (Serial.available()) {
                    c = Serial.read();
                    tcpserver.write(c);
                    //debug.print("<");
                    //debug.println(c,HEX);
                }
                if (millis() > tcpTimeout) {
                    break;
                }
            }
            Client client = tcpserver.available();
        }
    }

    if (Serial.available()) {
        c = Serial.read();
        if (c == '\r') {
            return;
        }
        if (c == '\n') {
            line[lineindex] = 0;
            //debug.print("srecieved ");
            //debug.println(line);
            publish(MQTTPREFIX,strtok(line,"="),strtok(NULL,"="));
            lineindex = 0;
            return;
        }
        line[lineindex++] = c;
    }
}

void statusloop() {
    unsigned long now = millis();
    char v[40];

    if (now > nextUptimeUpdate) {
        sprintf(v,"%lu",now);
        publish(MQTTLOC,"gateway/uptime",v);
        nextUptimeUpdate = now + UPTIMEUPDATEINVTERVAL;
    }
}

void loop() {
    mqttloop();
    commloop();
    statusloop();
}
