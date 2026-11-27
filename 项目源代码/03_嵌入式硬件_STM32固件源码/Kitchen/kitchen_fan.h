#ifndef __KITCHEN_FAN_H
#define __KITCHEN_FAN_H

#include "stm32l4xx_hal.h"

extern uint8_t motor_state;

/* 电机控制函数 */
void motor_on(void);
void motor_off(void);
void motor_toggle(void);

/* 兼容原有函数名 */
void kitchen_fan_on(void);
void kitchen_fan_off(void);

#endif
