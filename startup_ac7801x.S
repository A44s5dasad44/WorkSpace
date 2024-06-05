/* Copyright Statement:
 *
 * This software/firmware and related documentation ("AutoChips Software") are
 * protected under relevant copyright laws. The information contained herein is
 * confidential and proprietary to AutoChips Inc. and/or its licensors. Without
 * the prior written permission of AutoChips inc. and/or its licensors, any
 * reproduction, modification, use or disclosure of AutoChips Software, and
 * information contained herein, in whole or in part, shall be strictly
 * prohibited.
 *
 * AutoChips Inc. (C) 2016. All rights reserved.
 *
 * BY OPENING THIS FILE, RECEIVER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
 * THAT THE SOFTWARE/FIRMWARE AND ITS DOCUMENTATIONS ("AUTOCHIPS SOFTWARE")
 * RECEIVED FROM AUTOCHIPS AND/OR ITS REPRESENTATIVES ARE PROVIDED TO RECEIVER
 * ON AN "AS-IS" BASIS ONLY. AUTOCHIPS EXPRESSLY DISCLAIMS ANY AND ALL
 * WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR
 * NONINFRINGEMENT. NEITHER DOES AUTOCHIPS PROVIDE ANY WARRANTY WHATSOEVER WITH
 * RESPECT TO THE SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY,
 * INCORPORATED IN, OR SUPPLIED WITH THE AUTOCHIPS SOFTWARE, AND RECEIVER AGREES
 * TO LOOK ONLY TO SUCH THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO.
 * RECEIVER EXPRESSLY ACKNOWLEDGES THAT IT IS RECEIVER'S SOLE RESPONSIBILITY TO
 * OBTAIN FROM ANY THIRD PARTY ALL PROPER LICENSES CONTAINED IN AUTOCHIPS
 * SOFTWARE. AUTOCHIPS SHALL ALSO NOT BE RESPONSIBLE FOR ANY AUTOCHIPS SOFTWARE
 * RELEASES MADE TO RECEIVER'S SPECIFICATION OR TO CONFORM TO A PARTICULAR
 * STANDARD OR OPEN FORUM. RECEIVER'S SOLE AND EXCLUSIVE REMEDY AND AUTOCHIPS'S
 * ENTIRE AND CUMULATIVE LIABILITY WITH RESPECT TO THE AUTOCHIPS SOFTWARE
 * RELEASED HEREUNDER WILL BE, AT AUTOCHIPS'S OPTION, TO REVISE OR REPLACE THE
 * AUTOCHIPS SOFTWARE AT ISSUE, OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE
 * CHARGE PAID BY RECEIVER TO AUTOCHIPS FOR SUCH AUTOCHIPS SOFTWARE AT ISSUE.
 */
/*******************************************************************************
*
* @file startup_ac7801x.S
*
* @author AutoChips
*
* @version 0.0.1
*
* @date Jan.02.2019
*
* @brief     AC7801x Devices vector table for GCC based toolchain.
*            This module performs:
*                - Set the initial SP
*                - Set the initial PC == Reset_Handler,
*                - Set the vector table entries with the exceptions ISR address
*                - Configure the clock system  
*                - Branches to main in the C library (which eventually
*                  calls main()).
*            After Reset the Cortex-M3 processor is in Thread mode,
*            priority is Privileged, and the Stack is set to Main.
*******************************************************************************/
    
  .syntax unified
  .cpu cortex-m0plus
  .fpu softvfp
  .thumb

.global  g_pfnVectors
.global  Default_Handler
.global __Vectors

/* start address for the initialization values of the .data section. 
defined in linker script */
.word  _sidata
/* start address for the .data section. defined in linker script */  
.word  _sdata
/* end address for the .data section. defined in linker script */
.word  _edata
/* start address for the .bss section. defined in linker script */
.word  _sbss
/* end address for the .bss section. defined in linker script */
.word  _ebss
/* stack used for SystemInit_ExtMemCtl; always internal RAM used */

/**
 * @brief  This is the code that gets called when the processor first
 *          starts execution following a reset event. Only the absolutely
 *          necessary set is performed, after which the application
 *          supplied main() routine is called. 
 * @param  None
 * @retval : None
*/

    .section  .text.Reset_Handler
  .weak  Reset_Handler
  .type  Reset_Handler, %function
Reset_Handler:  

/* Copy the data segment initializers from flash to SRAM */  
  movs  r1, #0
  b  LoopCopyDataInit

CopyDataInit:
  ldr  r3, =_sidata
  ldr  r3, [r3, r1]
  str  r3, [r0, r1]
  adds  r1, r1, #4
    
LoopCopyDataInit:
  ldr  r0, =_sdata
  ldr  r3, =_edata
  adds  r2, r0, r1
  cmp  r2, r3
  bcc  CopyDataInit
  ldr  r2, =_sbss
  b  LoopFillZerobss
/* Zero fill the bss segment. */  
FillZerobss:
  movs  r3, #0
  str  r3, [r2]
  movs  r3, #4
  add r2, r2, r3
    
LoopFillZerobss:
  ldr  r3, = _ebss
  cmp  r2, r3
  bcc  FillZerobss

/* Call the clock system intitialization function.*/
  bl  SystemInit   
  
  ldr     R0, =0x20080014
  ldr     R1, =0xFFFF
  strh    R1, [R0]

  ldr     R0, =0x20080044
  ldr     R1, =0xFFFF
  strh    R1, [R0]

  ldr     R0, =0x20080074
  ldr     R1, =0x3FF
  strh    R1, [R0]
		
/* Call static constructors */
/*    bl __libc_init_array    */
/* Call the application's entry point.'*/
  bl  main
  bx  lr    
.size  Reset_Handler, .-Reset_Handler

/**
 * @brief  This is the code that gets called when the processor receives an 
 *         unexpected interrupt.  This simply enters an infinite loop, preserving
 *         the system state for examination by a debugger.
 * @param  None     
 * @retval None       
*/
    .section  .text.Default_Handler,"ax",%progbits
Default_Handler:
Infinite_Loop:
  b  Infinite_Loop
  .size  Default_Handler, .-Default_Handler
/******************************************************************************
*
* The minimal vector table for a Cortex M3. Note that the proper constructs
* must be placed on this to ensure that it ends up at physical address
* 0x0000.0000.
* 
*******************************************************************************/
   .section  .isr_vector,"a",%progbits
  .type  g_pfnVectors, %object
  .size  g_pfnVectors, .-g_pfnVectors
    
g_pfnVectors:
	.word  _estack
	.word  Reset_Handler
	.word  NMI_Handler
	.word  HardFault_Handler
	.word  0
	.word  0
	.word  0
	.word  0
	.word  0
	.word  0
	.word  0
	.word  SVC_Handler
	.word  0
	.word  0
	.word  PendSV_Handler
	.word  SysTick_Handler
   
/* External interrupts */
	.word     PWDT0_IRQHandler
	.word     PWDT1_IRQHandler
	.word     PWM0_IRQHandler
	.word     PWM1_IRQHandler
	.word     ACMP0_IRQHandler
	.word     UART0_IRQHandler
	.word     UART1_IRQHandler
	.word     UART2_IRQHandler
	.word     WDG_IRQHandler
	.word     SPI0_IRQHandler
	.word     SPI1_IRQHandler
	.word     I2C0_IRQHandler
	.word     I2C1_IRQHandler
	.word     DMA0_Channel0_IRQHandler
	.word     DMA0_Channel1_IRQHandler
	.word     DMA0_Channel2_IRQHandler
	.word     DMA0_Channel3_IRQHandler
	.word     TIMER_Channel0_IRQHandler
	.word     TIMER_Channel1_IRQHandler
	.word     TIMER_Channel2_IRQHandler
	.word     TIMER_Channel3_IRQHandler
	.word     RTC_IRQHandler
	.word     PVD_IRQHandler
	.word     SPM_IRQHandler
	.word     CAN0_Handler
	.word     ADC0_IRQHandler
	.word     ECC_SRAM_IRQHandler
	.word     EXTI0_IRQHandler
	.word     EXTI1_IRQHandler
    .word     EXTI2_IRQHandler
    .word     EXTI3_8_IRQHandler
    .word	  EXTI9_15_IRQHandler
__Vectors_End = .

__Vectors     =   g_pfnVectors
/*******************************************************************************
*
* Provide weak aliases for each Exception handler to the Default_Handler. 
* As they are weak aliases, any function with the same name will override 
* this definition.
* 
*******************************************************************************/
   .weak      NMI_Handler
   .thumb_set NMI_Handler,Default_Handler
  
   .weak      HardFault_Handler
   .thumb_set HardFault_Handler,Default_Handler

   .weak      SVC_Handler
   .thumb_set SVC_Handler,Default_Handler

   .weak      PendSV_Handler
   .thumb_set PendSV_Handler,Default_Handler

   .weak      SysTick_Handler
   .thumb_set SysTick_Handler,Default_Handler              
  
   .weak      PWDT0_IRQHandler                   
   .thumb_set PWDT0_IRQHandler,Default_Handler      
                  
   .weak      PWDT1_IRQHandler      
   .thumb_set PWDT1_IRQHandler,Default_Handler
               
   .weak      PWM0_IRQHandler            
   .thumb_set PWM0_IRQHandler,Default_Handler
            
   .weak      PWM1_IRQHandler                  
   .thumb_set PWM1_IRQHandler,Default_Handler
            
   .weak      ACMP0_IRQHandler         
   .thumb_set ACMP0_IRQHandler,Default_Handler
                  
   .weak      UART0_IRQHandler      
   .thumb_set UART0_IRQHandler,Default_Handler
                  
   .weak      UART1_IRQHandler      
   .thumb_set UART1_IRQHandler,Default_Handler
   
   .weak      UART2_IRQHandler         
   .thumb_set UART2_IRQHandler,Default_Handler
                  
   .weak      WDG_IRQHandler         
   .thumb_set WDG_IRQHandler,Default_Handler
                     
   .weak      SPI0_IRQHandler         
   .thumb_set SPI0_IRQHandler,Default_Handler 
                 
   .weak      SPI1_IRQHandler         
   .thumb_set SPI1_IRQHandler,Default_Handler
                        
   .weak      I2C0_IRQHandler         
   .thumb_set I2C0_IRQHandler,Default_Handler

   .weak      I2C1_IRQHandler         
   .thumb_set I2C1_IRQHandler,Default_Handler   
   
   .weak      DMA0_Channel0_IRQHandler               
   .thumb_set DMA0_Channel0_IRQHandler,Default_Handler
         
   .weak      DMA0_Channel1_IRQHandler               
   .thumb_set DMA0_Channel1_IRQHandler,Default_Handler
                  
   .weak      DMA0_Channel2_IRQHandler               
   .thumb_set DMA0_Channel2_IRQHandler,Default_Handler
                  
   .weak      DMA0_Channel3_IRQHandler               
   .thumb_set DMA0_Channel3_IRQHandler,Default_Handler 
                 
   .weak      TIMER_Channel0_IRQHandler              
   .thumb_set TIMER_Channel0_IRQHandler,Default_Handler
                  
   .weak      TIMER_Channel1_IRQHandler               
   .thumb_set TIMER_Channel1_IRQHandler,Default_Handler
                  
   .weak      TIMER_Channel2_IRQHandler               
   .thumb_set TIMER_Channel2_IRQHandler,Default_Handler
                  
   .weak      TIMER_Channel3_IRQHandler              
   .thumb_set TIMER_Channel3_IRQHandler,Default_Handler
                  
   .weak      RTC_IRQHandler               
   .thumb_set RTC_IRQHandler,Default_Handler
                  
   .weak      PVD_IRQHandler               
   .thumb_set PVD_IRQHandler,Default_Handler

   .weak      SPM_IRQHandler              
   .thumb_set SPM_IRQHandler,Default_Handler
                  
   .weak      CAN0_Handler               
   .thumb_set CAN0_Handler,Default_Handler
                  
   .weak      ADC0_IRQHandler               
   .thumb_set ADC0_IRQHandler,Default_Handler
   
   .weak      ECC_SRAM_IRQHandler              
   .thumb_set ECC_SRAM_IRQHandler,Default_Handler
                  
   .weak      EXTI0_IRQHandler               
   .thumb_set EXTI0_IRQHandler,Default_Handler
                  
   .weak      EXTI1_IRQHandler               
   .thumb_set EXTI1_IRQHandler,Default_Handler

   .weak      EXTI2_IRQHandler            
   .thumb_set EXTI2_IRQHandler,Default_Handler
                        
   .weak      EXTI3_8_IRQHandler            
   .thumb_set EXTI3_8_IRQHandler,Default_Handler   
   
   .weak      EXTI9_15_IRQHandler      
   .thumb_set EXTI9_15_IRQHandler,Default_Handler


