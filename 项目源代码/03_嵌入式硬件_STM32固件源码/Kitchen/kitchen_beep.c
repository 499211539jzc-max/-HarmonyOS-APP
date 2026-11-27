#include "kitchen_beep.h"
#include "stm32l4xx_hal.h"

uint8_t beep_state = 0; // 0: 关, 1: 响

// 打开蜂鸣器 (PE8高电平响)
void beep_on(void)
{
  beep_state = 1;
  HAL_GPIO_WritePin(GPIOE, GPIO_PIN_8, GPIO_PIN_SET);
}

// 关闭蜂鸣器 (PE8低电平静音)
void beep_off(void)
{
  beep_state = 0;
  HAL_GPIO_WritePin(GPIOE, GPIO_PIN_8, GPIO_PIN_RESET);
}

// 切换蜂鸣器
void beep_toggle(void)
{
  if (beep_state == 0) {
    beep_on();
  } else {
    beep_off();
  }
}

// 兼容旧接口
void kitchen_beep_on(void)  { beep_on(); }
void kitchen_beep_off(void) { beep_off(); }
