#define CR_OFFSET 0 // control register
#define CMR_OFFSET 1 // command register
#define SR_OFFSET 2 // status register
#define IR_OFFSET 3 // interrupt register
#define ACR_OFFSET 4 // Acceptance Code Register
#define AMR_OFFSET 5 // Acceptance Mask Register
#define BTR0_OFFSET 6 // Bus Timing Register 0
#define BTR1_OFFSET 7 // Bus Timing Register 1
#define OCR_OFFSET 8 // Output Control Register
#define TX_ID_BUF0_OFFSET 10 // [ID.10: ID.3]
#define TX_ID_BUF1_OFFSET 11 // [ID.2: ID.0],  RTR, [DLC.3:DLC.0]
#define TX_DATA_BUF0_OFFSET 12 // data0
#define RX_ID_BUF0_OFFSET 20 // [ID.10: ID.3]
#define RX_ID_BUF1_OFFSET 21 // [ID.2: ID.0],  RTR, [DLC.3:DLC.0]
#define RX_DATA_BUF0_OFFSET 22 // data0
#define CLK_DIVIDER_REG_OFFSET 31
struct CAN_tx_msg_s{
    uint32_t id;		    // Frame ID
    uint32_t rtr;		    // RTR/Data Frame
    uint32_t len;		    // Data Length
    uint32_t data[8];		// Data Bytes
};			      // length 15 byte

typedef struct CAN_tx_msg_s CAN_tx_msg;

struct CAN_rx_msg_s {
    uint32_t id;		    // Frame ID
    uint32_t rtr;		    // RTR/Data Frame
    uint32_t len;		    // Data Length
    uint32_t data[8];		// Data Bytes
};	

typedef struct CAN_rx_msg_s CAN_rx_msg;

void CAN_initialize_transreceiver(volatile uint8_t* can_ptr);
void CAN_send_data_polling(volatile uint8_t* can_ptr, CAN_tx_msg tx_msg, uint32_t *abort_tx);
void CAN_receive_data(volatile uint8_t* can_ptr, CAN_rx_msg* rx_msg);

/* definition for direct access to 8051 memory areas */
#define XBYTE ((unsigned char volatile xdata *) 0)
/* address and bit definitions for the Mode & Control Register */
#define ModeControlReg XBYTE[0]
#define RM_RR_Bit 0x01 /* reset mode (request) bit */
#if defined (PeliCANMode)
#define LOM_Bit 0x02 /* listen only mode bit */
#define STM_Bit 0x04 /* self test mode bit */
#define AFM_Bit 0x08 /* acceptance filter mode bit */
#define SM_Bit 0x10 /* enter sleep mode bit */
#endif
/* address and bit definitions for the
 Interrupt Enable & Control Register */
#if defined (PeliCANMode)
#define InterruptEnReg XBYTE[4] /* PeliCAN mode */
#define RIE_Bit 0x01 /* receive interrupt enable bit */
#define TIE_Bit 0x02 /* transmit interrupt enable bit */
#define EIE_Bit 0x04 /* error warning interrupt enable bit */
#define DOIE_Bit 0x08 /* data overrun interrupt enable bit */
#define WUIE_Bit 0x10 /* wake-up interrupt enable bit */
#define EPIE_Bit 0x20 /* error passive interrupt enable bit */
#define ALIE_Bit 0x40 /* arbitration lost interr. enable bit*/
#define BEIE_Bit 0x80 /* bus error interrupt enable bit */
#else /* BasicCAN mode */
#define InterruptEnReg XBYTE[0] /* Control Register */

#define CAN_RESP_RTR 0b0
#define CAN_REQ_RTR 0b1

#define RIE_Bit 0x02 /* Receive Interrupt enable bit */
#define TIE_Bit 0x04 /* Transmit Interrupt enable bit */
#define EIE_Bit 0x08 /* Error Interrupt enable bit */
#define DOIE_Bit 0x10 /* Overrun Interrupt enable bit */
#endif
/* address and bit definitions for the Command Register */
#define CommandReg XBYTE[1]
#define TR_Bit 0x01 /* transmission request bit */
#define AT_Bit 0x02 /* abort transmission bit */
#define RRB_Bit 0x04 /* release receive buffer bit */
#define CDO_Bit 0x08 /* clear data overrun bit */
#if defined (PeliCANMode)
#define SRR_Bit 0x10 /* self reception request bit */
#else /* BasicCAN mode */
#define GTS_Bit 0x10 /* goto sleep bit (BasicCAN mode) */
#endif
/* address and bit definitions for the Status Register */
#define StatusReg XBYTE[2]
#define RBS_Bit 0x01 /* receive buffer status bit */
#define DOS_Bit 0x02 /* data overrun status bit */
#define TBS_Bit 0x04 /* transmit buffer status bit */
#define TCS_Bit 0x08 /* transmission complete status bit */
#define RS_Bit 0x10 /* receive status bit */
#define TS_Bit 0x20 /* transmit status bit */
#define ES_Bit 0x40 /* error status bit */
#define BS_Bit 0x80 /* bus status bit */
/* address and bit definitions for the Interrupt Register */
#define InterruptReg XBYTE[3]
#define RI_Bit 0x01 /* receive interrupt bit */
#define TI_Bit 0x02 /* transmit interrupt bit */
#define EI_Bit 0x04 /* error warning interrupt bit */
#define DOI_Bit 0x08 /* data overrun interrupt bit */
#define WUI_Bit 0x10 /* wake-up interrupt bit */
#if defined (PeliCANMode)
#define EPI_Bit 0x20 /* error passive interrupt bit */
#define ALI_Bit 0x40 /* arbitration lost interrupt bit */
#define BEI_Bit 0x80 /* bus error interrupt bit */
#endif
/* address and bit definitions for the Bus Timing Registers */
#define BusTiming0Reg XBYTE[6]
#define BusTiming1Reg XBYTE[7]
#define SAM_Bit 0x80 
/* sample mode bit 
 1 == the bus is sampled 3 times
 0 == the bus is sampled once */
/* address and bit definitions for the Output Control Register */
#define OutControlReg XBYTE[8]
 /* OCMODE1, OCMODE0 */
#define BiPhaseMode 0x00 /* bi-phase output mode */
#define NormalMode 0x02 /* normal output mode */
#define ClkOutMode 0x03 /* clock output mode */
 /* output pin configuration for TX1 */
#define OCPOL1_Bit 0x20 /* output polarity control bit */
#define Tx1Float 0x00 /* configured as float */
#define Tx1PullDn 0x40 /* configured as pull-down */
#define Tx1PullUp 0x80 /* configured as pull-up */
#define Tx1PshPull 0xC0 /* configured as push/pull */

 /* output pin configuration for TX0 */
 #define OCPOL0_Bit 0x04 /* output polarity control bit */
 #define Tx0Float 0x00 /* configured as float */
 #define Tx0PullDn 0x08 /* configured as pull-down */
 #define Tx0PullUp 0x10 /* configured as pull-up */
 #define Tx0PshPull 0x18 /* configured as push/pull */
 /* address definitions of Acceptance Code & Mask Registers */
 #if defined (PeliCANMode)
 #define AcceptCode0Reg XBYTE[16]
 #define AcceptCode1Reg XBYTE[17]
 #define AcceptCode2Reg XBYTE[18]
 #define AcceptCode3Reg XBYTE[19]
 #define AcceptMask0Reg XBYTE[20]
 #define AcceptMask1Reg XBYTE[21]
 #define AcceptMask2Reg XBYTE[22]
 #define AcceptMask3Reg XBYTE[23]
 #else /* BasicCAN mode */
 #define AcceptCodeReg XBYTE[4]
 #define AcceptMaskReg XBYTE[5]
 #endif
 /* address definitions of the Rx-Buffer */
 #if defined (PeliCANMode)
 #define RxFrameInfo XBYTE[16]
 #define RxBuffer1 XBYTE[17]
 #define RxBuffer2 XBYTE[18]
 #define RxBuffer3 XBYTE[19]
 #define RxBuffer4 XBYTE[20]
 #define RxBuffer5 XBYTE[21]
 #define RxBuffer6 XBYTE[22]
 #define RxBuffer7 XBYTE[23]
 #define RxBuffer8 XBYTE[24]
 #define RxBuffer9 XBYTE[25]
 #define RxBuffer10 XBYTE[26]
 #define RxBuffer11 XBYTE[27]
 #define RxBuffer12 XBYTE[28]
 #else /* BasicCAN mode */
 #define RxBuffer1 XBYTE[20]
#define RxBuffer2 XBYTE[21]
#define RxBuffer3 XBYTE[22]
#define RxBuffer4 XBYTE[23]
#define RxBuffer5 XBYTE[24]
#define RxBuffer6 XBYTE[25]
#define RxBuffer7 XBYTE[26]
#define RxBuffer8 XBYTE[27]
#define RxBuffer9 XBYTE[28]
#define RxBuffer10 XBYTE[29]
#endif
/* address definitions of the Tx-Buffer */
#if defined (PeliCANMode)
/* write only addresses */
#define TxFrameInfo XBYTE[16]
#define TxBuffer1 XBYTE[17]
#define TxBuffer2 XBYTE[18]
#define TxBuffer3 XBYTE[19]
#define TxBuffer4 XBYTE[20]
#define TxBuffer5 XBYTE[21]
#define TxBuffer6 XBYTE[22]
#define TxBuffer7 XBYTE[23]
#define TxBuffer8 XBYTE[24]
#define TxBuffer9 XBYTE[25]
#define TxBuffer10 XBYTE[26]
#define TxBuffer11 XBYTE[27]
#define TxBuffer12 XBYTE[28]
/* read only addresses */
#define TxFrameInfoRd XBYTE[96]
#define TxBufferRd1 XBYTE[97]
#define TxBufferRd2 XBYTE[98]
#define TxBufferRd3 XBYTE[99]
#define TxBufferRd4 XBYTE[100]
#define TxBufferRd5 XBYTE[101]
#define TxBufferRd6 XBYTE[102]
#define TxBufferRd7 XBYTE[103]
#define TxBufferRd8 XBYTE[104]
#define TxBufferRd9 XBYTE[105]
#define TxBufferRd10 XBYTE[106]
#define TxBufferRd11 XBYTE[107]
#define TxBufferRd12 XBYTE[108]
#else /* BasicCAN mode */
#define TxBuffer1 XBYTE[10]
#define TxBuffer2 XBYTE[11]
#define TxBuffer3 XBYTE[12]
#define TxBuffer4 XBYTE[13]
#define TxBuffer5 XBYTE[14]
#define TxBuffer6 XBYTE[15]
#define TxBuffer7 XBYTE[16]
#define TxBuffer8 XBYTE[17]
#define TxBuffer9 XBYTE[18]
#define TxBuffer10 XBYTE[19]
#endif

/* address definitions of Other Registers */
#if defined (PeliCANMode)
#define ArbLostCapReg XBYTE[11]
#define ErrCodeCapReg XBYTE[12]
#define ErrWarnLimitReg XBYTE[13]
#define RxErrCountReg XBYTE[14]
#define TxErrCountReg XBYTE[15]
#define RxMsgCountReg XBYTE[29]
#define RxBufStartAdr XBYTE[30]
#endif
/* address and bit definitions for the Clock Divider Register */
#define ClockDivideReg XBYTE[31]
#define DivBy1 0x07 /* CLKOUT = oscillator frequency */
#define DivBy2 0x00 /* CLKOUT = 1/2 oscillator frequency */
#define ClkOff_Bit 0x08 /* clock off bit, control of the CLK OUT pin */
#define RXINTEN_Bit 0x20 /* pin TX1 used for receive interrupt */
#define CBP_Bit 0x40 /* CAN comparator bypass control bit */
#define CANMode_Bit 0x80 /* CAN mode definition bit */


// Register and bit definitions for the Micro Controller S87C654 
// /* Port 2 Register “P2” */
// sfr P2 = 0xA0;
// sbit P2_7 = 0xA7; /* MSB of port 2, used for chip select for SJA1000 */
// .
// /* alternate functions of port 3 “P3” */
// sfr P3 = 0xB0;
// .
// sbit int0 = 0xB2;
// .
// /* Timer Control Register “TCON” */
// sfr TCON = 0x88;
// .
// sbit IE0 = 0x89; /* external interrupt 0 edge flag */
// sbit IT0 = 0x88; /* interrupt 0 type control bit
//  (edge or low-level triggered */
// .
// /* Interrupt Enable Register “IE” */
// sfr IE = 0xA8;
// sbit EA = 0xAF; /* overall interrupt enable/disable flag */
// .
// sbit EX0 = 0xA8; /* enable or disable external interrupt 0 */
// .
// /* Interrupt Priority Register “IP” */
// sfr IP = 0xB8;
// .
// sbit PX0 = 0xB8; /* external interrupt 0 priority level control */

/*- definition of hardware / software connections ----------------------*/
/* controller: S87C654; CAN controller: SJA1000(see Figure 3 on page 11)*/
#define CS P2_7 /* ChipSelect for the SJA1000 */
#define SJAIntInp int0 /* external interrupt 0 (from SJA1000) */
#define SJAIntEn EX0 /* external interrupt 0 enable flag */
/*- definition of used constants ---------------------------------------*/
#define YES 1
#define NO 0
#define ENABLE 1
#define DISABLE 0
#define ENABLE_N 0
#define DISABLE_N 1
#define INTLEVELACT 0
#define INTEDGEACT 1
#define PRIORITY_LOW 0
#define PRIORITY_HIGH 1
/* default (reset) value for register content, clear register */
#define ClrByte 0x00
/* constant: clear Interrupt Enable Register */
#if defined (PeliCANMode)
#define ClrIntEnSJA ClrByte
#else
#define ClrIntEnSJA ClrByte | RM_RR_Bit /* preserve reset request */
#endif
/* definitions for the acceptance code and mask register */
#define DontCare 0xFF
/*- definition of bus timing values for different examples -------*/
/* bus timing values for the example given in (AN97046)
 - bit-rate : 250 kBit/s
 - oscillator frequency : 24 MHz, 1,0%
 - maximum propagation delay : 1630 ns
 - minimum requested propagation delay : 120 ns */
#define PrescExample 0x02 /* baud rate prescaler : 3 */
#define SJWExample 0xC0 /* SJW : 4 */
#define TSEG1Example 0x0A /* TSEG1 : 11 */
#define TSEG2Example 0x30 /* TSEG2 : 4 */
/* bus timing values for
 - bit-rate : 1 MBit/s
 - oscillator frequency : 24 MHz, 0,1%
 - maximum tolerated propagation delay : 747 ns
 - minimum requested propagation delay : 45 ns */
#define Presc_MB_24 0x00 /* baud rate prescaler : 1 */
#define SJW_MB_24 0x00 /* SJW : 1 */

#define TSEG1_MB_24 0x08 /* TSEG1 : 9 */
#define TSEG2_MB_24 0x10 /* TSEG2 : 2 */
/* bus timing values for
 - bit-rate : 100 kBit/s
 - oscillator frequency : 24 MHz, 1,0%
 - maximum tolerated propagation delay : 4250 ns
 - minimum requested propagation delay : 100 ns */
#define Presc_kB_24 0x07 /* baud rate prescaler : 8 */
#define SJW_kB_24 0xC0 /* SJW : 4 */
#define TSEG1_kB_24 0x09 /* TSEG1 : 10 */
#define TSEG2_kB_24 0x30 /* TSEG2 : 4 */
/* bus timing values for
 - bit-rate : 1 MBit/s
 - oscillator frequency : 16 MHz, 0,1%
 - maximum tolerated propagation delay : 623 ns
 - minimum requested propagation delay : 23 ns */
#define Presc_MB_16 0x00 /* baud rate prescaler : 1 */
#define SJW_MB_16 0x00 /* SJW : 1 */
#define TSEG1_MB_16 0x04 /* TSEG1 : 5 */
#define TSEG2_MB_16 0x10 /* TSEG2 : 2 */
/* bus timing values for
 - bit-rate : 100 kBit/s
 - oscillator frequency : 16 MHz, 1,0%
 - maximum tolerated propagation delay : 4450 ns
 - minimum requested propagation delay : 500 ns */
#define Presc_kB_16 0x04 /* baud rate prescaler : 5 */
#define SJW_kB_16 0xC0 /* SJW : 4 */
#define TSEG1_kB_16 0x0A /* TSEG1 : 11 */
#define TSEG2_kB_16 0x30 /* TSEG2 : 4 */
/*- end of definitions of bus timing values ----------------------*/
/*- definition of used variables ---------------------------------*/
/* intermediate storage of the content of the Interrupt Register */
// BYTE bdata CANInterrupt; /* bit addressable byte */
// sbit RI_BitVar = CANInterrupt ^ 0;
// sbit TI_BitVar = CANInterrupt ^ 1;
// sbit EI_BitVar = CANInterrupt ^ 2;
// sbit DOI_BitVar = CANInterrupt ^ 3;
// sbit WUI_BitVar = CANInterrupt ^ 4;
// sbit EPI_BitVar = CANInterrupt ^ 5;
// sbit ALI_BitVar = CANInterrupt ^ 6;
// sbit BEI_BitVar = CANInterrupt ^ 7;