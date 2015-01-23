library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity debounce is
	generic(
		default : std_logic :='1';
		bits : integer := 12
	);
	port(
		clk : in std_logic;
		signal_in : in std_logic;
		signal_out : out std_logic;
		posedge : out std_logic;
		negedge : out std_logic
	);
end debounce;

architecture RTL of debounce is
signal counter : unsigned(bits-1 downto 0):=to_unsigned(0,bits);
signal regin : std_logic := default;	-- Deglitched input signal
signal regin2 : std_logic := default;	-- Deglitched input signal
signal debtemp : std_logic := default;
signal prev : std_logic := default;
begin

	process(clk)
	begin
		if rising_edge(clk) then
			posedge<='0';
			negedge<='0';
			regin2<=signal_in;
			regin <= regin2;
			
			if debtemp/=regin then
				counter<=(others=>'1');
				debtemp<=regin;
			else
				if counter(counter'high downto 1)=(counter'high downto 1 => '0') then
					if counter(0)='1' then
						if prev/=regin then
							posedge<=regin;
							negedge<=not regin;
							prev<=regin;
						end if;
						counter<=counter-1;
					end if;
				else
					signal_out<=regin;
					counter<=counter-1;	
				end if;
			end if;
		end if;
	end process;

end architecture;