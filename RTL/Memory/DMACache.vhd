library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library work;
use work.DMACache_pkg.ALL;
use work.DMACache_config.ALL;


entity DMACache is
	port(
		clk : in std_logic;
		reset_n : in std_logic;
		-- DMA channel address strobes

		channels_from_host : in DMAChannels_FromHost
			:= (others =>
					(
						addr => (others =>'X'),
						setaddr => '0',
						reqlen => (others =>'X'),
						setreqlen => '0',
						req => '0'
					)); -- Yes, I know - ick.
		channels_to_host : out DMAChannels_ToHost;

		data_out : out std_logic_vector(15 downto 0);

		-- SDRAM interface
		sdram_addr : out std_logic_vector(31 downto 0);
		sdram_reserveaddr : out std_logic_vector(31 downto 0);
		sdram_reserve : out std_logic;
		sdram_req : out std_logic;
		sdram_ack : in std_logic; -- Set when the request has been acknowledged.
		sdram_fill : in std_logic;
		sdram_data : in std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of dmacache is

type inputstate_t is (rd1,rcv1,rcv2,rcv3,rcv4);
signal inputstate : inputstate_t := rd1;

constant vga_base : std_logic_vector(2 downto 0) := "000";
constant spr0_base : std_logic_vector(2 downto 0) := "001";
constant spr1_base : std_logic_vector(2 downto 0) := "010";
constant aud0_base : std_logic_vector(2 downto 0) := "011";
constant aud1_base : std_logic_vector(2 downto 0) := "100";
constant aud2_base : std_logic_vector(2 downto 0) := "101";
constant aud3_base : std_logic_vector(2 downto 0) := "110";

-- DMA channel state information
type DMAChannel_Internal is record
	valid_d : std_logic; -- Used to delay the valid flag
	wrptr : unsigned(DMACache_MaxCacheBit downto 0);
	wrptr_next : unsigned(DMACache_MaxCacheBit downto 0);
	rdptr : unsigned(DMACache_MaxCacheBit downto 0);
	addr : std_logic_vector(31 downto 0); -- Current RAM address
	count : unsigned(15 downto 0); -- Number of words to transfer.
	pending : std_logic; -- Host has a request pending on this channel.
	sdram_pending : std_logic; -- A request to the SDRAM is in progress.
end record;

type DMAChannels_Internal is array (DMACache_MaxChannel downto 0) of DMAChannel_Internal;

signal internals : DMAChannels_Internal;

-- interface to the blockram

signal cache_wraddr : std_logic_vector(7 downto 0);
signal cache_rdaddr : std_logic_vector(7 downto 0);
signal cache_wren : std_logic;
signal data_from_ram : std_logic_vector(15 downto 0);

begin

myDMACacheRAM : entity work.DMACacheRAM
	port map
	(
		clock => clk,
		data => data_from_ram,
		rdaddress => cache_rdaddr,
		wraddress => cache_wraddr,
		wren => cache_wren,
		q => data_out
	);

-- Employ bank reserve for SDRAM.
-- FIXME - use pointer comparison to turn off reserve when not needed.
sdram_reserve<='1' when internals(0).count/=X"000" else '0';

process(clk)
	variable activechannel : integer range 0 to DMACache_MaxChannel;
	variable activereq : std_logic;
begin
	if rising_edge(clk) then
		if reset_n='0' then
			inputstate<=rd1;
			for I in 0 to DMACache_MaxChannel loop
				internals(I).count<=(others => '0');
				internals(I).wrptr<=(others => '0');
				internals(I).wrptr_next<=(2=>'1', others =>'0');
			end loop;
		end if;

		cache_wren<='0';
		
		if sdram_ack='1' then
			sdram_reserveaddr<=internals(0).addr;
			sdram_req<='0';
		end if;

		-- Request and receive data from SDRAM:
		case inputstate is
			-- First state: Read.  Check the channels in priority order.
			-- VGA has absolute priority, and the others won't do anything until the VGA buffer is
			-- full.
			when rd1 =>
				activereq:='0';
				for I in 1 to DMACache_MaxChannel loop
					if internals(I).rdptr( DMACache_MaxCacheBit downto 2)/=internals(I).wrptr_next( DMACache_MaxCacheBit downto 2) and internals(I).count/=X"000" then
						activechannel := I;
						activereq:='1';
					end if;
				end loop;
				-- Give channel zero priority:
				if internals(0).rdptr( DMACache_MaxCacheBit downto 2)/=internals(0).wrptr_next( DMACache_MaxCacheBit downto 2) and internals(0).count/=X"000" then
					activechannel := 0;
					activereq:='1';
				end if;

				if activereq='1' then
					cache_wraddr<=std_logic_vector(to_unsigned(activechannel,3))&std_logic_vector(internals(activechannel).wrptr);
					sdram_req<='1';
					sdram_addr<=internals(activechannel).addr;
					internals(activechannel).addr<=std_logic_vector(unsigned(internals(activechannel).addr)+8);
					inputstate<=rcv1;
					internals(activechannel).sdram_pending<='1';
					internals(activechannel).count<=internals(activechannel).count-4;
				end if;

--				elsif internals(1).rdptr( DMACache_MaxCacheBit downto 2)/=internals(1).wrptr_next( DMACache_MaxCacheBit downto 2) and internals(1).count/=X"000" then
--					cache_wraddr<=spr0_base&std_logic_vector(internals(1).wrptr);
--					sdram_req<='1';
--					sdram_addr<=internals(1).addr;
--					internals(1).addr<=std_logic_vector(unsigned(internals(1).addr)+8);
--					inputstate<=rcv1;
--					update<=upd_spr0;
--					internals(1).count<=internals(1).count-4;
--				end if;

			-- Wait for SDRAM, fill first word.
			when rcv1 =>
				if sdram_fill='1' then
					data_from_ram<=sdram_data;
					cache_wren<='1';
					inputstate<=rcv2;
				end if;
			when rcv2 =>
				data_from_ram<=sdram_data;
				cache_wren<='1';
				cache_wraddr<=std_logic_vector(unsigned(cache_wraddr)+1);
				inputstate<=rcv3;
			when rcv3 =>
				data_from_ram<=sdram_data;
				cache_wren<='1';
				cache_wraddr<=std_logic_vector(unsigned(cache_wraddr)+1);
				inputstate<=rcv4;
			when rcv4 =>
				data_from_ram<=sdram_data;
				cache_wren<='1';
				cache_wraddr<=std_logic_vector(unsigned(cache_wraddr)+1);
				inputstate<=rd1;
				
				internals(activechannel).wrptr<=internals(activechannel).wrptr_next;
				internals(activechannel).wrptr_next<=internals(activechannel).wrptr_next+4;
			when others =>
				null;
		end case;
	
		for I in 0 to DMACache_MaxChannel loop
			if channels_from_host(I).setaddr='1' then
				internals(I).addr<=channels_from_host(I).addr;
				internals(I).wrptr<=(others =>'0');
				internals(I).wrptr_next<=(2=>'1', others =>'0');
			end if;
			if channels_from_host(I).setreqlen='1' then
				internals(I).count<=channels_from_host(I).reqlen;
			end if;
		end loop;

	end if;
end process;


process(clk)
	variable servicechannel : integer range 0 to DMACache_MaxChannel;
	variable serviceactive : std_logic;
begin
	if rising_edge(clk) then
		if reset_n='0' then
			for I in 0 to DMACache_MaxChannel loop
				internals(I).rdptr<=(others => '0');
			end loop;
		end if;

	-- Reset read pointers when a new address is set
		for I in 0 to DMACache_MaxChannel loop
			if channels_from_host(I).setaddr='1' then
				internals(I).rdptr<=(others => '0');
				internals(I).pending<='0';
			end if;
		end loop;

	-- Handle timeslicing of output registers
	-- We prioritise simply by testing in order of priority.
	-- req signals should always be a single pulse; need to latch all but VGA, since it may be several
	-- cycles since they're serviced.

		for I in 0 to DMACache_MaxChannel loop -- Channel 0 has priority, so is never held pending.
			if channels_from_host(I).req='1' then
				internals(I).pending<='1';
			end if;

--			channels_to_host(I).valid<=internals(I).valid_d;
--			internals(I).valid_d<='0';
			channels_to_host(I).valid<='0';
		end loop;
		
		serviceactive := '0';
		for I in 1 to DMACache_MaxChannel loop
			if internals(I).pending='1' and internals(I).rdptr/=internals(I).wrptr then
				serviceactive := '1';
				servicechannel := I;
			end if;
		end loop;
		if channels_from_host(0).req='1' then
				serviceactive := '1';
				servicechannel := 0;
		end if;

		if serviceactive='1' then
			cache_rdaddr<=std_logic_vector(to_unsigned(servicechannel,3))&std_logic_vector(internals(servicechannel).rdptr);
			internals(servicechannel).rdptr<=internals(servicechannel).rdptr+1;
--			internals(servicechannel).valid_d<='1';
			channels_to_host(servicechannel).valid<='1';
			internals(servicechannel).pending<='0';
		end if;

	end if;
end process;
		
end rtl;

