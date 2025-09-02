#include <stdint.h>

#define SIMULATION
#define LED_BASE_ADDR 0x000F0000
#define LED_COUNT 8
#ifdef SIMULATION
    #define WAIT_COUNT 1
#else
    #define WAIT_COUNT 0xFC000
#endif

void led_pattern();
void wait(uint32_t count);

volatile uint32_t* led_ptr2 = (volatile uint32_t*) LED_BASE_ADDR;

int _main(void)
{
    *led_ptr2 = 0; // off all LEDs
    while(1){
        led_pattern();
    }
    return 0;

    
}

void led_pattern(){
    uint32_t led_val = 0;
    // fill
    for(int32_t i=0; i<LED_COUNT; i++){
        led_val = (led_val<<1) + 1;
        *led_ptr2 = led_val;
        wait(WAIT_COUNT);
    }
    // flush
    for(int32_t i=0; i<LED_COUNT; i++){
        led_val = led_val<<1;
        *led_ptr2 = led_val;
        wait(WAIT_COUNT);
    }
}

void wait(uint32_t count) {
    for (uint32_t i = 0; i < count; i++) {
        __asm__ volatile("nop");
    }
}

void _sw_isr(void){
    
}

void _can_isr(void){
    
}