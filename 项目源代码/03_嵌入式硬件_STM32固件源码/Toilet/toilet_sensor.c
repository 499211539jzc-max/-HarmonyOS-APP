#include "stm32l4xx_hal.h"                  // Device header


/*****************************IO引脚宏定义**************************************/	
#define AS312_Pin            GPIO_PIN_8
#define AS312_GPIO_Port      GPIOC

/*****************************IO操作函数****************************************/	
#define	AS312_STATE()        HAL_GPIO_ReadPin(AS312_GPIO_Port, AS312_Pin)     

/********************************************************************************
* 名    称：AS312_Init
* 功    能：初始化AS312
* 参数说明：无
* 返 回 值：无
* 说    明：配置AS312的IO引脚
********************************************************************************/
void AS312_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct;

    __HAL_RCC_GPIOC_CLK_ENABLE();    


    GPIO_InitStruct.Pin = AS312_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
    GPIO_InitStruct.Pull = GPIO_PULLDOWN;
    HAL_GPIO_Init(AS312_GPIO_Port, &GPIO_InitStruct);
}

/********************************************************************************
* 名    称：Infrared_Read_State
* 功    能：读取AS312的状态
* 参数说明：无
* 返 回 值：AS312_STATE: 0 无人运动
                            1 有人运动
* 说    明：用于检测是否存在运动的物体
********************************************************************************/
uint8_t Infrared_Read_State(void)
{
    return AS312_STATE();
}
