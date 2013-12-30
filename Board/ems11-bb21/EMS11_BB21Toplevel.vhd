-- Toplevel file for EMS11-BB21 board

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity EMS11_BB21Toplevel is
port
(
		-- Housekeeping
	CLK50 : in std_logic;

		-- UART
	TXD1_TO_FPGA : in std_logic;
	RXD1_FROM_FPGA : out std_logic;
	N_RTS1_TO_FPGA : in std_logic;
	N_CTS1_FROM_FPGA : out std_logic;
	
		-- SDRAM
	DR_CAS : out std_logic;
	DR_CS : out std_logic;
	DR_RAS : out std_logic;
	DR_WE	: out std_logic;
	DR_CLK_I : in std_logic;
	DR_CLK_O : out std_logic;
	DR_CKE : out std_logic;
	DR_A : out std_logic_vector(12 downto 0);
	DR_D : inout std_logic_vector(15 downto 0);
	DR_DQMH : out std_logic;
	DR_DQML : out std_logic;
	DR_BA : out std_logic_vector(1 downto 0)
);
end entity;


architecture rtl of EMS11_BB21Toplevel is

signal sdram_clk : std_logic;
signal sdram_clk_inv : std_logic;
signal sysclk : std_logic;
signal clklocked : std_logic;

begin
N_CTS1_FROM_FPGA<='1';  -- safe default since we're not using handshaking.

DR_CLK_O<='1';

-- Clock generation.  We need a system clock and an SDRAM clock.
-- Limitations of the Spartan 6 mean we need to "forward" the SDRAM clock
-- to the io pin.

--myclock : entity work.EMS11_BB21_sysclock
--port map(
--	CLK_IN1 => CLK50,
--	RESET => '0',
--	CLK_OUT1 => sysclk,
--	CLK_OUT2 => sdram_clk,
--	LOCKED => clklocked
--);
--
--sdram_clk_inv <= not sdram_clk;
--
--ODDR2_inst : ODDR2
--generic map(
--	DDR_ALIGNMENT => "NONE",
--	INIT => '0',
--	SRTYPE => "SYNC")
--port map (
--	Q => DR_CLK_O,
--	C0 => sdram_clk,
--	C1 => sdram_clk_inv,
--	CE => '1',
--	D0 => '0',
--	D1 => '1',
--	R => '0',    -- 1-bit reset input
--	S => '0'     -- 1-bit set input
--);


project: entity work.VirtualToplevel
	generic map (
		sdram_rows => 13,
		sdram_cols => 10,
		sysclk_frequency => 500 -- Sysclk frequency * 10
	)
	port map (
		clk => CLK50,
		reset_in => '1',
	
		-- SDRAM
		sdr_data => DR_D,
		sdr_addr => DR_A,
		sdr_dqm(1) => DR_DQMH,
		sdr_dqm(0) => DR_DQML,
		sdr_we => DR_WE,
		sdr_cas => DR_CAS,
		sdr_ras => DR_RAS,
		sdr_cs => DR_CS,
		sdr_ba => DR_BA,
		sdr_cke => DR_CKE,

		-- UART
		rxd => TXD1_TO_FPGA,
		txd => RXD1_FROM_FPGA
);

end architecture;
