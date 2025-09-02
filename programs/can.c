#include <stdint.h>
#include "can.h"

#define SIMULATION

#ifdef SIMULATION
    #define CAN_TIMING0_BRP 0x0 /* Baud rate prescaler (2*(value+1)) */
    #define CAN_TIMING0_SJW 0x0 /* SJW (value+1) */
    #define CAN_TIMING1_TSEG1 0x7 /* TSEG1 segment (value+1) */
    #define CAN_TIMING1_TSEG2 0x0 /* TSEG2 segment (value+1) */
    #define CAN_TIMING1_SAM 0x0 /* Triple sampling */
#else
    // ex:-
    // CLK rate : 100MHz
    // Baudrate : 100kHz (78.1kHz)
    // TSEG1 = 0101(6) and TSEG2 = 010 (3)
    // Period = 10 cycles (1+TSESG1+TSEG2)
    // BRP = 5h1F // 128 = (2*64) = (2*(32 × 1 + 16 × 1 + 8 × 1 + 4 × 1 + 2 × 1 + 1 × 1 + 1))

    #define CAN_TIMING0_BRP 0x1F /* Baud rate prescaler (2*(value+1)) */
    #define CAN_TIMING0_SJW 0x0 /* SJW (value+1) */
    #define CAN_TIMING1_TSEG1 0x7 /* TSEG1 segment (value+1) */
    #define CAN_TIMING1_TSEG2 0x0 /* TSEG2 segment (value+1) */
    #define CAN_TIMING1_SAM 0x0 /* Triple sampling */
    
#endif

/**
 * This will initialize the CAN module. It will do following things
 * 
 * 1. Enter reset mode (software reset)
 * 
 * 2. 
 */
void CAN_initialize_transreceiver(volatile uint8_t* can_ptr){

    *(can_ptr+CR_OFFSET) = 0x01; // go to reset mode

    *(can_ptr+CLK_DIVIDER_REG_OFFSET) = 0b00001000; // enable BasicCAN mode + disable clkout

    *(can_ptr+ACR_OFFSET) = ClrByte; // reset acceptance code register
    *(can_ptr+AMR_OFFSET) = DontCare; // accept all identifiers

    *(can_ptr+BTR0_OFFSET) =  (uint8_t)((CAN_TIMING0_SJW << 6) | CAN_TIMING0_BRP);//0x4;
    *(can_ptr+BTR1_OFFSET) = (uint8_t)((CAN_TIMING1_SAM<<7) | (CAN_TIMING1_TSEG2<<4) | CAN_TIMING1_TSEG1);//0x7; //

    *(can_ptr+OCR_OFFSET) = Tx1Float | Tx0PshPull | NormalMode;

    // clear reset bit + set interrupts
    uint8_t ctrl_reg_val = DOIE_Bit | EIE_Bit | TIE_Bit | RIE_Bit;
    do{
        *(can_ptr+CR_OFFSET) = ctrl_reg_val;
    }
    while(((*(can_ptr+CR_OFFSET)) & RM_RR_Bit) != ClrByte);

    return;
}

void CAN_send_data_polling(volatile uint8_t* can_ptr, CAN_tx_msg tx_msg, uint32_t *abort_tx){
    if(tx_msg.len > 8) tx_msg.len = 8;

    while((*(can_ptr+SR_OFFSET) & TBS_Bit ) != TBS_Bit ){ // [TODO] Make sure this is compiled without disappearing
        if(*abort_tx == 1){ // ex:- in case bus disconnect
            *abort_tx = 0;
            return;
        }
    }

    *(can_ptr+TX_ID_BUF0_OFFSET) = (uint8_t)((tx_msg.id>>3) & 0xF); // ID[10:3]
    // __asm__ volatile ("fence iorw, iorw"); 
    *(can_ptr+TX_ID_BUF1_OFFSET) = (uint8_t)(((tx_msg.id & 0b111)<<5) | ((tx_msg.rtr & 0b1)<<4) | (tx_msg.len & 0xF)); // [ID.2: ID.0], RTR, [DLC.3:DLC.0]

    // set data values
    for(uint8_t i=0; i< tx_msg.len; i++){
        *(can_ptr+TX_DATA_BUF0_OFFSET+i) = (uint8_t)(tx_msg.data[i]);
    }

    // request for transmission
    *(can_ptr+CMR_OFFSET) = TR_Bit;

    // wait for the transmission to be completed
    while((*(can_ptr+SR_OFFSET) & TCS_Bit ) != TCS_Bit ){
        if(*abort_tx == 1){ // ex:- in case bus disconnect
            *(can_ptr+CMR_OFFSET) = AT_Bit;
            abort_tx = 0;
            return;
        }
    }
    return;
}

void CAN_receive_data(volatile uint8_t* can_ptr, CAN_rx_msg* rx_msg){
 
    (*rx_msg).id = ((uint32_t)(*(can_ptr+RX_ID_BUF0_OFFSET)))<<3 | ((uint32_t)(*(can_ptr+RX_ID_BUF1_OFFSET)))>>5;
    (*rx_msg).rtr = (uint32_t)((*(can_ptr+RX_ID_BUF1_OFFSET)>>4) & 0x1);
    (*rx_msg).len = (uint32_t)(*(can_ptr+RX_ID_BUF1_OFFSET) & 0xF);
    if((*rx_msg).len>8) (*rx_msg).len = 8;
    
    for(uint32_t i=0; i<(*rx_msg).len; i++){
        (*rx_msg).data[i] = (uint32_t)(*(can_ptr+RX_DATA_BUF0_OFFSET+i));
    }
    
    
    *(can_ptr+CMR_OFFSET) = RRB_Bit;//release the recieve buffer
    return;
}