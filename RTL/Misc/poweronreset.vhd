library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity poweronreset is
	port(
		clk : in std_logic;
		reset_button : in std_logic;
		reset_out : out std_logic;
		power_button : in std_logic := '1';
		power_hold : out std_logic := '1'
	);
end entity;

architecture rtl of poweronreset is
signal counter : unsigned(15 downto 0):=(others => '1');
signal resetbutton_debounced : std_logic;
signal powerbutton_debounced : std_logic;
signal powerbutton_posedge : std_logic;
signal resetbutton_posedge : std_logic;
signal poweron : std_logic :='1';

begin
	mydb : entity work.debounce
		port map(
			clk=>clk,
			signal_in=>reset_button and power_button,
			signal_out=>resetbutton_debounced,
			posedge=>resetbutton_posedge
		);
	mydb2 : entity work.debounce
		generic map(
			default => '0',	-- Will probably power up with the button held.
			bits => 23
		)
		port map(
			clk=>clk,
			signal_in=>power_button,
			signal_out=>powerbutton_debounced,
			posedge=>powerbutton_posedge
		);
	process(clk)
	begin
		if(rising_edge(clk)) then
			reset_out<='0';
			if resetbutton_posedge='1' then
				counter<=X"FFFF";
			elsif counter=X"0000" then
				if powerbutton_posedge='1' then
					power_hold<=poweron; -- Ignore the first posedge after poweron.
					poweron<='0';
				end if;
				reset_out<='1';
			else
				counter<=counter-1;
			end if;

		end if;
	end process;

end architecture;