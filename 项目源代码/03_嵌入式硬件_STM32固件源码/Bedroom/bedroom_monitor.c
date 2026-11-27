#include "stm32l4xx_hal.h"                  // Device header
#include "bedroom_eth30.h"

float temp;
float humi;

void  bedroom_monitor(void){
	//监测温湿度
 SHT30_read_result(&temp,&humi);
	
	//将来还能监测其它的
	
	
}