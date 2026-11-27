// mqtt.c
#include "mqtt.h"
#include "esp8285.h"
#include "string.h"
#include "stdio.h"

uint8_t mqtt_connected = 0;

// 连接MQTT服务
uint8_t MQTT_Connect(const char *host, int port, const char *client_id)	
{
    char cmd[160];
    
    // 配置MQTT客户端属性: LinkID=0, scheme=1(TCP), client_id, user, pwd, cert=0, CA=0, path=""
    sprintf(cmd, "AT+MQTTUSERCFG=0,1,\"%s\",\"root\",\"root\",0,0,\"\"", client_id);
    if (!ESP_SendCmd(cmd, "OK", 1000)) {
        // 如果配置失败，清理已有连接后再试一次
        ESP_SendCmd("AT+MQTTCLEAN=0", "OK", 500);
        if (!ESP_SendCmd(cmd, "OK", 1000)) {
            return 0;
        }
    }

    // 连接Broker: AT+MQTTCONN=<LinkID>,<host>,<port>,<reconnect>
    // 成功时ESP8266会返回 "+MQTTCONNECTED" 或 "OK"
    sprintf(cmd, "AT+MQTTCONN=0,\"%s\",%d,0", host, port);
    if (!ESP_SendCmd(cmd, "OK", 8000)) {
        return 0;
    }

    HAL_Delay(150);
    mqtt_connected = 1;
    // 连接成功点亮主板 LED PA6 作为网络在线指示
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET);
    return 1;
}

// 发布MQTT服务
uint8_t MQTT_Publish(const char *topic, const char *payload)
{
    if (!mqtt_connected) return 0;

    char cmd[160];
    int len = strlen(payload);
    snprintf(cmd, sizeof(cmd), "AT+MQTTPUBRAW=0,\"%s\",%d,0,0", topic, len);

    // 发送 AT+MQTTPUBRAW 指令
    if (!ESP_SendCmd(cmd, "OK", 500)) {
        return 0; // 发送失败返回0，触发连续失败重连
    }
    HAL_Delay(20);

    // 发送原始 Payload 数据 (无需引号转义，按字节准确传输)
    huart1.Lock = HAL_UNLOCKED;
    HAL_UART_Transmit(&huart1, (uint8_t*)payload, len, 500);
    HAL_Delay(30);

    return 1;
}

// 订阅MQTT服务
uint8_t MQTT_Subscribe(const char *topic)
{
    if (!mqtt_connected) return 0;

    char cmd[128];
    sprintf(cmd, "AT+MQTTSUB=0,\"%s\",0", topic);
    if (ESP_SendCmd(cmd, "OK", 2000)) {
        printf("[MQTT] Subscribed to topic: %s\r\n", topic);
        return 1;
    }
    return 0;
}
