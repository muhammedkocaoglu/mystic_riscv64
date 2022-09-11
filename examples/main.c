#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>


int main(void) {

  uint32_t uart_status_reg;

  uint32_t  *uart_ctrl   = (uint32_t  *)0x40000000; 
  uint32_t  *uart_status = (uint32_t  *)0x40000004; 
  uint32_t  *uart_wdata  = (uint32_t  *)0x4000000c; 

  char c[] = "Hello world! How are you doing? My name is Muhammed Kocaoglu! \n \
  This is a 64 bit RISC-V based SoC.\n \
  It supports I(Integer), M(Multiply-divide), and C(Compressed) instructions. \n \
  The core has UART and SPI peripherals.\n \
  What you see on the terminal is printed by the processor I designed :).\n \
  This is actually the first processor I designed.\n \
  I plan to increase the performance with a pipelined architecture in the future.\n \
  I also want to add Direct Memory Access(DMA) feature to my processor to \n \
  understand the logic behind it. There is a lot to learn !!! \n \
  \n \
  The SoC can run at 100 MHZ on Arty A7 35T FPGA board. \n \
  \n \
  By the way, you can find the source codes in my Github account. \n \
  ";

/*
 *uart_ctrl = 868*pow(2, 16) + 0*pow(2, 2)  + 0*pow(2, 1) + 1*pow(2, 0); // 868  +  ... + 0 + 1 // 568885249
 uart_status_reg = *uart_status;
 for (size_t i = 0; i < 40; i++) {
    *uart_wdata = i;
    while (1)  {
      uart_status_reg = *uart_status;
      if (uart_status_reg != 9) {
        break;
      }
    }
 }
*/
  uart_status_reg = *uart_status;
   for (int i = 0; c[i] != '\0'; i++) {
    while (1)  {
      uart_status_reg = *uart_status;
      if (uart_status_reg != 9) {
        break;
      }
    }

    *uart_wdata = c[i];
  }



  return 0;
}
