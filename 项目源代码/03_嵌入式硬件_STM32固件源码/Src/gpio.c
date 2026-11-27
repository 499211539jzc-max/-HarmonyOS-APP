#include "gpio.h"
#include "toilet_led.h"
#include "kitchen_fan.h"
#include "kitchen_beep.h"
#include "kitchen_monitor.h"
#include "tim.h"
#include "stdio.h"

void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* 使能各个GPIO端口时钟 */
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOE_CLK_ENABLE();

  /* 1. 初始化蜂鸣器 (PE8, 高电平响) */
  GPIO_InitStruct.Pin = GPIO_PIN_8;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
  HAL_GPIO_Init(GPIOE, &GPIO_InitStruct);
  HAL_GPIO_WritePin(GPIOE, GPIO_PIN_8, GPIO_PIN_RESET);

  /* 2. 初始化风扇/电机 (PA8, 高电平开) */
  GPIO_InitStruct.Pin = GPIO_PIN_8;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_8, GPIO_PIN_RESET);

  /* 3. 初始化主板指示灯 PA4, PA5, PA6, PA7 (低电平亮，默认全灭置高) */
  GPIO_InitStruct.Pin = GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7, GPIO_PIN_SET);

  /* 4. 初始化试验箱大灯 (PB15) 及 PB12 (高电平开) */
  GPIO_InitStruct.Pin = GPIO_PIN_12|GPIO_PIN_15;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_12|GPIO_PIN_15, GPIO_PIN_RESET);

  /* 5. 初始化智慧家居板继电器 (PC7, 高电平吸合) */
  GPIO_InitStruct.Pin = GPIO_PIN_7;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
  HAL_GPIO_WritePin(GPIOC, GPIO_PIN_7, GPIO_PIN_RESET);

  /* 6. 初始化主板按键 KEY1(PD5), KEY2(PD4), KEY3(PD3), KEY4(PD2) */
  GPIO_InitStruct.Pin = GPIO_PIN_2|GPIO_PIN_3|GPIO_PIN_4|GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

  /* 7. 初始化智慧家居板触摸按键 (PD14, 触摸为高) */
  GPIO_InitStruct.Pin = GPIO_PIN_14;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

  /* 8. 初始化试验箱光电开关 (PD13) */
  GPIO_InitStruct.Pin = GPIO_PIN_13;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);
}

/* 按键与传感器触发扫描处理函数 */
void Key_Scan(void)
{
  static uint8_t key1_last = 1, key2_last = 1, key3_last = 1, key4_last = 1;
  static uint8_t touch_last = 0;

  uint8_t k1 = HAL_GPIO_ReadPin(GPIOD, GPIO_PIN_5);  // KEY1
  uint8_t k2 = HAL_GPIO_ReadPin(GPIOD, GPIO_PIN_4);  // KEY2
  uint8_t k3 = HAL_GPIO_ReadPin(GPIOD, GPIO_PIN_3);  // KEY3
  uint8_t k4 = HAL_GPIO_ReadPin(GPIOD, GPIO_PIN_2);  // KEY4
  uint8_t touch = HAL_GPIO_ReadPin(GPIOD, GPIO_PIN_14); // 触摸按键

  // KEY1 或 触摸按键: 切换灯光
  if ((key1_last == 1 && k1 == 0) || (touch_last == 0 && touch == 1)) {
    HAL_Delay(15);
    light_toggle();
    printf("[KEY/TOUCH] Toggle Light -> %s\r\n", light_state ? "ON" : "OFF");
  }

  // KEY2: 切换电机
  if (key2_last == 1 && k2 == 0) {
    HAL_Delay(15);
    motor_toggle();
    printf("[KEY2] Toggle Motor -> %s\r\n", motor_state ? "ON" : "OFF");
  }

  // KEY3: 测试道闸 (左边顺时针90度，右边逆时针90度，转完之后再转回去)
  if (key3_last == 1 && k3 == 0) {
    HAL_Delay(15);
    if (HAL_GPIO_ReadPin(GPIOD, GPIO_PIN_3) == 0) {
      Gate_Test();
    }
  }

  // KEY4: 报警测试
  if (key4_last == 1 && k4 == 0) {
    HAL_Delay(15);
    manual_alarm_test = !manual_alarm_test;
    if (!manual_alarm_test) {
      beep_off();
    }
    printf("[KEY4] Alarm Test -> %s\r\n", manual_alarm_test ? "TEST ON" : "TEST OFF");
  }

  key1_last = k1;
  key2_last = k2;
  key3_last = k3;
  key4_last = k4;
  touch_last = touch;
}
