library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- Theory of operation

--Need a VGA cache that will keep up with 1 word per 4-cycles.
--The SDRAM controller runs on a 16-cycle phase, and shifts 4 words per burst, so
--we will saturate one port of the SDRAM controller
--The other port can perform operations when the bank is not equal to either
--the current or next bank used by the VGA cache.
--To this end we will hardcode a framebuffer pointer, and have a "new frame" signal which will
--reset this hardcoded pointer.
--
--We will have three buffers, each 4 words in size; the first is the current data, which will be clocked out
--one word at a time.
--
--Need a req signal which will be activated at the start of each pixel.
--case counter is
--	when "00" =>
--		vgadata<=buf1(63 downto 48);
--	when "01" =>
--		vgadata<=buf1(47 downto 32);
--	when "02" =>
--		vgadata<=buf1(31 downto 16);
--	when "02" =>
--		vgadata<=buf1(15 downto 0);
--		buf1<=buf2;
--		fetchptr<=fetchptr+4;
--		sdr_req<='1';
--end case;
--
--Alternatively, could use a multiplier to shift the data - might use fewer LEs?
--
--In the meantime, we will constantly fetch data from SDRAM, and feed it into buf3.
--As soon as buf3 is filled, we move the contents into buf2, and drop the req signal.
--		

-- TODO:	prefetching variant
-- 		Multiple ports
--       Release DTACK quicker
--       Respond to address change quicker (or drop DTACK for 1 cycle.)

-- FIXME - need to take care of refresh cycle timing.  Make it coincide with HSync.

entity vgacache is
	port(
		clk : in std_logic;
		reset : in std_logic;
		reqin : in std_logic;
		newframe : in std_logic;
		addrout : buffer std_logic_vector(23 downto 0);
		data_in : in std_logic_vector(15 downto 0);	
		data_out : out std_logic_vector(15 downto 0);
		fill : in std_logic; -- High when data is being written from SDRAM controller
		req : out std_logic -- Request service from SDRAM controller
	);
end entity;

architecture rtl of vgacache is

signal buf1 : std_logic_vector(63 downto 0);
signal buf2 : std_logic_vector(63 downto 0);
signal buf3 : std_logic_vector(63 downto 0);
signal incounter : unsigned(1 downto 0);
signal outcounter : unsigned(1 downto 0);

begin

	process(clk)
	begin

		if reset='0' then
			incounter<="00";
			outcounter<="00";
		elsif rising_edge(clk) then
			if newframe='1' then
				outcounter<="00";
				addrout<=X"100000";
			elsif reqin='1' then
				case outcounter is
					when "00" =>
						data_out<=buf1(63 downto 48);
					when "01" =>
						data_out<=buf1(47 downto 32);
					when "10" =>
						data_out<=buf1(31 downto 16);
					when "11" =>
						data_out<=buf1(15 downto 0);
						buf1<=buf2;
						addrout<=std_logic_vector(unsigned(addrout)+4);
						req<='1';
				end case;
				outcounter<=outcounter+1;
			end if;

			if fill='1' then	-- Are we currently receiving data from SDRAM?	
				case incounter is
					when "00" =>
						req<='0';
						buf3(63 downto 48)<=data_in;
					when "01" =>
						buf3(47 downto 32)<=data_in;
					when "10" =>
						buf3(31 downto 16)<=data_in;
					when "11" =>
						buf3(15 downto 0)<=data_in;
				end case;
				incounter<=incounter+1;
			else
				buf2<=buf3;
			end if;
		end if;
	end process;
end architecture;
