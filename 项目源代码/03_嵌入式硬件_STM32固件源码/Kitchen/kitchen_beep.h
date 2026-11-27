#ifndef __KITCHEN_BEEP_H
#define __KITCHEN_BEEP_H

#include "stm32l4xx_hal.h"

extern uint8_t beep_state;

void beep_on(void);
void beep_off(void);
void beep_toggle(void);

void kitchen_beep_on(void);
void kitchen_beep_off(void);

#endif
