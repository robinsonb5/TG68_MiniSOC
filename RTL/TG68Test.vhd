library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity TG68Test is
	port (
		clk 			: in std_logic;
--		clk50			: in std_logic;
		src 			: in std_logic_vector(15 downto 0);
		counter 		: buffer unsigned(15 downto 0);
		reset_in 	: in std_logic;
		
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
signal end_of_line :std_logic;
signal end_of_frame :std_logic;
signal vga_data : std_logic_vector(15 downto 0);

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
signal clk114 : std_logic;
signal vga_req : std_logic;
signal vga_newframe : std_logic;

signal romdata : std_logic_vector(15 downto 0);
signal ramdata : std_logic_vector(15 downto 0);

signal framectr : unsigned(15 downto 0);
signal resetctr : std_logic;

type prgstates is (run,mem,rom,waitread,waitwrite,wait1,wait2);
signal prgstate : prgstates :=wait2;
begin

sdr_clkena <='1';
sdr_clk <=clk114;

mypll : ENTITY work.PLL
	port map
	(
		inclk0 => clk,
		c0 => clk114,
		locked => open
	);


process(clk114)
begin
	ready <= tg68_ready and sdr_ready and reset;

	if reset_in='0' then
		reset_counter<=X"FFFF";
		reset<='0';
	elsif rising_edge(clk114) then
		reset_counter<=reset_counter-1;
		if reset_counter=X"0000" then
			reset<='1' and sdr_ready;
		end if;
	end if;
end process;


--vga_red<=wred(7 downto 4);
--vga_green<=wgreen(7 downto 4);
--vga_blue<=wblue(7 downto 4);


myTG68 : entity work.TG68KdotC_Kernel
	generic map
	(
		MUL_Mode => 1
	)
   port map
	(
		clk => clk114,
      nReset => reset,
      clkena_in => cpu_clkena,
      data_in => cpu_datain,
		IPL => "111",
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


-- mul Test program: 
--	move.l	#$11,d0	; $7011
--.loop
--	move.l	d0,d1	; $2200
--	mulu	#$1234,d1	; $C2FC,$1234
--	move.l	d1,$100	; $21C1,$0100
--	bra.s	.loop	; $60F4

-- Address decoding
--process(clk,cpu_addr)
--begin
--	if rising_edge(clk) then
--		if cpu_clkena='0' then
--			case cpu_addr(11 downto 0) is
--				-- We have a simple program encoded here...
--				-- (longword at 0 is initial stack pointer (0), while
--				-- longword at 4 is initial program counter, 0x00000008)
--				when X"006" =>
--					cpu_datain <= X"0008";
--				when X"008" =>
--					cpu_datain <= X"7011";  -- moveq.l #$11,d0
--				when X"00A" =>
--	--				cpu_datain <= X"4440";	-- neg.w d0,
--					cpu_datain <= X"4e71";	-- nop
--				when X"00C" =>
--					cpu_datain <= X"2200";  -- move.l d0,d1
--				when X"00E" =>
--					cpu_datain <= X"c2fc";  -- mulu ....,d1
--	--				cpu_datain <= X"c3fc";  -- muls ....,d1
--				when X"010" =>
--					cpu_datain <= src;
--				when X"012" =>
--					cpu_datain <= X"31c1";  -- move.w d1,...
--				when X"014" =>
--					cpu_datain <= X"0100";  -- $100
--				when X"016" =>
--					cpu_datain <= X"60f4";  -- bra.s .loop
--				when X"100" =>
--					counter<=unsigned(cpu_dataout);
--					cpu_datain <= X"0000";
--				when others =>
--					cpu_datain <= X"0000";
--			end case;
----			cpu_clkena<='1';
----		elsif busstate/="01" then	-- Does this cycle involve mem access if so, wait?
----			cpu_clkena<='0';
--		end if;
--		cpu_clkena<=(not cpu_clkena) and (ready or not tg68_ready);	-- Don't let TG68 start until the SDRAM is ready
--	end if;
--end process;
--

-- SDRAM test program:
-- 7000 7400 2202 41F9 0010 0000 30C1 5241 5340 66F8 5242 60EC

--process(clk114,cpu_addr)
--begin
--	if rising_edge(clk114) then
--		if write_pending='1' and dtack1='0' then
--			write_pending<='0';
--		end if;
--		case prgstate is
--			when run =>
--				cpu_clkena<='0';
--				prgstate<=mem;
--			when mem =>
--				case cpu_addr(11 downto 0) is
--					-- We have a simple program encoded here...
--					-- (longword at 0 is initial stack pointer (0), while
--					-- longword at 4 is initial program counter, 0x00000008)
--					when X"006" =>
--						cpu_datain <= X"0008";
--					when X"008" =>
--						cpu_datain <= X"7000";
--					when X"00a" =>
--						cpu_datain <= X"7400";
--					when X"00c" =>
--						cpu_datain <= X"2202";
--					when X"00e" =>
--						cpu_datain <= X"41f9";
--					when X"010" =>
--						cpu_datain <= X"0010";
--					when X"012" =>
--						cpu_datain <= X"0000";
--					when X"014" =>
--						cpu_datain <= X"30c1";
--					when X"016" =>
--						cpu_datain <= X"5241";
--					when X"018" =>
--						cpu_datain <= X"5340";
--					when X"01a" =>
--						cpu_datain <= X"66f8";
--					when X"01c" =>
--						cpu_datain <= X"5242";
----						cpu_datain <= X"60ea";
--					when X"01e" =>
--						cpu_datain <= X"60ec";
--					when others =>
--						cpu_datain <= X"0000";
--				end case;
--				if cpu_addr(20)='1' and cpu_r_w='0' then
--						counter<=unsigned(cpu_dataout);
--						write_address<=cpu_addr(23 downto 0);
--						write_pending<='1';
--				end if;
--				prgstate<=wait2;
--			when wait1 =>
--				prgstate<=wait2;
--			when wait2 =>
--				if (ready or not tg68_ready)='1' then
--					cpu_clkena<='1';
--					prgstate<=run;
--				end if;
--			when others =>
--				null;
--		end case;
----		elsif busstate/="01" then	-- Does this cycle involve mem access if so, wait?
----			cpu_clkena<='0';
----		end if;
----		cpu_clkena<=(not cpu_clkena) and (ready or not tg68_ready);	-- Don't let TG68 start until the SDRAM is ready
--	end if;
--end process;

--process(clk114)
--begin
--	if rising_edge(clk114) then
--		resetctr<='0';
--		if req_pending='1' and dtack1='0' then
--			req_pending<='0';
--		elsif req_pending='0' then
--			if unsigned(write_address(19 downto 0))>=614400 then -- 640x480x2
--				write_address<=X"100000";
--				resetctr<='1';
--			else
--				write_address<="0001" & std_logic_vector(unsigned(write_address(19 downto 0))+2);
--			end if;
--			counter<=unsigned(write_address(16 downto 1));
----			write_address<="0001000" & std_logic_vector(counter) & '0';
--			req_pending<='1';
--		end if;
--		
--		if resetctr='1' then
--			framectr<=framectr+1;
--		end if;
--	end if;
--end process;


mybootrom : entity work.BootRom
	port map (
		clock => clk114,
		address => cpu_addr(8 downto 1),
		q => romdata
		);


-- Make use of boot rom
process(clk114,cpu_addr)
begin
	if reset_in='0' then
		prgstate<=wait2;
		req_pending<='0';
	elsif rising_edge(clk114) then
		case prgstate is
			when run =>
				cpu_clkena<='0';
				prgstate<=mem;
			when mem =>
				if busstate="01" then
					prgstate<=wait2;
				elsif cpu_addr(31 downto 12) = X"00000" then -- ROM access
				-- FIXME SDRAM read needs to go here...
					cpu_datain<=romdata;
					prgstate<=rom;
				else --if cpu_r_w='0' then
					counter<=unsigned(cpu_dataout); -- Remove this...
					write_address<=cpu_addr(23 downto 0);
					req_pending<='1';
					if cpu_r_w='0' then
						prgstate<=waitwrite;
					else	-- SDRAM read
						prgstate<=waitread;		
					end if;
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
		sysclk => clk114,
		reset => reset_in,
		reset_out => sdr_ready,

		vga_newframe => vga_newframe,
		vga_req => vga_req,
		vga_data => vga_data,
		vga_refresh => end_of_line,

		datawr1 => std_logic_vector(counter),
		Addr1 => std_logic_vector(write_address),
		req1 => req_pending,
		wr1 => cpu_r_w,
		wrL1 => '0', -- Always access full words for now...
		wrU1 => '0', 
		dataout1 => ramdata,
		dtack1 => dtack1
	);


-- Video
-- -----------------------------------------------------------------------
-- VGA timing configured for 640x480
-- -----------------------------------------------------------------------
	myVgaMaster : entity work.video_vga_master
		generic map (
			clkDivBits => 4
		)
		port map (
			clk => clk114,
			-- 50 Mhz / (1+1) = 25 Mhz
			clkDiv => X"3",

			hSync => vga_hsync,
			vSync => vga_vsync,

			endOfPixel => end_of_pixel,
			endOfLine => end_of_line,
			endOfFrame => end_of_frame,
			currentX => currentX,
			currentY => currentY,

			-- Setup 640x480@60hz needs ~25 Mhz
			hSyncPol => '0',
			vSyncPol => '0',
			xSize => to_unsigned(800, 12),
			ySize => to_unsigned(525, 12),
			xSyncFr => to_unsigned(656, 12), -- Sync pulse 96
			xSyncTo => to_unsigned(752, 12),
			ySyncFr => to_unsigned(500, 12), -- Sync pulse 2
			ySyncTo => to_unsigned(502, 12)
		);
		
	-- VGADither
	vgadithering : entity work.video_vga_dither
		port map (
			pixelclock => end_of_pixel,
			X => currentX(9 downto 0),
			Y => currentY(9 downto 0),
			VSync => vga_vsync,
			enable => '1',
			iRed => wred,
			iGreen => wgreen,
			iBlue => wblue,
			oRed => vga_red,
			oGreen => vga_green,
			oBlue => vga_blue
		);


	-- -----------------------------------------------------------------------
-- VGA colors
-- -----------------------------------------------------------------------
	process(clk114, currentX, currentY)
	begin
		if rising_edge(clk114) then
			vga_req<='0';
			vga_newframe<='0';
			if currentX<640 and currentY<480 then
				if end_of_pixel='1' then
					vga_req<='1';
					wred <= unsigned(vga_data(15 downto 11) & "000");
					wgreen <= unsigned(vga_data(10 downto 5) & "00");
					wblue	<=	unsigned(vga_data(4 downto 0) & "000");
				end if;
			else
				if currentY=481 then
					if end_of_pixel='1' then -- Prefetch two cachelines
						if  currentX(0)='0' and currentX>16 and currentX<45 then
							vga_req<='1';
						end if;
						if end_of_pixel='1' and currentX=0 then
							vga_newframe<='1';
						end if;
					end if;
				end if;
				wred <= (others => '0');
				wgreen <= (others => '0');
				wblue <= (others => '0');
			end if;
		end if;
	end process;

end architecture;
