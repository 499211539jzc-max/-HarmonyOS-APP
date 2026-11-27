#include "kitchen_fan.h"
#include "stm32l4xx_hal.h"

uint8_t motor_state = 0; // 0: 停, 1: 转

// 打开试验箱电机 (PA8高电平导通MOS管)
void motor_on(void)
{
  motor_state = 1;
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_8, GPIO_PIN_SET);    // 试验箱电机运转
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);  // 主板LED2指示灯亮
}

// 关闭试验箱电机 (PA8低电平截止MOS管)
void motor_off(void)
{
  motor_state = 0;
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_8, GPIO_PIN_RESET);  // 试验箱电机停止
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);    // 主板LED2指示灯灭
}

// 切换电机状态
void motor_toggle(void)
{
  if (motor_state == 0) {
    motor_on();
  } else {
    motor_off();
  }
}

// 兼容原有函数名
void kitchen_fan_on(void)  { motor_on(); }
void kitchen_fan_off(void) { motor_off(); }
