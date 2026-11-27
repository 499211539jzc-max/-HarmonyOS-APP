// esp8285.c
#include "esp8285.h"
#include "string.h"
#include "stdio.h"
#include "stdint.h"
#include "toilet_led.h"
#include "bedroom_led.h"
#include "kitchen_beep.h"
#include "kitchen_fan.h"
#include "kitchen_monitor.h"
#include "kitchen_gas.h"
#include "tim.h"

uint8_t uart1_rx_byte;
uint8_t esp_rx_buffer[512];
uint16_t esp_rx_index = 0;
volatile uint8_t esp_rx_flag = 0;
static char expected_ack[32] = {0};

uint8_t uart2_rx_buffer[128];
uint16_t uart2_rx_index = 0;

uint8_t smart_flag = 1;
volatile uint8_t gate_test_flag = 0;

uint8_t ESP_SendCmd(char *cmd, char *ack, uint16_t timeout)
{
    memset(esp_rx_buffer, 0, sizeof(esp_rx_buffer));
    esp_rx_index = 0;
    esp_rx_flag = 0;
    if (ack && strlen(ack) > 0) {
        strncpy(expected_ack, ack, sizeof(expected_ack) - 1);
        expected_ack[sizeof(expected_ack) - 1] = '\0';
    } else {
        expected_ack[0] = '\0';
    }

    // 确保清除可能存在的溢出或噪声错误并重置状态
    __HAL_UART_CLEAR_OREFLAG(&huart1);
    __HAL_UART_CLEAR_NEFLAG(&huart1);
    __HAL_UART_CLEAR_FEFLAG(&huart1);
    huart1.Lock = HAL_UNLOCKED;
    huart1.RxState = HAL_UART_STATE_READY;
    HAL_UART_Receive_IT(&huart1, &uart1_rx_byte, 1);

    HAL_UART_Transmit(&huart1, (uint8_t*)cmd, strlen(cmd), 500);
    int len = strlen(cmd);
    if (len < 2 || cmd[len-1] != '\n') {
        HAL_UART_Transmit(&huart1, (uint8_t*)"\r\n", 2, 50);
    }

    // 发送完成后，确保huart1未处于锁定状态；若RxState被重置为READY则重新挂载中断
    huart1.Lock = HAL_UNLOCKED;
    if (huart1.RxState == HAL_UART_STATE_READY) {
        huart1.Lock = HAL_UNLOCKED;
        huart1.RxState = HAL_UART_STATE_READY;
        HAL_UART_Receive_IT(&huart1, &uart1_rx_byte, 1);
    }

    uint32_t tickstart = HAL_GetTick();
    while(!esp_rx_flag)
    {
        if(HAL_GetTick() - tickstart > timeout)
        {
            expected_ack[0] = '\0';
            return 0;
        }
    }

    uint8_t res = (esp_rx_flag == 1) ? 1 : 0;
    expected_ack[0] = '\0';
    return res;
}

void ESP_Init(char *wifiname, char *wifipass)
{
    char cmd[128];

    printf("[NET] Checking ESP WiFi module communication...\r\n");
    uint8_t ok = 0;
    for(int i = 0; i < 3; i++) {
        if(ESP_SendCmd("AT", "OK", 500)) {
            ok = 1;
            break;
        }
        HAL_Delay(300);
    }

    if (!ok)
    {
        printf("[NET] ESP8285 not responding to AT. Running in standalone local mode.\r\n");
        return;
    }

    ESP_SendCmd("ATE0", "OK", 300);
    ESP_SendCmd("AT+CWMODE=1", "OK", 300);

    sprintf(cmd, "AT+CWJAP=\"%s\",\"%s\"", wifiname, wifipass);
    printf("[NET] Connecting to WiFi '%s'...\r\n", wifiname);
    if (ESP_SendCmd(cmd, "WIFI GOT IP", 12000) || strstr((char*)esp_rx_buffer, "OK"))
    {
        printf("[NET] WiFi connected successfully!\r\n");
    }
    else
    {
        printf("[NET] WiFi connection failed or timeout.\r\n");
    }
}

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if(huart->Instance == USART1)
    {
        if(esp_rx_index < sizeof(esp_rx_buffer) - 1)
        {
            esp_rx_buffer[esp_rx_index++] = uart1_rx_byte;
            esp_rx_buffer[esp_rx_index] = '\0';
        }
        else
        {
            // 防御性安全重置：防止缓冲区溢出导致死锁
            esp_rx_index = 0;
            esp_rx_buffer[0] = '\0';
        }

        // 检测断开事件，及时标记离线以便主循环自动重连
        if(strstr((char*)esp_rx_buffer, "+MQTTDISCONNECTED") || strstr((char*)esp_rx_buffer, "CLOSED"))
        {
            extern uint8_t mqtt_connected;
            mqtt_connected = 0;
            HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET);
        }

        if(expected_ack[0] != '\0')
        {
            if(strstr((char*)esp_rx_buffer, expected_ack) || 
               (strstr((char*)esp_rx_buffer, "CONNECTED") != NULL) ||
               (strstr((char*)esp_rx_buffer, "ALREADY CONNECTED") != NULL)) {
                esp_rx_flag = 1;
            } else if(strstr((char*)esp_rx_buffer, "ERROR") || strstr((char*)esp_rx_buffer, "FAIL")) {
                esp_rx_flag = 2;
            }
        }

        if(uart1_rx_byte == '\n')
        {
            if(strstr((char*)esp_rx_buffer, "smart_hand")) smart_flag = 0;
            if(strstr((char*)esp_rx_buffer, "smart_auto")) smart_flag = 1;

            if(strstr((char*)esp_rx_buffer, "light_on") || strstr((char*)esp_rx_buffer, "bedroom_led1_on")) {
                light_on();
                printf("[MQTT] Light ON\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "light_off") || strstr((char*)esp_rx_buffer, "bedroom_led1_off")) {
                light_off();
                printf("[MQTT] Light OFF\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "motor_on") || strstr((char*)esp_rx_buffer, "kitchen_fan_on")) {
                motor_on();
                printf("[MQTT] Motor ON\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "motor_off") || strstr((char*)esp_rx_buffer, "kitchen_fan_off")) {
                motor_off();
                printf("[MQTT] Motor OFF\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "gate_test")) {
                gate_test_flag = 1; // 仅置标志位，在主循环中安全执行，绝不在中断中阻塞
                printf("[MQTT] Gate Test Flag Triggered\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "gate_open")) {
                Gate_Open();
                printf("[MQTT] Gate OPEN\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "gate_close")) {
                Gate_Close();
                printf("[MQTT] Gate CLOSE\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "beep_on") || strstr((char*)esp_rx_buffer, "kitchen_beep_on") || strstr((char*)esp_rx_buffer, "alarm_on")) {
                beep_on();
                printf("[MQTT] Beep ON\r\n");
            }
            else if(strstr((char*)esp_rx_buffer, "beep_off") || strstr((char*)esp_rx_buffer, "kitchen_beep_off") || strstr((char*)esp_rx_buffer, "alarm_off")) {
                beep_off();
                printf("[MQTT] Beep OFF\r\n");
            }

            // 执行完指令或收到换行后，及时重置接收缓冲区
            esp_rx_index = 0;
            memset(esp_rx_buffer, 0, sizeof(esp_rx_buffer));
        }

        huart1.Lock = HAL_UNLOCKED;
        huart1.RxState = HAL_UART_STATE_READY;
        HAL_UART_Receive_IT(&huart1, &uart1_rx_byte, 1);
    }
    else if(huart->Instance == USART2)
    {
        if(uart2_rx_index < sizeof(uart2_rx_buffer)-1)
        {
            if(uart2_rx_byte != '\r' && uart2_rx_byte != '\n')
            {
                uart2_rx_buffer[uart2_rx_index++] = uart2_rx_byte;
                uart2_rx_buffer[uart2_rx_index] = '\0';
            }
        }

        if(uart2_rx_byte == '\n' || uart2_rx_byte == '\r')
        {
            if(uart2_rx_index > 0)
            {
                if(strstr((char*)uart2_rx_buffer, "light_on") || strcmp((char*)uart2_rx_buffer, "1") == 0) {
                    light_on();
                    printf("[CMD OK] Light ON (PB15 & PC7)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "light_off") || strcmp((char*)uart2_rx_buffer, "0") == 0) {
                    light_off();
                    printf("[CMD OK] Light OFF (PB15 & PC7)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "motor_on") || strcmp((char*)uart2_rx_buffer, "2") == 0) {
                    motor_on();
                    printf("[CMD OK] Motor ON (PA8)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "motor_off") || strcmp((char*)uart2_rx_buffer, "3") == 0) {
                    motor_off();
                    printf("[CMD OK] Motor OFF (PA8)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "gate_test") || strcmp((char*)uart2_rx_buffer, "4") == 0) {
                    Gate_Test();
                }
                else if(strstr((char*)uart2_rx_buffer, "gate_open")) {
                    Gate_Open();
                    printf("[CMD OK] Gate OPEN (Left CW 90, Right CCW 90)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "gate_close") || strcmp((char*)uart2_rx_buffer, "5") == 0) {
                    Gate_Close();
                    printf("[CMD OK] Gate CLOSE (Returned)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "alarm_on")) {
                    manual_alarm_test = 1;
                    beep_on();
                    printf("[CMD OK] Alarm Test ON (PE8)\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "alarm_off")) {
                    manual_alarm_test = 0;
                    beep_off();
                    printf("[CMD OK] Alarm Test OFF\r\n");
                }
                else if(strstr((char*)uart2_rx_buffer, "status")) {
                    printf("=== STATUS: Light:%d | Motor:%d | Gate:%d | SmokeGas:%d ===\r\n", 
                           light_state, motor_state, gate_state, gas);
                }
                else {
                    printf("[UNKNOWN CMD] %s (Commands: light_on, light_off, motor_on, motor_off, gate_test, gate_open, gate_close, alarm_on, alarm_off, status)\r\n", uart2_rx_buffer);
                }

                uart2_rx_index = 0;
                memset(uart2_rx_buffer, 0, sizeof(uart2_rx_buffer));
            }
        }

        HAL_UART_Receive_IT(&huart2, &uart2_rx_byte, 1);
    }
}

void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART1)
    {
        __HAL_UART_CLEAR_OREFLAG(huart);
        __HAL_UART_CLEAR_NEFLAG(huart);
        __HAL_UART_CLEAR_FEFLAG(huart);
        huart1.Lock = HAL_UNLOCKED;
        huart1.RxState = HAL_UART_STATE_READY;
        HAL_UART_Receive_IT(&huart1, &uart1_rx_byte, 1);
    }
    else if (huart->Instance == USART2)
    {
        __HAL_UART_CLEAR_OREFLAG(huart);
        __HAL_UART_CLEAR_NEFLAG(huart);
        __HAL_UART_CLEAR_FEFLAG(huart);
        HAL_UART_Receive_IT(&huart2, &uart2_rx_byte, 1);
    }
}
