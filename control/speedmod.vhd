library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity speedmod is
	port(
		rst, clk : in std_logic;
		p : in PLAYER;
		is_hit, dir_hit : in std_logic;
		l, r, u, d : in std_logic;
		key_signal : in std_logic_vector(4 downto 0);-- 分别指示上下左右 0 W 1 S 2 A 3 D, 4 开火
		xs , ys : out SPDSET);
end entity;

architecture speedmod_beh of speedmod is
	
	constant jumpspd: std_logic_vector(15 downto 0) := "0000000000001111";
	constant judwspd: std_logic_vector(15 downto 0) := "0000000000000001";
	constant conspd : std_logic_vector(15 downto 0) := "0000000000000010";
	constant conacc : std_logic_vector(15 downto 0) := "0000000000000001";
	constant zerospd: std_logic_vector(15 downto 0) := "0000000000000000";
	constant maxdspd: std_logic_vector(15 downto 0) := "0000000000000011";
	
begin
	
	-- x speed
	
	process(rst, clk)
	variable cnt : integer := 50;
	begin
	
		if(rst = '1') then
		
			xs <= p.xs;
			ys <= p.ys;
			cnt := 0;
			
		elsif (rising_edge(clk)) then
						
			-- X PART
			
			--if(is_hit = '1') then -- hit : forced move
			
				--xs.spd <= conspd;
				--xs.dir <= not dir_hit;
				--xs.acc <= conacc;
			
			--else -- not hit : free move
			
				cnt := cnt + 1;
				
				if(cnt > 100) then cnt := 100; end if; 
				
				case cnt is
				
					when 1 => -- acc : dir not change
				
						if(p.xs.spd <= p.xs.acc) then xs.spd <= zerospd;
						else xs.spd <= p.xs.spd - p.xs.acc; end if;
						
						xs.acc <= p.xs.acc;
						xs.dir <= p.xs.dir;
							
					
					when 50 => -- key : dir may change
						
						if(key_signal(2) = '1') then -- move left
							xs.spd <= conspd;
							xs.dir <= '0';
							xs.acc <= conacc;
						elsif(key_signal(3) = '1') then -- move right
							xs.spd <= conspd;
							xs.dir <= '1';
							xs.acc <= conacc;
						end if;
					
					--when 15 => -- wall : block
						
					--	if(p.xs.dir = '0' and l = '1') then -- l block
					--		xs.spd <= zerospd;
					--	elsif (p.xs.dir = '1' and r = '1') then
					--		xs.spd <= zerospd;
					--	end if;
					
					when others =>
						
					end case;
					
				--end if;
				
			
			-- Y PART
			
			case cnt is
				when 1 => -- acc move
				
					if(p.ys.dir = '0') then -- up
						if (p.ys.spd <= p.ys.acc) then ys.spd <= zerospd; ys.dir <= '1'; -- start to down
						else ys.spd <= p.ys.spd - p.ys.acc; ys.dir <= '0'; end if;
					else
						if(p.ys.spd >= maxdspd) then ys.spd <= maxdspd;
						else ys.spd <= p.ys.spd + p.ys.acc; end if;
						ys.dir <= '1';
					end if;
					
					ys.acc <= p.ys.acc;
					
				when 30 => -- block 
					if (d = '1') then -- touch down
						ys.spd <= zerospd;
						ys.dir <= '1';
					end if;
				
				when 50 => -- key move
					if (key_signal(0) = '1' and d = '1') then -- only ground could jump
						ys.spd <= jumpspd;
						ys.dir <= '0';
					end if;
				
				when others =>
					
					
			end case;
				
			end if;
	
	end process;
	
end architecture speedmod_beh;

