#ifndef __toilet_sensor_H
#define __toilet_sensor_H

#include "stm32l4xx_hal.h"

/*****************************外部函数声明**************************************/
extern void AS312_Init(void);
extern uint8_t Infrared_Read_State(void);

#endif

