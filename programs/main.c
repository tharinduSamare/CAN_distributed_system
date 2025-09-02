#include <stdint.h>
#include "can.h"

#define SIMULATION

#define IMEMSZ 1024

#define CFG_BADR_MEM   0x00000000// fixed, must start from 0
#define CFG_BADR_DMEM  CFG_BADR_MEM + IMEMSZ*4;
#define CFG_BADR_LED   0x000F0000
#define CFG_BADR_SW    0x000F0010
#define CFG_BADR_Scrolling    0x000F0040
#define CFG_BADR_CAN   0x00F1000

#define DATA_SET_SIZE 16
#define LED_COUNT 8

#define CAN_ID 0b00000100001 // {00001,<group_id>}
#define CAN_UPDATE_FREQ_FRAME_TYPE 0x03
#define CAN_DATA_ADD_FRAME_TYPE 0x01
#define CAN_DATA_SET_CLEAR_FRAME_TYPE 0x00
#define CAN_INIT_DATASET_FRAME_REQ_TYPE 0x04
#define CAN_INIT_DATASET_FRAME_RESP_TYPE 0x04

#ifdef SIMULATION
    #define INITIAL_SCROLLING_SPEED_COUNT 1
#else
    #define INITIAL_SCROLLING_SPEED_COUNT 25e6
#endif


volatile uint32_t* led_ptr = (volatile uint32_t*) CFG_BADR_LED;
volatile uint32_t* sw_ptr  = (volatile uint32_t*) CFG_BADR_SW;
volatile uint32_t* scrolling_ptr  = (volatile uint32_t*) CFG_BADR_Scrolling;
volatile uint8_t* can_ptr = (volatile uint8_t*) CFG_BADR_CAN;
uint32_t sw_val, btn_val;
uint32_t sw_flag, can_flag;
uint32_t data_set[DATA_SET_SIZE];
uint32_t dataset_next_idx;
uint32_t dataset_current_size;
uint32_t scrolling_speed_count;
CAN_rx_msg rx_msg;
CAN_tx_msg tx_msg;
uint32_t abort_tx = 0; // in case there is no other client in network, need to abort trasmission
uint32_t trasmitting = 0; // in case, trasmission is failed due to simultaneous reception, should not update current state based on trasmitted data

void setup();
void loop();
void wait(uint32_t count);
void set_scrolling_speed(uint32_t counter_val);
void broadcast_scrolling_speed(uint32_t counter_val);
void add_data(uint8_t value);
void broadcast_data(uint8_t value);
void clear_dataset();
void broadcast_clear();
void request_initial_dataset();
void resp_initial_dataset();

int _main(void)
{   
    setup();
    loop();
    return 0; // should not reach this line
}

void wait(uint32_t count) {
    for (uint32_t i = 0; i < count; i++) {
        __asm__ volatile("nop");
    }
}

void setup(){
    sw_flag  = 0;
    can_flag = 0;
    dataset_next_idx = 0;
    dataset_current_size = 0;

    *scrolling_ptr       = (1 << 8);  //clear the buffer (bit 8)
    scrolling_speed_count = INITIAL_SCROLLING_SPEED_COUNT;
    set_scrolling_speed(scrolling_speed_count);
    *scrolling_ptr       = 1;         //turn it on (bit 0)

    abort_tx = 0;
    CAN_initialize_transreceiver(can_ptr);

    return;
}

void loop(){
    while(1){
        if(sw_flag){
            sw_val = sw_val & 0xFFFF; // only low 16 bits represent switch values
            btn_val = btn_val & 0x1F; // only low 5 bits represent button values

            // add value to dataset (BTNU=1)
            if(btn_val & (1<<1)){
                uint8_t value = sw_val & 0x1F;
                trasmitting = 1;
                broadcast_data(value);
                if (trasmitting == 1){ // if no valid CAN receptions
                    trasmitting = 0;
                    add_data(value);
                }
            }
            
            // clear data set (BTND=1)
            else if(btn_val & (1<<4)){
                trasmitting = 1;
                broadcast_clear();
                if(trasmitting == 1){ // if no valid CAN receptions
                    trasmitting = 0;
                    clear_dataset();
                }
            }

            // set scrolling speed (BTNL=1)
            else if(btn_val & (1<<2)){
                scrolling_speed_count = (sw_val << 16); // switches represent the MSB 16 bits
                trasmitting = 1;
                broadcast_scrolling_speed(scrolling_speed_count);
                if(trasmitting == 1){ // if no valid CAN receptions
                    trasmitting = 0;
                    set_scrolling_speed(scrolling_speed_count);
                }
            }

            // request initial dataset (BTNM=0)
            else if(btn_val & (1<<0)){
                request_initial_dataset();
            }
            sw_flag  = 0;    
        }
        if(can_flag){
            if( ((uint8_t)rx_msg.data[0]) == CAN_DATA_SET_CLEAR_FRAME_TYPE) {
                clear_dataset();
                
            }

            else if(rx_msg.data[0] == CAN_DATA_ADD_FRAME_TYPE){
                add_data(rx_msg.data[1]);
            }

            else if(rx_msg.data[0] == CAN_UPDATE_FREQ_FRAME_TYPE){
                scrolling_speed_count = (rx_msg.data[1] << 24) | (rx_msg.data[2] << 16);
                set_scrolling_speed(scrolling_speed_count);
            }

            else if(rx_msg.data[0] == CAN_INIT_DATASET_FRAME_REQ_TYPE){
                resp_initial_dataset();
            }
            else if (rx_msg.data[0] == CAN_INIT_DATASET_FRAME_RESP_TYPE){
                add_data(rx_msg.data[1]);
            }

            can_flag = 0;
        }
    }

    return;
}

/**
 * @brief _sw_isr will be triggered when a button is pressed
 * 
 * Buttons: 0: BTNC, 1: BTNU, 2: BTNL, 3: BTNR, 4: BTND
 * 
 * - BTNU : add value to dataset
 * 
 * - BTND : clear data set
 * 
 * - BTNL : set scrolling speed
 */
__attribute__((interrupt))
void _sw_isr(void){ 
    sw_val = *sw_ptr;
    btn_val = *(sw_ptr+1);
    sw_flag = 1;
    return;
}

/**
 * @brief _can_isr will trigger when:
 * 
 * - Wake up
 * 
 * - Data overrun
 * 
 * - Error
 * 
 * - Transmit interrupt
 * 
 * - Receive interrupt
 */
__attribute__((interrupt))
void _can_isr(void){
    
    uint8_t interruptRegVal = *(can_ptr+IR_OFFSET);

    // receive data interrupt
    if(interruptRegVal & RI_Bit & !can_flag){
        CAN_receive_data(can_ptr, &rx_msg);
        can_flag = 1;   
        if(trasmitting == 1){ // ongoing trasmission is interrupted by reception
            trasmitting = 0; // avoid update internal states
        }
    }

    // error interrupt
    else if((interruptRegVal & EI_Bit) && !can_flag){
        uint8_t statusRegVal = *(can_ptr+SR_OFFSET);
        if((statusRegVal & (ES_Bit | TS_Bit)) == (ES_Bit | TS_Bit)){ // trasmission failure
            abort_tx = 1;
        }
    }
    return;
}

void set_scrolling_speed(uint32_t counter_val){
    *(scrolling_ptr + 1) = counter_val; // cnt_value 
}

void broadcast_scrolling_speed(uint32_t counter_val){
    CAN_tx_msg tx_msg;

    tx_msg.data[0] = CAN_UPDATE_FREQ_FRAME_TYPE;
    tx_msg.data[1] = ((counter_val >> 24) & 0xFF);
    tx_msg.data[2] = ((counter_val >> 16) & 0xFF);
    tx_msg.id = CAN_ID;
    tx_msg.len = 0x03;
    tx_msg.rtr = CAN_RESP_RTR;

    CAN_send_data_polling(can_ptr, tx_msg, &abort_tx);
}

void add_data(uint8_t value){
    data_set[dataset_next_idx] = (uint32_t)value;
    dataset_next_idx = (dataset_next_idx+1)%DATA_SET_SIZE;
    if(dataset_current_size < DATA_SET_SIZE){
        dataset_current_size ++;
    }
    *scrolling_ptr       = (1 << 24) | (value << 16);  //buffer_write (bit 24) and buffer_data (bit 16-20)
}

void broadcast_data(uint8_t value){
    CAN_tx_msg tx_msg;

    tx_msg.data[0] = CAN_DATA_ADD_FRAME_TYPE;
    tx_msg.data[1] = value;
    tx_msg.id = CAN_ID;
    tx_msg.len = 0x02;
    tx_msg.rtr = CAN_RESP_RTR;

    CAN_send_data_polling(can_ptr, tx_msg, &abort_tx);
}

void clear_dataset(){
    dataset_next_idx = 0;
    dataset_current_size = 0;
    *scrolling_ptr       = (1 << 8);  //clear the buffer (bit 8)
}

void broadcast_clear(){
    CAN_tx_msg tx_msg;
    tx_msg.data[0] = CAN_DATA_SET_CLEAR_FRAME_TYPE;
    tx_msg.id = CAN_ID;
    tx_msg.len = 0x01;
    tx_msg.rtr = CAN_RESP_RTR;
    CAN_send_data_polling(can_ptr, tx_msg, &abort_tx);
}

void request_initial_dataset(){
    CAN_tx_msg tx_msg;
    tx_msg.data[0] = CAN_INIT_DATASET_FRAME_REQ_TYPE;
    tx_msg.id = CAN_ID;
    tx_msg.len = 0x01;
    tx_msg.rtr = CAN_RESP_RTR;
    CAN_send_data_polling(can_ptr, tx_msg, &abort_tx);
}

void resp_initial_dataset(){
    broadcast_scrolling_speed(scrolling_speed_count);
    for(uint32_t i=0; i<dataset_current_size; i++){
        broadcast_data((uint8_t)data_set[i]);
    }
}