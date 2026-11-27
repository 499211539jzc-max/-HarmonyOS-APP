#ifndef __tim_H
#define __tim_H
#ifdef __cplusplus
 extern "C" {
#endif

#include "main.h"

extern TIM_HandleTypeDef htim1;
extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim15;

extern uint8_t gate_state;
extern uint16_t gate_delta;
extern uint16_t gate_base_left;
extern uint16_t gate_base_right;

void MX_TIM1_Init(void);
void MX_TIM2_Init(void);
void MX_TIM15_Init(void);
                        
void HAL_TIM_MspPostInit(TIM_HandleTypeDef *htim);

/* 道闸控制接口 */
void Gate_Init(void);
void Gate_Open(void);
void Gate_Close(void);
void Gate_Toggle(void);
void Gate_Test(void);
void Gate_Set(uint16_t pulse1, uint16_t pulse2);

#ifdef __cplusplus
}
#endif
#endif
