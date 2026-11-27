#include "toilet_led.h"
#include "stm32l4xx_hal.h"

uint8_t light_state = 0; // 0: 灭, 1: 亮

// 打开灯光 (PB15试验箱大灯 + PC7智慧家居板继电器 + PA4板载指示灯)
void light_on(void)
{
  light_state = 1;
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_15, GPIO_PIN_SET);   // 试验箱大灯开 (高电平)
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_7, GPIO_PIN_SET);    // 智慧家居板继电器吸合
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_RESET);  // 主板LED1指示灯亮 (低电平)
}

// 关闭灯光 (PB15低电平 + PC7断开 + PA4灭)
void light_off(void)
{
  light_state = 0;
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_15, GPIO_PIN_RESET); // 试验箱大灯关
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_7, GPIO_PIN_RESET);  // 智慧家居板继电器释放
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_SET);    // 主板LED1指示灯灭
}

// 切换灯光
void light_toggle(void)
{
  if (light_state == 0) {
    light_on();
  } else {
    light_off();
  }
}

// 兼容旧接口
void toilet_led_on(void)  { light_on(); }
void toilet_led_off(void) { light_off(); }
