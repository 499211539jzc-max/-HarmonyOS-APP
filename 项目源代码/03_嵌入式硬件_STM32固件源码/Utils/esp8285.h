#ifndef __ESP8285_H
#define __ESP8285_H
#include "main.h"
#include "usart.h"

void ESP_Init(char *wifiname, char *wifipass);
uint8_t ESP_SendCmd(char *cmd, char *ack, uint16_t timeout);

extern uint8_t smart_flag;
extern uint8_t esp_rx_buffer[512];

#endif
