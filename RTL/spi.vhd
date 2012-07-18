-- Adapted by AMR from the Chameleon Minimig cfide.vhd file,
-- originally by Tobias Gubener.

-- spi_to_host contains data received from slave device.
-- Top bit, 15, indicated valid data ready
-- Bit 14 indicates attempt to write while busy.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity spi_interface is
	generic (
		bits : integer :=8
	);
	port (
		sysclk : in std_logic;
		reset : in std_logic;

		-- Host interface
		spiclk_in : in std_logic;	-- Momentary high pulse
		host_to_spi : in std_logic_vector(bits-1 downto 0);
		spi_to_host : out std_logic_vector(15 downto 0);
		trigger : in std_logic;  -- Momentary high pulse
		interrupt : out std_logic;

		-- Hardware interface
--		cs	: out std_logic;
		miso : in std_logic;
		mosi : out std_logic;
		spiclk_out : out std_logic -- 50% duty cycle
	);
end entity;

architecture rtl of spi_interface is
signal sd_busy : std_logic;
--signal scs : std_logic;
signal sck : std_logic;
signal sd_out : std_logic_vector(15 downto 0);
signal sd_in_shift : std_logic_vector(15 downto 0);
signal shiftcnt : std_logic_vector(13 downto 0);
begin

-----------------------------------------------------------------
-- SPI-Interface
-----------------------------------------------------------------	
--	cs <= NOT scs;
	spiclk_out <= NOT sck;
	mosi <= sd_out(15);
	sd_busy <= shiftcnt(13);

	spi_to_host(15)<=shiftcnt(13); -- busy?
	
	PROCESS (sysclk, reset) BEGIN

		IF reset ='0' THEN 
			shiftcnt <= (OTHERS => '0');
--			scs <= '0';
			sck <= '0';
--			mosi <='0';
			sd_out<=X"0000";
			spi_to_host(14 downto 0)<="000"&X"000";
		ELSIF rising_edge(sysclk) then
			interrupt<='0';
			IF trigger='1' then
				if sd_busy='1' then
					spi_to_host(14)<='1'; -- Indicate sd_busy failure
				else
					spi_to_host(14)<='0'; -- Indicate data not ready
--					scs<='1';
					shiftcnt <= "10000000000111";  -- shift out 8 bits, underflow will clear bit 13, mapped to sd_busy
					sd_out <= host_to_spi(7 downto 0) & X"FF";
					sck <= '1';
				END IF;
			ELSE
				IF spiclk_in='1' and sd_busy='1' THEN
					IF sck='0' THEN
						if shiftcnt(12 downto 0)="0000000000000" then
							spi_to_host(13 downto 0)<=sd_in_shift(13 downto 0);
							interrupt<='1';
--							scs<='0';
						else
							sck <='1';
						END IF;
						shiftcnt <= shiftcnt-1;
						sd_out <= sd_out(14 downto 0)&'1';
					ELSE	
						sck <='0';
						sd_in_shift <= sd_in_shift(14 downto 0)&miso;
					END IF;
				END IF;
			END IF;
		end if;
	END PROCESS;

end architecture;
