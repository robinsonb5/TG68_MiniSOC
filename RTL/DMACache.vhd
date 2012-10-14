library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity DMACache is
	port(
		clk : in std_logic;
		reset_n : in std_logic;
		-- DMA channel address strobes
		addr_in : in std_logic_vector(31 downto 0);
		setaddr_vga : in std_logic;
		setaddr_sprite0 : in std_logic;
		setaddr_audio0 : in std_logic;
		setaddr_audio1 : in std_logic;

		req_length : unsigned(11 downto 0);
		setreqlen_vga : in std_logic;
		setreqlen_sprite0 : in std_logic;
		setreqlen_audio0 : in std_logic;
		setreqlen_audio1 : in std_logic;

		-- Read requests
		req_vga : in std_logic;
		req_sprite0 : in std_logic;
		req_audio0 : in std_logic;
		req_audio1 : in std_logic;

		-- DMA channel output and valid flags.
		data_out : out std_logic_vector(15 downto 0);
		valid_vga : out std_logic;
		valid_sprite0 : out std_logic;
		valid_audio0 : out std_logic;
		valid_audio1 : out std_logic;
		
		-- SDRAM interface
		sdram_addr : out std_logic_vector(31 downto 0);
		sdram_reserveaddr : out std_logic_vector(31 downto 0);
		sdram_reserve : out std_logic;
		sdram_req : out std_logic;
		sdram_ack : in std_logic; -- Set when the request has been acknowledged.
		sdram_fill : in std_logic;
		sdram_data : in std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of dmacache is


type inputstate_t is (rd1,rcv1,rcv2,rcv3,rcv4);
signal inputstate : inputstate_t := rd1;

type updatestate_t is (vga,spr0,aud0,aud1);
signal updatestate : updatestate_t := vga;

constant vga_base : std_logic_vector(2 downto 0) := "000";
constant spr0_base : std_logic_vector(2 downto 0) := "001";
constant spr1_base : std_logic_vector(2 downto 0) := "010";
constant audio0_base : std_logic_vector(2 downto 0) := "011";

-- DMA channel state information

signal vga_writeptr : unsigned(5 downto 0);
signal vga_rdptr : unsigned(5 downto 0);
signal vgaaddr : std_logic_vector(31 downto 0);
signal vgacount : unsigned(11 downto 0);

signal spr0_writeptr : unsigned(5 downto 0);
signal spr0_rdptr : unsigned(5 downto 0);
signal spr0addr : std_logic_vector(31 downto 0);
signal spr0count : unsigned(11 downto 0);

-- interface to the blockram

signal cache_writeaddr : std_logic_vector(7 downto 0);
signal cache_rdaddr : std_logic_vector(7 downto 0);
signal cache_wren : std_logic;

begin

myDMACacheRAM : entity work.DMACacheRAM
	port map
	(
		clock => clk,
		data => sdram_data,
		rdaddress => cache_rdaddr,
		wraddress => cache_wraddr,
		wren => cache_wren,
		q => data_out
	);

-- Employ bank reserve for SDRAM.
sdram_reserve<='1' when vgacount/=X"000" else '0';

process(clk)
begin
	if rising_edge(clk) then
		if reset='1' then
			inputstate<=rd1;
			vgacount<=X"000";
			spr0count<=X"000";
			vga_rdptr<=(others => '0');
			vga_wrptr<=(others => '0');
			vga_wrptr_next<="01000";
		end if;

		if sdram_ack='1' then
			sdram_reserveaddr<=vga_addr+8;
		end if;

		-- Request and receive data from SDRAM:
		case inputstate is
			-- First state: Read.  Check the channels in priority order.
			-- VGA has absolutel priority, and the others won't do anything until the VGA buffer is
			-- full.
			when rd1 =>
				if vga_rdptr(5 downto 2)/=vga_writeptr_next(5 downto 2) and vgacount/=X"000" then
					cache_writeaddr<=vga_base&vga_writeptr;
					sdram_req<='1';
					sdram_addr<=vga_reqaddr;
					vga_reqaddr<=vga_reqaddr+8;
					inputstate<=rcv1;
					update<=vga;
				end if;
				-- FIXME - other channels here
			-- Wait for SDRAM, fill first word.
			when rcv1 =>
				if sdram_fill='1' then
					data<=sdram_data;
					wren<='1';
					inputstate<=rcv2;
					writeptr<=writeptr+1;
				end if;
			when rcv2 =>
				data<=sdram_data;
				cache_wren<='1';
				writeptr<=writeptr+1;
				inputstate<=rcv3;
			when rcv3 =>
				data<=sdram_data;
				cache_wren<='1';
				writeptr<=writeptr+1;
				inputstate<=rcv4;
			when rcv4 =>
				data<=sdram_data;
				cace_wren<='1';
				writeptr<=writeptr+1;
				inputstate<=rd1;
				case update is
					when vga =>
						vga_writeptr<=vga_writeptr+4;
						vga_writeptr_next<=vga_writeptr_next+4;
				-- FIXME - other channels here
					when others =>
						null;
				end case;
			when others =>
				null;
		end case;
	end if;
end process;


process(clk)
begin
	if rising_edge(clk) then
	-- Handle timeslicing of output registers
	-- We prioritise simply by testing in order of priority.
	-- req signals should always be a single pulse; need to latch all but VGA, since it may be several
	-- cycles since they're serviced.

		if spr0_req='1' then
			spr0_pending<='1';
		end if;
		if audio0_req='1' then
			audio0_pending<='1';
		end if;


		if vga_req='1' then -- and vga_rdptr/=vga_wrptr then -- This test should never fail.
			rdaddress<=vga_rdptr;
			vga_rdptr<=vga_rdptr+1;
			vga_ack<='1';
		elsif spr0_pending='1' and spr0_rdptr/=spr0_wrptr then
			rdaddress<=spr0_rdptr;
			spr0_rdptr<=spr0_rdptr+1;
			spr0_ack<='1';
			spr0_pending<='0';
		elsif aud0_pending='1' and aud0_rdptr/=aud0_wrptr then
			rdaddress<=aud0_rdptr;
			aud0_rdptr<=aud0_rdptr+1;
			aud0_ack<='1';
			aud0_pending<='0';
		end if;
	end if;
end process;
		
end rtl;

