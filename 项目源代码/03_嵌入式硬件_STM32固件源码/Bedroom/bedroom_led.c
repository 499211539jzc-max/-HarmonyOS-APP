#include "stm32l4xx_hal.h"                  // Device header


void  bedroom_led1_on(void){
HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_RESET);

}



void  bedroom_led1_off(void){

HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_SET);
}



void  bedroom_led2_on(void){
HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);

}



void  bedroom_led2_off(void){

HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
}