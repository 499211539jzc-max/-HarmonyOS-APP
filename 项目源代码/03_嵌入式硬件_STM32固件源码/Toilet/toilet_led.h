#ifndef __TOILET_LED_H
#define __TOILET_LED_H

#include "stm32l4xx_hal.h"

extern uint8_t light_state;

/* 灯光控制函数 */
void light_on(void);
void light_off(void);
void light_toggle(void);

/* 兼容原有函数名 */
void toilet_led_on(void);
void toilet_led_off(void);

#endif
