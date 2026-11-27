#include "stdio.h"
#include <stdint.h>
#include "stm32l4xx_hal.h"                  // Device header

/*-----------------------------------------------------------------------------
* @文件名        : SHT30
* @描述          : 温湿度检测驱动文件
* @作者          : 物联网项目组
* @日期          : 2023/04/01
* @版本          : V0.0.2
*******************************************************************************
本驱动函数使用指导流程：
1、添加本驱动的.c和.h文件
2、在alarm_task.c中调用SHT30_GPIO_Init函数进行GPIO初始化
3、用户要根据程序系统时钟修改SYSCLOCK的值，要不会影响延时精度
******************************************************************************/
/********************************内部引脚定义***********************************/	   
#define SHT30_SCL_Pin              GPIO_PIN_13        
#define SHT30_SCL_GPIO_Port        GPIOB

#define SHT30_SDA_Pin              GPIO_PIN_14        
#define SHT30_SDA_GPIO_Port        GPIOB

/********************************IO模式设置*************************************/	
#define SHT30_SDA_IN()             {GPIOB->MODER&=~(3<<(14*2));GPIOB->MODER|=0<<14*2;}	      // PB14输入模式
#define SHT30_SDA_OUT()            {GPIOB->MODER&=~(3<<(14*2));GPIOB->MODER|=1<<14*2;}       // PB14输出模式

/********************************IO口函数操作***********************************/				   
#define SHT30_SCLK_Clr() 	HAL_GPIO_WritePin(SHT30_SCL_GPIO_Port, SHT30_SCL_Pin, GPIO_PIN_RESET) 
#define SHT30_SCLK_Set() 	HAL_GPIO_WritePin(SHT30_SCL_GPIO_Port, SHT30_SCL_Pin, GPIO_PIN_SET) 

#define SHT30_SDA_Clr()    HAL_GPIO_WritePin(SHT30_SDA_GPIO_Port, SHT30_SDA_Pin, GPIO_PIN_RESET)   
#define SHT30_SDA_Set()    HAL_GPIO_WritePin(SHT30_SDA_GPIO_Port, SHT30_SDA_Pin, GPIO_PIN_SET)

#define SHT30_READ_SDA()   HAL_GPIO_ReadPin(SHT30_SDA_GPIO_Port, SHT30_SDA_Pin)

/********************************内部宏定义*************************************/
#define SYSCLOCK   80         // 系统时钟，用于延时,需要用户根据系统时钟进行修改，要不会影响精确延时，单位Mhz
#define ACK        1
#define NACK       0
#define TURE       0  
#define ERROR      1
#define write 0
#define read  1
//******************************内部函数定义************************************/
static void delay_us(uint16_t Nus);
static void delay_ms(uint16_t Nms);

static void SHT30_IIC_Start(void);
static void SHT30_IIC_Stop(void);
static uint8_t IIC_wait_ACK(void);
static void IIC_ACK(void);
static void IIC_NACK(void);


/********************************************************************************
* 名    称：delay_us
* 功    能：微秒级延时
* 参数说明：Nus:延时的时间，单位us
* 返 回 值：无
* 说    明：根据系统时钟，进行延时
* 调用方法：内部函数
********************************************************************************/
static void delay_us(uint16_t Nus)
{
    uint32_t i;
    i = Nus * (SYSCLOCK/3);        
    while(i--);
}

/********************************************************************************
* 名    称：delay_ms
* 功    能：毫秒级延时
* 参数说明：nus:延时的时间，单位us
* 返 回 值：无
* 说    明：根据系统时钟，进行延时
********************************************************************************/
static void delay_ms(uint16_t Nms)
{
    uint32_t i;
    i = Nms * (SYSCLOCK/3) * 1000;        
    while(i--);
}


/********************************************************************************
* 名    称：SHT30_GOIO_Init
* 功    能：初始化SHT30引脚
* 参数说明：无
* 返 回 值：无
* 说    明：用于配置SHT30引脚工作模式
********************************************************************************/
void SHT30_GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct;
    __HAL_RCC_GPIOB_CLK_ENABLE();
	
    GPIO_InitStruct.Pin = SHT30_SCL_Pin | SHT30_SDA_Pin;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_PULLUP;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(SHT30_SCL_GPIO_Port, &GPIO_InitStruct);
	
	
}

/********************************************************************************
* 名    称：IIC_ACK
* 功    能：产生ACK应答
* 参数说明：无
* 返 回 值：无
* 说    明：无
* 调用方法：内部函数
********************************************************************************/
static void IIC_ACK(void)
{
    SHT30_SCLK_Clr();
		SHT30_SDA_OUT();
		SHT30_SDA_Clr();
		delay_us(2);
		SHT30_SCLK_Set() ;
		delay_us(2);
		SHT30_SCLK_Clr();
}

/********************************************************************************
* 名    称：IIC_No_Ack
* 功    能：不产生ACK应答	
* 参数说明：无
* 返 回 值：无
* 说    明：无
* 调用方法：内部函数
********************************************************************************/
static void IIC_NACK(void)
{
    SHT30_SCLK_Clr();
		SHT30_SDA_OUT();
		SHT30_SDA_Set();
		delay_us(2);
		SHT30_SCLK_Set();
		delay_us(2);
		SHT30_SCLK_Clr();
}

/********************************************************************************
* 名    称：IIC_wait_ACK
* 功    能：等待IIC应答信号
* 参数说明：无
* 返 回 值：TURE：接收成功
            ERROR：接受失败
* 说    明：无
* 调用方法：内部函数
********************************************************************************/
/*主机等待从机的ACK*/
static uint8_t IIC_wait_ACK(void)
{
    uint8_t ack_time=0;
    
	SHT30_SDA_IN();       
	SHT30_SDA_Set();
    delay_us(2);	   
	SHT30_SCLK_Set();
    delay_us(2);	 
    
	while(SHT30_READ_SDA())
	{
		ack_time++;
		delay_us(10);
		if(ack_time>250)
		{
			SHT30_IIC_Stop();
			return ERROR;
		}
	}
	SHT30_SDA_Clr();//时钟输出0 	   
	return TURE;  
}

/*功能： 启动IIC总线，即发送IIC起始条件*/
/********************************************************************************
* 名    称：SHT30_IIC_Start
* 功    能：产生IIC开始信号
* 参数说明：无
* 返 回 值：无
* 说    明：          
* 调用方法：内部函数
********************************************************************************/
static void SHT30_IIC_Start(void)
{
    SHT30_SDA_OUT();     
		SHT30_SDA_Set();
		SHT30_SCLK_Set();
    delay_us(5);
		SHT30_SDA_Clr();
    delay_us(5);
		SHT30_SCLK_Clr();
}


/********************************************************************************
* 名    称：SHT30_IIC_Stop
* 功    能：产生IIC停止信号
* 参数说明：无
* 返 回 值：无
* 说    明：
* 调用方法：内部函数
********************************************************************************/
static void SHT30_IIC_Stop(void)
{
    SHT30_SDA_OUT();
		SHT30_SCLK_Clr();
		SHT30_SDA_Clr();
    SHT30_SCLK_Set();
		delay_us(5);  
		SHT30_SDA_Set();
    delay_us(5);  
}


void IIC_SendByte(uint8_t byte)
{
    uint8_t BitCnt;
    SHT30_SDA_OUT();
    SHT30_SCLK_Clr();
    for(BitCnt = 0; BitCnt < 8; BitCnt++)
    {
        if(byte & 0x80) { SHT30_SDA_Set(); }
        else { SHT30_SDA_Clr(); }
        byte <<= 1;
        delay_us(2);
        SHT30_SCLK_Set();
        delay_us(2);
        SHT30_SCLK_Clr();
        delay_us(2);
    }
}

uint8_t IIC_RcvByte(void)
{
    uint8_t BitCnt;
    uint8_t retc;
    retc = 0;
    SHT30_SDA_IN();
    delay_us(1);
    for(BitCnt = 0; BitCnt < 8; BitCnt++)
    {
        SHT30_SCLK_Clr();
        delay_us(2);
        SHT30_SCLK_Set();
        retc = retc << 1;
        if(SHT30_READ_SDA()) { retc |= 1; }
        delay_us(1);
    }
    SHT30_SCLK_Clr();
    return (retc);
}


/*温湿度获取函数
函数原型：SHT30_read_result(float *Temperature,float *Humidity)
功能：用来接收器件采集并合成温湿度
*/

void SHT30_read_result(float *Temperature,float *Humidity)
{
    uint16_t tem, hum;
    uint8_t buff[6];
	/*****************************Code Start 5*********************************/
    SHT30_IIC_Start();
    IIC_SendByte(0x44 << 1 | write);
    IIC_wait_ACK();
    IIC_SendByte(0x2C);
    IIC_wait_ACK();
    IIC_SendByte(0x06);
    IIC_wait_ACK();
    SHT30_IIC_Stop();
    delay_ms(50);
    SHT30_IIC_Start();
    IIC_SendByte(0x44 << 1 | read);
    if(IIC_wait_ACK() == 0)
    {
        buff[0] = IIC_RcvByte();
        IIC_ACK();
        buff[1] = IIC_RcvByte();
        IIC_ACK();
        buff[2] = IIC_RcvByte();
        IIC_ACK();
        buff[3] = IIC_RcvByte();
        IIC_ACK();
        buff[4] = IIC_RcvByte();
        IIC_ACK();
        buff[5] = IIC_RcvByte();
        IIC_ACK();
        SHT30_IIC_Stop();
    }

    tem = buff[0];
    tem = (tem << 8) + buff[1];
    hum = buff[3];
    hum = (hum << 8) + buff[4];

    //转换实际温度
    *Temperature =(175.0f * (float)tem / 65535.0f - 45.0f);
    *Humidity    =(100.0f * (float)hum / 65535.0f);
	/*****************************Code End 5***********************************/
}


