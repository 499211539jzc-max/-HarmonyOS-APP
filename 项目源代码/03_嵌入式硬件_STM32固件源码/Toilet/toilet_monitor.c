#include "toilet_monitor.h"
#include "stm32l4xx_hal.h"
#include "toilet_sensor.h"
#include "toilet_led.h"
#include "esp8285.h"
#include "stdio.h"

uint8_t sensor_people = 0;
static uint32_t last_people_detected_tick = 0;
static uint8_t pir_triggered = 0;

void toilet_monitor(void)
{
    // 读取人体红外传感器状态 (PC8: 1=有人靠近/运动, 0=无人)
    uint8_t current_state = Infrared_Read_State();
    sensor_people = current_state;

    // 自动感应模式 (默认开启)
    if (smart_flag)
    {
        if (current_state == 1)
        {
            last_people_detected_tick = HAL_GetTick();
            if (!pir_triggered)
            {
                pir_triggered = 1;
                light_on(); // 自动开灯 (试验箱大灯PB15 + 智慧家居板继电器PC7)
                HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_RESET); // 主板LED3指示灯亮
                printf("[PIR] Human motion detected! Light ON (Auto)\r\n");
            }
        }
        else
        {
            // 人离开后延时3秒再自动关灯，提供平滑的使用体验
            if (pir_triggered && (HAL_GetTick() - last_people_detected_tick >= 3000))
            {
                pir_triggered = 0;
                light_off(); // 自动关灯
                HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET); // 主板LED3指示灯灭
                printf("[PIR] Nobody detected. Light OFF (Auto)\r\n");
            }
        }
    }
}
