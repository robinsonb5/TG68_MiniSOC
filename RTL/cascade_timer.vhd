library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;


entity cascade_timer is
	port (
		clk : in std_logic;
		reset : in std_logic;
		setdiv : in std_logic;
		divisor : in std_logic_vector(1 downto 0);
		divin : in unsigned(15 downto 0);
		trigger : out std_logic_vector(3 downto 0)
	);
end entity;

architecture rtl of cascade_timer is

signal divisor0 : unsigned(15 downto 0);
signal divisor1 : unsigned(15 downto 0);
signal divisor2 : unsigned(15 downto 0);
signal divisor3 : unsigned(15 downto 0);

signal counter0 : unsigned(15 downto 0);
signal counter1 : unsigned(15 downto 0);
signal counter2 : unsigned(15 downto 0);
signal counter3 : unsigned(15 downto 0);

begin

	process(clk)
	begin
		if reset='0' then
			divisor0<=X"2BF2"; -- 10KHz @ 112.5 MHz sysclock
			divisor1<=X"0064"; -- 100Hz
			divisor2<=X"0064"; -- 100Hz
			divisor3<=X"0064"; -- 100Hz
			counter0<=X"0000";
			counter1<=X"0000";
			counter2<=X"0000";
			counter3<=X"0000";
		elsif rising_edge(clk) then
			if setdiv='1' then
				case divisor is
					when "00" =>
						divisor0<=divin;
						counter0<=divin;
					when "01" =>
						divisor1<=divin;
						counter1<=divin;
					when "10" =>
						divisor2<=divin;
						counter2<=divin;
					when "11" =>
						divisor3<=divin;
						counter3<=divin;
				end case;
			end if;
			
			trigger<="0000";

			counter0<=counter0-1;
			
			if counter0 = 0 then
				counter0 <= divisor0;
				
				counter1<=counter1-1;
				counter2<=counter2-1;
				counter3<=counter3-1;
				
				if counter1 = 0 then
					counter1 <= divisor1;
					trigger(1)<='1';
				end if;

				if counter2 = 0 then
					counter2 <= divisor2;
					trigger(2)<='1';
				end if;

				if counter3 = 0 then
					counter3 <= divisor3;
					trigger(3)<='1';
				end if;
			end if;
			
		end if;
	end process;
end architecture;