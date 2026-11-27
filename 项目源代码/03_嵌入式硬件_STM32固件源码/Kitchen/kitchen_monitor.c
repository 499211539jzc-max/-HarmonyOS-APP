#include "kitchen_monitor.h"
#include "kitchen_gas.h"
#include "kitchen_fan.h"
#include "kitchen_beep.h"
#include "esp8285.h"
#include "stdio.h"

uint8_t gas = 1;
uint8_t manual_alarm_test = 0; // 手动报警测试标志

void kitchen_monitor(void)
{
  uint8_t prev_gas = gas;
  gas = MQ5_Read_State(); // 0: 有烟雾/超标, 1: 正常

  // 烟雾超标自动报警或手动测试
  if (gas == 0 || manual_alarm_test) {
    beep_on();
    motor_on(); // 自动排风排烟
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, GPIO_PIN_RESET); // 主板LED4警报亮
    if (prev_gas != 0 && gas == 0) {
      printf("[ALARM] Smoke detected! Buzzer & Motor ON!\r\n");
    }
  } else {
    // 烟雾恢复正常
    if (!manual_alarm_test) {
      beep_off();
      HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, GPIO_PIN_SET); // 主板LED4警报灭
      if (prev_gas == 0 && gas == 1) {
        printf("[NORMAL] Smoke cleared. Buzzer OFF.\r\n");
      }
    }
  }
}
