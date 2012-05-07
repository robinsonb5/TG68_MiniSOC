-- Toplevel file for Altera DE1 board

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------


entity chameleon_pong_top is
port
	(
		-- clock inputs
		CLOCK_24 : in std_logic_vector(1 downto 0),	-- 24 Mhz
		CLOCK_27 : in std_logic_vector(1 downto 0),	-- 27 MHz
		CLOCK_50 : in std_logic,	-- 50 MHz
		EXT_CLOCK : in std_logic,	-- External Clock

		KEY : in std_logic(3 downto 0), -- Push-buttons
		SW : in std_logic(9 downto 0), -- Toggle switches

		HEX0 : out std_logic_vector(6 downto 0), -- 7seg digit 0
		HEX1 : out std_logic_vector(6 downto 0), -- 7seg digit 1
		HEX2 : out std_logic_vector(6 downto 0), -- 7seg digit 2
		HEX3 : out std_logic_vector(6 downto 0), -- 7seg digit 3

		LEDG : out std_logic_vector(7 downto 0), -- Green LEDs
		LEDG : out std_logic_vector(7 downto 0), -- Red LEDs

		UART_TXD : out std_logic, -- UART Transmitter
		UART_RXD : out std_logic, -- UART Receiver

		DRAM_DQ	: inout std_logic_vector(15 downto 0),	-- Bidirectional SDRAM data
		DRAM_ADDR	: out std_logic_vector(11 downto 0), -- SDRAM address
		DRAM_LDQM	: out std_logic, -- SDRAM Low-byte Data Mask 
		DRAM_UDQM	: out std_logic, -- SDRAM High-byte Data Mask
		DRAM_WE_N	: out std_logic, -- SDRAM Write Enable
		DRAM_CAS_N	: out std_logic, -- SDRAM Column Address Strobe
		DRAM_RAS_N	: out std_logic, -- SDRAM Row Address Strobe
		DRAM_CS_N	: out std_logic, -- SDRAM Chip Select
		DRAM_BA_0	: out std_logic, -- SDRAM Bank Address 0
		DRAM_BA_1	: out std_logic, -- SDRAM Bank Address 0
		DRAM_CLK	: out std_logic, -- SDRAM Clock
		DRAM_CKE	: out std_logic, -- SDRAM Clock Enable

		FL_DQ,							//	FLASH Data bus 8 Bits
		FL_ADDR,						//	FLASH Address bus 22 Bits
		FL_WE_N,						//	FLASH Write Enable
		FL_RST_N,						//	FLASH Reset
		FL_OE_N,						//	FLASH Output Enable
		FL_CE_N,						//	FLASH Chip Enable
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		////////////////////	USB JTAG link	////////////////////
		TDI,  							// CPLD -> FPGA (data in)
		TCK,  							// CPLD -> FPGA (clk)
		TCS,  							// CPLD -> FPGA (CS)
	    TDO,  							// FPGA -> CPLD (data out)
		////////////////////	I2C		////////////////////////////
		I2C_SDAT,						//	I2C Data
		I2C_SCLK,						//	I2C Clock
		////////////////////	PS2		////////////////////////////
		PS2_DAT,						//	PS2 Data
		PS2_CLK,						//	PS2 Clock
		////////////////////	VGA		////////////////////////////
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_R,   						//	VGA Red[3:0]
		VGA_G,	 						//	VGA Green[3:0]
		VGA_B,  						//	VGA Blue[3:0]
		////////////////	Audio CODEC		////////////////////////
		AUD_ADCLRCK,					//	Audio CODEC ADC LR Clock
		AUD_ADCDAT,						//	Audio CODEC ADC Data
		AUD_DACLRCK,					//	Audio CODEC DAC LR Clock
		AUD_DACDAT,						//	Audio CODEC DAC Data
		AUD_BCLK,						//	Audio CODEC Bit-Stream Clock
		AUD_XCK,						//	Audio CODEC Chip Clock
		////////////////////	GPIO	////////////////////////////
		GPIO_0,							//	GPIO Connection 0
		GPIO_1							//	GPIO Connection 1
	);

output			UART_TXD;				//	UART Transmitter
input			UART_RXD;				//	UART Receiver
///////////////////////		SDRAM Interface	////////////////////////
inout	[15:0]	DRAM_DQ;				//	SDRAM Data bus 16 Bits
output	[11:0]	DRAM_ADDR;				//	SDRAM Address bus 12 Bits
output			DRAM_LDQM;				//	SDRAM Low-byte Data Mask 
output			DRAM_UDQM;				//	SDRAM High-byte Data Mask
output			DRAM_WE_N;				//	SDRAM Write Enable
output			DRAM_CAS_N;				//	SDRAM Column Address Strobe
output			DRAM_RAS_N;				//	SDRAM Row Address Strobe
output			DRAM_CS_N;				//	SDRAM Chip Select
output			DRAM_BA_0;				//	SDRAM Bank Address 0
output			DRAM_BA_1;				//	SDRAM Bank Address 0
output			DRAM_CLK;				//	SDRAM Clock
output			DRAM_CKE;				//	SDRAM Clock Enable
////////////////////////	Flash Interface	////////////////////////
inout	[7:0]	FL_DQ;					//	FLASH Data bus 8 Bits
output	[21:0]	FL_ADDR;				//	FLASH Address bus 22 Bits
output			FL_WE_N;				//	FLASH Write Enable
output			FL_RST_N;				//	FLASH Reset
output			FL_OE_N;				//	FLASH Output Enable
output			FL_CE_N;				//	FLASH Chip Enable
////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable
////////////////////	SD Card Interface	////////////////////////
inout			SD_DAT;					//	SD Card Data
inout			SD_DAT3;				//	SD Card Data 3
inout			SD_CMD;					//	SD Card Command Signal
output			SD_CLK;					//	SD Card Clock
////////////////////////	I2C		////////////////////////////////
inout			I2C_SDAT;				//	I2C Data
output			I2C_SCLK;				//	I2C Clock
////////////////////////	PS2		////////////////////////////////
input		 	PS2_DAT;				//	PS2 Data
input			PS2_CLK;				//	PS2 Clock
////////////////////	USB JTAG link	////////////////////////////
input  			TDI;					// CPLD -> FPGA (data in)
input  			TCK;					// CPLD -> FPGA (clk)
input  			TCS;					// CPLD -> FPGA (CS)
output 			TDO;					// FPGA -> CPLD (data out)
////////////////////////	VGA			////////////////////////////
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output	[3:0]	VGA_R;   				//	VGA Red[3:0]
output	[3:0]	VGA_G;	 				//	VGA Green[3:0]
output	[3:0]	VGA_B;   				//	VGA Blue[3:0]
////////////////////	Audio CODEC		////////////////////////////
output			AUD_ADCLRCK;			//	Audio CODEC ADC LR Clock
input			AUD_ADCDAT;				//	Audio CODEC ADC Data
output			AUD_DACLRCK;			//	Audio CODEC DAC LR Clock
output			AUD_DACDAT;				//	Audio CODEC DAC Data
inout			AUD_BCLK;				//	Audio CODEC Bit-Stream Clock
output			AUD_XCK;				//	Audio CODEC Chip Clock
////////////////////////	GPIO	////////////////////////////////
inout	[35:0]	GPIO_0;					//	GPIO Connection 0
inout	[35:0]	GPIO_1;					//	GPIO Connection 1
////////////////////////////////////////////////////////////////////

//	All inout port turn to tri-state
assign	DRAM_DQ		=	16'hzzzz;
assign	FL_DQ		=	8'hzz;
assign	SRAM_DQ		=	16'hzzzz;
assign	SD_DAT		=	1'bz;
assign	I2C_SDAT	=	1'bz;
assign	GPIO_0		=	36'hzzzzzzzzz;
assign	GPIO_1		=	36'hzzzzzzzzz;
//	Audio

wire	[15:0]	mSEG7_DIG;
reg		[27:0]	Cont;
reg		[9:0]	mLEDR;
reg				ST;

always@(posedge CLOCK_50)		Cont	<=	Cont+1'b1;

// assign	mSEG7_DIG	=	{	Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24]	};

SEG7_LUT_4 			u0	(	HEX0,HEX1,HEX2,HEX3,mSEG7_DIG );

TG68Test myTG68Test
(	
	.clk(CLOCK_50),
//	.clk50(CLOCK_50),
	.src({SW[9:5],SW[5],SW[5],SW[4],SW[4],SW[4],SW[3],SW[3],SW[3:0]}),
	.reset_in(KEY[0]),
	.counter(mSEG7_DIG),
	
	// video
	.vga_hsync(VGA_HS),
	.vga_vsync(VGA_VS),
	.vga_red(VGA_R),
	.vga_green(VGA_G),
	.vga_blue(VGA_B),
	
	// sdram
	.sdr_data(DRAM_DQ),
	.sdr_addr(DRAM_ADDR),
	.sdr_dqm({DRAM_UDQM,DRAM_LDQM}),
	.sdr_we(DRAM_WE_N),
	.sdr_cas(DRAM_CAS_N),
	.sdr_ras(DRAM_RAS_N),
	.sdr_cs(DRAM_CS_N),
	.sdr_ba({DRAM_BA_1,DRAM_BA_0}),
	.sdr_clk(DRAM_CLK),
	.sdr_clkena(DRAM_CKE)
);

endmodule
