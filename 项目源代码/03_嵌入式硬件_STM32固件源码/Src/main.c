#include "main.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"
#include "esp8285.h"
#include "mqtt.h"
#include "bedroom_eth30.h"
#include "kitchen_gas.h"
#include "bedroom_monitor.h"
#include "kitchen_monitor.h"
#include "toilet_sensor.h"
#include "toilet_monitor.h"
#include "toilet_led.h"
#include "kitchen_fan.h"
#include "kitchen_beep.h"
#include "stdio.h"

void SystemClock_Config(void);

int main(void)
{
  // 1. 系统与HAL库初始化
  HAL_Init();
  SystemClock_Config();

  // 2. 初始化GPIO (大灯PB15、电机PA8、蜂鸣器PE8、按键KEY1~KEY4、触摸按键PD14、继电器PC7、板载LED PA4~PA7)
  MX_GPIO_Init();

  // 3. 初始化道闸PWM (TIM1 PA11 及 TIM2 PA15) 并设为默认闭合
  Gate_Init();

  // 4. 初始化串口 (USART1: WiFi模块, USART2: USB调试串口)
  MX_USART1_UART_Init();
  MX_USART2_UART_Init();

  // 5. 初始化传感器 (SHT30温湿度, MQ-5气体烟雾, AS312人体红外感应)
  SHT30_GPIO_Init();
  MQ5_Init();
  AS312_Init();

  // 6. 开启PC调试串口接收中断
  HAL_UART_Receive_IT(&huart2, &uart2_rx_byte, 1);

  // 7. 打印启动日志
  printf("\r\n===================================================\r\n");
  printf("*      Smart Home & Box Control (STM32L431)       *\r\n");
  printf("* Controls & Sensors:\r\n");
  printf("*  1. Light: KEY1 or Touch / CMD: light_on, light_off\r\n");
  printf("*  2. Motor: KEY2 / CMD: motor_on, motor_off\r\n");
  printf("*  3. Gate:  KEY3 / CMD: gate_test\r\n");
  printf("*  4. Smoke: MQ-5(PD15) Auto Alarm Beep & Motor\r\n");
  printf("*  5. PIR:   AS312(PC8) Human Sensing -> Auto Light\r\n");
  printf("*  6. MQTT:  Auto-reconnecting, Sub 'commandtopic'\r\n");
  printf("===================================================\r\n");

  // 8. 开机自检提示：大灯闪烁一次，电机转动0.2秒，蜂鸣器短鸣一声
  printf("[SELF-TEST] Testing Hardware...\r\n");
  light_on();
  motor_on();
  beep_on();
  HAL_Delay(100);
  beep_off();
  HAL_Delay(150);
  light_off();
  motor_off();

  // 道闸动作测试：左边顺时针90度，右边逆时针90度，转完之后再转回去
  Gate_Test();
  printf("[SELF-TEST] Hardware OK!\r\n");

  // 9. 连接WiFi (连接2.4GHz热点 GZ)
  ESP_Init("GZ", "20051007jzc");
  HAL_Delay(500);
  if (MQTT_Connect("10.177.212.134", 1880, "jzc_stm32"))
  {
      MQTT_Subscribe("commandtopic");
  }

  char payload[200];
  uint32_t last_mqtt_time = 0;
  uint32_t last_reconnect_time = 0;
  uint8_t pub_fail_count = 0;

  // 10. 主控制循环
  while (1)
  {
    extern volatile uint8_t gate_test_flag;
    if (gate_test_flag)
    {
        gate_test_flag = 0;
        Gate_Test();
    }

    // 扫描实体按键 KEY1~KEY4 及 智慧家居板触摸按键
    Key_Scan();

    // 烟雾自动监测 (超标时自动报警响蜂鸣器并开电机排风)
    kitchen_monitor();

    // 人体红外感应监测 (有人靠近自动开灯，离开3秒后自动关灯)
    toilet_monitor();

    uint32_t now = HAL_GetTick();

    // 核心自动重连机制：若未连接MQTT，每3秒自动重连一次
    if (!mqtt_connected && (now - last_reconnect_time >= 3000))
    {
        last_reconnect_time = now;
        // 连接宿主机转发端口 10.84.189.134:1880 (已实测成功穿透至虚拟机EMQX 1883)
        if (MQTT_Connect("10.177.212.134", 1880, "jzc_stm32"))
        {
            MQTT_Subscribe("commandtopic");
        }
    }

    // 定时读取温湿度并上报状态 (每2秒一次)
    if (now - last_mqtt_time >= 2000)
    {
      last_mqtt_time = now;
      bedroom_monitor(); // 读取温湿度 temp, humi

      sprintf(payload, "{\"temp\":%.2f,\"humi\":%.2f,\"gas\":%d,\"human\":%d,\"light\":%d,\"motor\":%d,\"gate\":%d}",
              temp, humi, gas, sensor_people, light_state, motor_state, gate_state);

      if (mqtt_connected)
      {
          uint8_t ok = MQTT_Publish("sensorData", payload);
          if (!ok) {
              pub_fail_count++;
              if (pub_fail_count >= 3) {
                  // 连续3次发送失败说明连接断开，重置标志触发自动重连
                  mqtt_connected = 0;
                  pub_fail_count = 0;
                  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, GPIO_PIN_SET); // 灭掉PA6在线指示灯
              }
          } else {
              pub_fail_count = 0;
          }
      }

      printf("[STATUS] Temp:%.1f C | Humi:%.1f %% | Gas:%d | Human:%s | Light:%s | Motor:%s | Gate:%s | MQTT:%s\r\n",
             temp, humi, gas, (sensor_people ? "DETECTED" : "None"),
             light_state ? "ON" : "OFF",
             motor_state ? "ON" : "OFF",
             gate_state ? "OPEN" : "CLOSE",
             mqtt_connected ? "ONLINE" : "OFFLINE");
    }

    // 10ms 快速扫描延时
    HAL_Delay(10);
  }
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 1;
  RCC_OscInitStruct.PLL.PLLN = 20;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV7;
  RCC_OscInitStruct.PLL.PLLQ = RCC_PLLQ_DIV2;
  RCC_OscInitStruct.PLL.PLLR = RCC_PLLR_DIV2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    Error_Handler();
  }
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_USART1|RCC_PERIPHCLK_USART2;
  PeriphClkInit.Usart1ClockSelection = RCC_USART1CLKSOURCE_PCLK2;
  PeriphClkInit.Usart2ClockSelection = RCC_USART2CLKSOURCE_PCLK1;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }

  if (HAL_PWREx_ControlVoltageScaling(PWR_REGULATOR_VOLTAGE_SCALE1) != HAL_OK)
  {
    Error_Handler();
  }
}

void Error_Handler(void)
{
}
