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

--FIXME - need to signal to the SDRAM when a request is coming up, so the access slot
--to the required bank can be kept clear.

entity vgacache is
	port(
		clk : in std_logic;
		reset : in std_logic;
		reqin : in std_logic;
		addrin : in std_logic_vector(23 downto 0);
		setaddr : in std_logic;
--		newframe : in std_logic;
		addrout : buffer std_logic_vector(23 downto 0);
		data_in : in std_logic_vector(15 downto 0);	
		data_out : out std_logic_vector(15 downto 0);
		fill : in std_logic; -- High when data is being written from SDRAM controller
		req : buffer std_logic -- Request service from SDRAM controller
	);
end entity;

architecture rtl of vgacache is

signal buf1 : std_logic_vector(63 downto 0);
signal buf2 : std_logic_vector(63 downto 0);
signal buf3 : std_logic_vector(63 downto 0);
signal incounter : unsigned(1 downto 0);
signal outcounter : unsigned(1 downto 0);
signal preloadcounter : unsigned(1 downto 0);
signal bufdone : std_logic;

type cachestates is (preload, preload2, preload3, preload4, run);
signal cachestate : cachestates;

begin

	process(clk)
	begin

		if reset='0' then
			incounter<="00";
			outcounter<="00";
			cachestate<=run;
		elsif rising_edge(clk) then
			if setaddr='1' then	-- Set the framebuffer address and start preloading data...
				outcounter<="00";
				addrout<=addrin;
				cachestate<=preload;
				req<='1';
			end if;
			
			case cachestate is
				when preload =>
					if fill='1' then
						cachestate<=preload2;
					end if;
				when preload2 => 		-- Once we've received a burst, pretend the buffer has been
					if fill='0' then	-- drained, to trigger the next burst read.
						cachestate<=preload3;
						bufdone<='1';
					end if;
					
				when preload3 =>		-- once the next burst starts, we can be sure that buf2 contains
					if fill='1' then 	-- valid data, so copy it to buf1...
						buf1<=buf2;
						cachestate<=preload4;
					end if;

				when preload4 =>		-- Once again pretend the main buffer has been drained,
					if fill='0' then 	-- and we're good to go.
						bufdone<='1';
						cachestate<=run;
					end if;

				when run =>
					if reqin='1' then
						case outcounter is
							when "00" =>
								data_out<=buf1(63 downto 48);
							when "01" =>
								data_out<=buf1(47 downto 32);
							when "10" =>
								data_out<=buf1(31 downto 16);
							when "11" =>
								data_out<=buf1(15 downto 0);
								bufdone<='1';
								buf1<=buf2;
						end case;
						outcounter<=outcounter+1;
					end if;

			end case;

			if fill='1' then	-- Are we currently receiving data from SDRAM?	
				case incounter is
					when "00" =>
						addrout<=std_logic_vector(unsigned(addrout)+8);
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
			elsif bufdone='1' and req='0' then
				buf2<=buf3;
				bufdone<='0';
				req<='1';
			end if;
		end if;
	end process;
end architecture;
