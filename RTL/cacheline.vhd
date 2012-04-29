library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- TODO - prefetching variant

entity cacheline is
	port(
		clk : in std_logic;
		reset : in std_logic;
		addr : in std_logic_vector(23 downto 0);
		hit : out std_logic;	-- Needed?  Indicates a cache hit, but not necessarily data valid.
		stale : out std_logic;
		data_in : in std_logic_vector(15 downto 0);	
		data_out : out std_logic_vector(15 downto 0);
		dtack	: out std_logic;	-- Goes low to indicate valid data on data_out
		fill : in std_logic; -- High when data is being written from SDRAM controller
		req : out std_logic -- Request service from SDRAM controller
	);
end entity;

architecture rtl of cacheline is
constant keepcycles : unsigned(4 downto 0) := "11111";
signal cacheaddr : std_logic_vector(23 downto 0);
signal cachedata : std_logic_vector(63 downto 0);
signal valid : std_logic_vector(3 downto 0);
signal stalectr: unsigned(4 downto 0);

begin

	process(clk)
	begin
		if reset='0' then
			valid<="0000";
			cacheaddr<=X"ffffff";
		elsif rising_edge(clk) then

			-- We use the "stale" signal to indicate that the data in the cache
			-- hasn't been used for a few cycles, so this cacheline is ripe for replacement.
			stale <='1';
			dtack <='1';
			hit <='0';

			if stalectr/="00000" then
				stalectr<=stalectr-1;
				stale<='0';
			end if;

			-- We match omitting the lower 3 bits of the address, 
			if cacheaddr(23 downto 3) = addr(23 downto 3) then
				stalectr<=keepcycles;
				hit<='1';

				if fill='1' then	-- Are we currently receiving data from SDRAM?	
					-- Fill the cacheline
					case cacheaddr(2 downto 1) is
						when "00" =>
							cachedata(63 downto 48)<=data_in;
							valid(3)<='1';
							cacheaddr(2 downto 1)<="01";
						when "01" =>
							cachedata(47 downto 32)<=data_in;
							valid(2)<='1';
							cacheaddr(2 downto 1)<="10";
						when "10" =>
							cachedata(31 downto 16)<=data_in;
							valid(1)<='1';
							cacheaddr(2 downto 1)<="11";
						when "11" =>
							cachedata(15 downto 0)<=data_in;
							valid(0)<='1';
							cacheaddr(2 downto 1)<="00";
							req<='0';
						when others =>
							null;
					end case;
				else
					cacheaddr(2 downto 1)<="00";
				end if;

				-- Have we received the word we're waiting for?
--				if fill='1' and cacheaddr(2 downto 1) = addr(2 downto 1) then
--					data_out<=data_in;
--					dtack<='0';
--				else
					-- Addresses match  - is the cached data valid?
					case addr(2 downto 1) is
						when "00" =>
							if valid(3)='1' then
								data_out<=cachedata(63 downto 48);
								dtack<='0';
							end if;
						when "01" =>
							if valid(2)='1' then
								data_out<=cachedata(47 downto 32);
								dtack<='0';
							end if;
						when "10" =>
							if valid(1)='1' then
								data_out<=cachedata(31 downto 16);
								dtack<='0';
							end if;
						when "11" =>
							if valid(0)='1' then
								data_out<=cachedata(15 downto 0);
								dtack<='0';
							end if;
					end case;
--				end if;
			else
				-- Not in cache - store address and trigger a request...
				cacheaddr(23 downto 3)<=addr(23 downto 3);
				req<='1';
				valid<="0000";
			end if;
		end if;
	end process;
end architecture;
