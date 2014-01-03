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
	DR_BA : out std_logic_vector(1 downto 0);
	
		-- VGA Connector
	N_CTS2_FROM_FPGA : out std_logic; -- Actually used for VGA
	M1_S : inout std_logic_vector(39 downto 0)
);
end entity;


architecture rtl of EMS11_BB21Toplevel is

signal sdram_clk : std_logic;
signal sdram_clk_inv : std_logic;
signal sysclk : std_logic;
signal clklocked : std_logic;

signal vga_red : unsigned(9 downto 0);
signal vga_green : unsigned(9 downto 0);
signal vga_blue : unsigned(9 downto 0);
signal vga_hsync : std_logic;
signal vga_vsync : std_logic;
signal vga_window : std_logic;
signal vga_clock : std_logic;
signal vga_blank : std_logic;
signal vga_sync : std_logic;
signal vga_psave : std_logic;

-- PS/2 ports
alias ps2_b_clk : std_logic is M1_S(35);
alias ps2_b_data : std_logic is M1_S(33);
alias ps2_a_clk : std_logic is M1_S(37);
alias ps2_a_data : std_logic is M1_S(39);

begin
N_CTS1_FROM_FPGA<='1';  -- safe default since we're not using handshaking.

DR_CLK_O<='1';

ps2_a_clk <='Z';
ps2_a_data <='Z';
ps2_b_clk <='Z';
ps2_b_data <='Z';

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


vga_clock <= CLK50;
vga_sync <= '0';
vga_blank <= vga_window;
vga_psave <= '1';

N_CTS2_FROM_FPGA<=vga_green(9);
M1_S(0)<=vga_green(8);
M1_S(2)<=vga_green(7);
M1_S(4)<=vga_green(6);
M1_S(6)<=vga_green(5);
M1_S(8)<=vga_green(4);
M1_S(10)<=vga_green(3);
M1_S(12)<=vga_green(2);
M1_S(14)<=vga_green(1);
M1_S(16)<=vga_green(0);

M1_S(18)<=vga_blue(4);
M1_S(20)<=vga_blue(5);
M1_S(22)<=vga_blue(6);
M1_S(24)<=vga_blue(7);
M1_S(26)<=vga_blue(8);
M1_S(28)<=vga_blue(9);

M1_S(30)<=vga_clock;
M1_S(32)<=vga_psave;
M1_S(34)<=vga_hsync;
M1_S(36)<=vga_vsync;

M1_S(1)<=vga_blue(3);
M1_S(3)<=vga_blue(2);
M1_S(5)<=vga_blue(1);
M1_S(7)<=vga_blue(0);

M1_S(9)<=vga_blank;
M1_S(11)<=vga_sync;
M1_S(13)<=vga_red(9);
M1_S(15)<=vga_red(8);
M1_S(17)<=vga_red(7);
M1_S(19)<=vga_red(6);
M1_S(21)<=vga_red(5);
M1_S(23)<=vga_red(4);
M1_S(25)<=vga_red(3);
M1_S(27)<=vga_red(2);
M1_S(29)<=vga_red(1);
M1_S(31)<=vga_red(0);
M1_S(38)<='1';

project: entity work.VirtualToplevel
	generic map (
		sdram_rows => 13,
		sdram_cols => 10,
		sysclk_frequency => 500, -- Sysclk frequency * 10
		vga_bits => 8
	)
	port map (
		clk => CLK50,
		reset_in => '1',
	
		-- VGA
		vga_red => vga_red(9 downto 2),
		vga_green => vga_green(9 downto 2),
		vga_blue => vga_blue(9 downto 2),
		vga_hsync => vga_hsync,
		vga_vsync => vga_vsync,
		vga_window => vga_window,

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
