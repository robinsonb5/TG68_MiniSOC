library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity TG68Test is
	port (
		clk50 			: in std_logic;
--		clk50			: in std_logic;
		src 			: in std_logic_vector(15 downto 0);
		counter 		: buffer unsigned(15 downto 0);
		reset_in 	: in std_logic;
		pausecpu		: in std_logic;
		pausevga		: in std_logic;
		buttons		: in std_logic_vector(2 downto 0);
		
		-- VGA
		vga_red 		: out unsigned(3 downto 0);
		vga_green 	: out unsigned(3 downto 0);
		vga_blue 	: out unsigned(3 downto 0);
		vga_hsync 	: out std_logic;
		vga_vsync 	: buffer std_logic;
		
		-- SDRAM
		sdr_data		: inout std_logic_vector(15 downto 0);
		sdr_addr		: out std_logic_vector(11 downto 0);
		sdr_dqm 		: out std_logic_vector(1 downto 0);
		sdr_we 		: out std_logic;
		sdr_cas 		: out std_logic;
		sdr_ras 		: out std_logic;
		sdr_cs		: out std_logic;
		sdr_ba		: out std_logic_vector(1 downto 0);
		sdr_clk		: out std_logic;
		sdr_clkena	: out std_logic
	);
end entity;

architecture rtl of TG68Test is
signal cpu_datain : std_logic_vector(15 downto 0);	-- Data provided by us to CPU
signal cpu_dataout : std_logic_vector(15 downto 0); -- Data received from the CPU
signal cpu_addr : std_logic_vector(31 downto 0); -- CPU's current address
signal cpu_as : std_logic; -- Address strobe
signal cpu_uds : std_logic; -- upper data strobe
signal cpu_lds : std_logic; -- lower data strobe
signal cpu_r_w : std_logic; -- read(high)/write(low)
signal busstate : std_logic_vector(1 downto 0);
signal cpu_clkena : std_logic :='0';

-- VGA
signal currentX : unsigned(11 downto 0);
signal currentY : unsigned(11 downto 0);
signal wred : unsigned(7 downto 0);
signal wgreen : unsigned(7 downto 0);
signal wblue : unsigned(7 downto 0);
signal end_of_pixel : std_logic;
signal refresh :std_logic;
signal end_of_frame :std_logic;
signal vga_data : std_logic_vector(15 downto 0);
signal chargen_pixel : std_logic;
signal chargen_window : std_logic;

--
signal reset : std_logic := '0';
signal reset_counter : unsigned(15 downto 0) := X"FFFF";
signal tg68_ready : std_logic;
signal sdr_ready : std_logic;
signal ready : std_logic;
signal write_address : std_logic_vector(23 downto 0);
signal req_pending : std_logic :='0';
--signal write_pending : std_logic :='0';
signal dtack1 : std_logic;
signal clk100 : std_logic;

signal vga_addr : std_logic_vector(23 downto 0);
signal vga_req : std_logic;
signal vga_fill : std_logic;
signal vga_refresh : std_logic;
signal vga_newframe : std_logic;
signal vga_reservebank : std_logic; -- Keep bank clear for instant access.
signal vga_reserveaddr : std_logic_vector(23 downto 0); -- to SDRAM

signal vga_reg_addr : std_logic_vector(11 downto 0);
signal vga_reg_dataout : std_logic_vector(15 downto 0);
signal vga_reg_datain : std_logic_vector(15 downto 0);
signal vga_reg_rw : std_logic;

signal vblank_int : std_logic;
signal int_ack : std_logic;
signal ints : std_logic_vector(2 downto 0);

signal romdata : std_logic_vector(15 downto 0);
signal ramdata : std_logic_vector(15 downto 0);

signal framectr : unsigned(15 downto 0);
signal resetctr : std_logic;

type prgstates is (run,mem,rom,waitread,waitwrite,wait1,wait2,waitvga,hardware);
signal prgstate : prgstates :=wait2;
begin

sdr_clkena <='1';
--sdr_clk <=clk100;

mypll : ENTITY work.PLL
	port map
	(
		inclk0 => clk50,
		c0 => sdr_clk,
		c1 => clk100,
		locked => open
	);


process(clk100)
begin
	ready <= tg68_ready and sdr_ready and reset;

	if reset_in='0' then
		reset_counter<=X"FFFF";
		reset<='0';
	elsif rising_edge(clk100) then
		reset_counter<=reset_counter-1;
		if reset_counter=X"0000" then
			reset<='1' and sdr_ready;
		end if;
	end if;
end process;


--vga_red<=wred(7 downto 4);
--vga_green<=wgreen(7 downto 4);
--vga_blue<=wblue(7 downto 4);

myint : entity work.interrupt_controller
	port map(
		clk => clk100,
		reset => reset,
		int7 => not buttons(2),
		int1 => vblank_int,
		int2 => not buttons(1),
		int3 => not buttons(0),
		int4 => '0',
		int5 => '0',
		int6 => '0',
		int_out => ints,
		ack => int_ack
	);


myTG68 : entity work.TG68KdotC_Kernel
	generic map
	(
		MUL_Mode => 1
	)
   port map
	(
		clk => clk100,
      nReset => reset,
      clkena_in => cpu_clkena and pausecpu,
      data_in => cpu_datain,
		IPL => ints,
		IPL_autovector => '0',
		CPU => "00",
		addr => cpu_addr,
		data_write => cpu_dataout,
		nWr => cpu_r_w,
		nUDS => cpu_uds,
		nLDS => cpu_lds,
		busstate => busstate,
		nResetOut => tg68_ready,
		FC => open,
-- for debug		
		skipFetch => open,
		regin => open
	);


mybootrom : entity work.BootRom
	port map (
		clock => clk100,
		address => cpu_addr(9 downto 1),
		q => romdata
		);


-- Make use of boot rom
process(clk100,cpu_addr)
begin
	if reset_in='0' then
		prgstate<=wait2;
		req_pending<='0';
	elsif rising_edge(clk100) then
		int_ack<='0';
		vga_reg_rw<='1';
		case prgstate is
			when run =>
				cpu_clkena<='0';
				prgstate<=mem;
			when mem =>
				if busstate="01" then
					prgstate<=wait2;
				else
					case cpu_addr(31 downto 16) is
						when X"FFFF" => -- Interrupt acknowledge cycle
							-- CPU address bits 3 downto 1 contain the int number,
							-- we respond with that number.  (Could just use autovectoring, of course.)
							cpu_datain <= "0000000000000" & cpu_addr(3 downto 1);
							int_ack<='1';
							prgstate<=wait1;
						when X"0080" => -- hardware registers
							vga_reg_addr<=cpu_addr(11 downto 0);
							vga_reg_rw<=cpu_r_w;
							vga_reg_datain<=cpu_dataout;
							prgstate<=hardware;
						when X"0000" => -- ROM access
							cpu_datain<=romdata;
							prgstate<=rom;
						when others =>
							counter<=unsigned(cpu_dataout); -- Remove this...
--							write_address<=cpu_addr(23 downto 0);
							req_pending<='1';
							if cpu_r_w='0' then
								prgstate<=waitwrite;
							else	-- SDRAM read
								prgstate<=waitread;
							end if;
					end case;
				end if;
			when waitread =>
				if dtack1='0' then
					cpu_datain<=ramdata;
					req_pending<='0';
					cpu_clkena<='1';
					prgstate<=run;
				end if;
			when waitwrite =>
				if dtack1='0' then
					req_pending<='0';
					cpu_clkena<='1';
					prgstate<=run;
				end if;
			when rom =>
				cpu_datain<=romdata;
				prgstate<=wait2;
			when hardware =>
				cpu_datain<=vga_reg_dataout;
				prgstate<=wait2;
			when wait1 =>
				prgstate<=wait2;
			when wait2 =>
				if (ready or not tg68_ready)='1' then
					cpu_clkena<='1';
					prgstate<=run;
				end if;
			when others =>
				null;
		end case;
--		elsif busstate/="01" then	-- Does this cycle involve mem access if so, wait?
--			cpu_clkena<='0';
--		end if;
--		cpu_clkena<=(not cpu_clkena) and (ready or not tg68_ready);	-- Don't let TG68 start until the SDRAM is ready
	end if;
end process;

	
-- SDRAM
mysdram : entity work.sdram 
	port map
	(
	-- Physical connections to the SDRAM
		sdata => sdr_data,
		sdaddr => sdr_addr,
		sd_we	=> sdr_we,
		sd_ras => sdr_ras,
		sd_cas => sdr_cas,
		sd_cs	=> sdr_cs,
		dqm => sdr_dqm,
		ba	=> sdr_ba,

	-- Housekeeping
		sysclk => clk100,
		reset => reset_in,
		reset_out => sdr_ready,

		vga_addr => vga_addr,
		vga_data => vga_data,
		vga_fill => vga_fill,
		vga_req => vga_req,
		vga_refresh => vga_refresh,
		vga_reservebank => vga_reservebank,
		vga_reserveaddr => vga_reserveaddr,

		vga_newframe => vga_newframe,

		datawr1 => std_logic_vector(counter),
		Addr1 => cpu_addr(23 downto 0),
		req1 => req_pending,
		wr1 => cpu_r_w,
		wrL1 => '0', -- Always access full words for now...
		wrU1 => '0', 
		dataout1 => ramdata,
		dtack1 => dtack1
	);

	myvga : entity work.vga_controller
		port map (
		clk => clk100,
		reset => reset,

		reg_addr_in => vga_reg_addr,
		reg_data_in => vga_reg_datain,
		reg_data_out => vga_reg_dataout,
		reg_rw => vga_reg_rw,
		reg_uds => cpu_uds,
		reg_lds => cpu_lds,

		sdr_addrout => vga_addr,
		sdr_datain => vga_data, 
		sdr_fill => vga_fill,
		sdr_req => vga_req,
		sdr_reservebank => vga_reservebank,
		sdr_reserveaddr => vga_reserveaddr,
		sdr_refresh => vga_refresh,

		hsync => vga_hsync,
		vsync => vga_vsync,
		vblank_int => vblank_int,
		red => vga_red,
		green => vga_green,
		blue => vga_blue
	);

end architecture;
