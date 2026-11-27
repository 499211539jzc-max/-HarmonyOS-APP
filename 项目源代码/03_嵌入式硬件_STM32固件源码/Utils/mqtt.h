// mqtt.h
#ifndef __MQTT_H
#define __MQTT_H
#include "main.h"

extern uint8_t mqtt_connected;

uint8_t MQTT_Connect(const char *host, int port, const char *client_id);
uint8_t MQTT_Publish(const char *topic, const char *payload);
uint8_t MQTT_Subscribe(const char *topic);

#endif
