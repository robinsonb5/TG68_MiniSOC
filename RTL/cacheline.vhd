library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- TODO:	prefetching variant
-- 		Multiple ports

entity cacheline is
	port(
		clk : in std_logic;
		reset : in std_logic;
		addr : in std_logic_vector(23 downto 0);
		hit : out std_logic;	-- Needed?  Indicates a cache hit, but not necessarily data valid.
		data_in : in std_logic_vector(15 downto 0);	
		data_out : out std_logic_vector(15 downto 0);
		dtack	: out std_logic;	-- Goes low to indicate valid data on data_out
		fill : in std_logic; -- High when data is being written from SDRAM controller
		req : out std_logic -- Request service from SDRAM controller
	);
end entity;

architecture rtl of cacheline is

type addresscache is array(0 to 3) of std_logic_vector(23 downto 3); -- round to nearest cacheline, hence downto 3
signal cacheaddr : addresscache;

--signal cachedata : std_logic_vector(63 downto 0);
signal delay : std_logic_vector(3 downto 0);
signal rdline : std_logic_vector(5 downto 0) := "000000";	-- cacheline
signal wrline : std_logic_vector(1 downto 0) := "00";	-- cacheline
signal wrlsb : std_logic_vector(1 downto 0);


begin

myM4K : entity work.DualPortM4k
	port map
	(
		clock => clk,
		rdaddress => rdline & addr(2 downto 1),
		wraddress => "0000" & wrline & wrlsb(1 downto 0),
		data => "00" & data_in,
		wren => fill,
		q(15 downto 0) => data_out
	);

	process(clk)
	begin
		if reset='0' then
			cacheaddr(0)<=X"fffff"&'1';
			cacheaddr(1)<=X"fffff"&'1';
			cacheaddr(2)<=X"fffff"&'1';
			cacheaddr(3)<=X"fffff"&'1';
			req<='0';
			wrlsb<="00";
			rdline<="000000";
			wrline<="00";
		elsif rising_edge(clk) then

			dtack <='1';
			hit <='0';

			-- Handle propogation of the DTACK signal
			if delay(2)='1' then	-- Assert dtack 3 cycles late.
				dtack<='0';
			else
				delay<=delay(2 downto 0) & '0';
			end if;

			if fill='1' then	-- Are we currently receiving data from SDRAM?	
				wrlsb(1 downto 0)<=(wrlsb(1) xor wrlsb(0)) & (not wrlsb(0));  -- +1
				if wrlsb(1 downto 0)="10" then -- 1 cycle early.
					req<='0';
				end if;
				if wrlsb(1 downto 0)="11" then
						wrline<=std_logic_vector(unsigned(wrline)+1); -- increment cacheline pointer
				end if;
			else -- Request ending?  If so, can shortly assert DTACK.
				if delay="0000" then
					delay<="0001";
				end if;
			end if;
			
			-- We match omitting the lower 3 bits of the address, 
			if cacheaddr(0)(23 downto 3) = addr(23 downto 3) then
				rdline<="000000";
				hit<='1';
			elsif cacheaddr(1)(23 downto 3) = addr(23 downto 3) then
				rdline<="000001";
				hit<='1';
			elsif cacheaddr(2)(23 downto 3) = addr(23 downto 3) then
				rdline<="000010";
				hit<='1';
			elsif cacheaddr(3)(23 downto 3) = addr(23 downto 3) then
				rdline<="000011";
				hit<='1';
			else
				-- Not in cache - store address and trigger a request...
				case wrline is
					when "00" =>
						cacheaddr(0)(23 downto 3)<=addr(23 downto 3);
					when "01" =>
						cacheaddr(1)(23 downto 3)<=addr(23 downto 3);
					when "10" =>
						cacheaddr(2)(23 downto 3)<=addr(23 downto 3);
					when "11" =>
						cacheaddr(3)(23 downto 3)<=addr(23 downto 3);
					when others =>
						null;
				end case;
				req<='1';
				delay<="0000";
			end if;
		end if;
	end process;
end architecture;
