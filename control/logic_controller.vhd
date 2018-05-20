-- Give bullet and player information to vga output
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity logic_controller is
	port(
		rst, clk: in std_logic;
		player_one_input: in std_logic_vector(4 downto 0);
		player_two_input: in std_logic_vector(4 downto 0);
		enter: in std_logic;
		bullets_output: out BULLETS;
		players_output: out PLAYERS;
		barriers_output:out BARRIERS;
		curs:out std_logic_vector(2 downto 0);
		xout : out std_logic_vector(15 downto 0)
	);
end entity logic_controller;

architecture logic_controller_bhv of logic_controller is
	
	component speedmod is
		port(
			rst, clk : in std_logic;
			p : PLAYER;
			is_hit, dir_hit : in std_logic;
			l, r, u, d : in std_logic;
			key_signal : in std_logic_vector(4 downto 0);-- 分别指示上下左右 0 W 1 S 2 A 3 D, 4 开火
			xs , ys : buffer SPDSET);
	end component speedmod;
	
	component nextpos is
	port(
		rst, clk : in std_logic;
		p : PLAYER;
		x , y : out std_logic_vector(15 downto 0));
	end component nextpos;
	
	component init is
	port(
		rst, clk : in std_logic;
		bullets : out BULLETS;
		barriers: out BARRIERS;
		players : out PLAYERS);
	end component init;
	
	component wallhit is
	port(
		rst, clk : in std_logic;
		x, y : in std_logic_vector(15 downto 0);
		wmap : in BARRIERS;
		l, r, u, d : out std_logic);
	end component;
	
	signal bullets, bullets_init : BULLETS;
	signal barriers, barriers_init : BARRIERS;
	signal players, players_init: PLAYERS;

	type STATE is (start, init_state, p1work);
--After update_coor reached, the information can be sent to vga controller
--caution : the end of game

	signal cur_state: STATE := start;
	
	signal init_enable, p1move_enable, p1spdm_enable : std_logic;
	signal wallhit_enable : std_logic;
	signal walll, wallr, wallu, walld : std_logic;
	signal wl, wr, wu, wd : std_logic;
	
	signal p1_nxt_x, p1_nxt_y : std_logic_vector(15 downto 0);
	signal p1_nxt_xspd, p1_nxt_yspd : SPDSET;
	
	signal tpbit : std_logic;
	signal tpbit1 : std_logic;
	signal tpbit2 : std_logic;
	
begin
	
	PINIT: init port map(init_enable, clk, bullets_init, barriers_init, players_init);
	P1MOVE: nextpos port map(p1move_enable, clk, players(0), p1_nxt_x, p1_nxt_y);
	P1SPEMOD: speedmod port map(p1spdm_enable, clk, players(0), '0', '0', wl, wr, wu, wd, player_one_input, p1_nxt_xspd, p1_nxt_yspd);
	P1WALLHIT: wallhit port map(wallhit_enable, clk, players(0).x, players(0).y, barriers, walll, wallr, wallu, walld);
	
	bullets_output <= bullets;
	barriers_output <= barriers;
	players_output <= players;
	
	--tpbit <= '1' when players(0).y + PLY_Y >= barriers(2).ay else '0';
	--tpbit1<= '1' when not (players(0).x + PLY_X <= barriers(2).ax) else '0';
	--tpbit2<= '1' when not (players(0).x > barriers(2).bx) else '0';
	--xout <= "0000000000000"&tpbit&tpbit1&tpbit2;
	xout <= "000000000000000"&wd;
	--if(y <= ay and y + wy + pls >= ay and (not x + wx <= ax) and (not x > bx))
	
	process(clk, rst)
	variable rising_count : integer := 0;
	begin
		if(rst = '0') then -- to be added
			
			curs <= "000";
			
			cur_state <= init_state;
			rising_count := 0;
			p1move_enable <= '1';
			p1spdm_enable <= '1';
			init_enable <= '1';
			wallhit_enable <= '1';
			
		elsif(rising_edge(clk)) then
		
			case cur_state is
				
				when init_state =>
					
					rising_count := rising_count + 1;
					if(rising_count = 1000000) then
						rising_count := 0;
						cur_state <= p1work;
					end if;
					
					case rising_count is
						when 1=> 
							p1move_enable <= '1';
							p1spdm_enable <= '1';
							init_enable <= '0';
							wallhit_enable <= '1';
						
						when 500000=>
							bullets <= bullets_init;
							barriers <= barriers_init;
							players <= players_init;
						
						when 700000=>
							barriers(2).ax <= "0000000100000000";
							barriers(2).ay <= "0000001000000000";
							barriers(2).bx <= "0000010000000000";
							barriers(2).by <= "0000001000001000";

						when 800000=>
							barriers(3).ax <= "0000000010000000";
							barriers(3).bx <= "0000000111110100";
							barriers(3).ay <= "0000000110010110";
							barriers(3).by <= "0000000110011110";
						
						when 900000=>
							barriers(4).ax <= "0000001000001000";
							barriers(4).bx <= "0000001001011000";
							barriers(4).ay <= "0000000101101110";
							barriers(4).by <= "0000000101110110";
						
						
						
						when others=>
							
					end case;
				
				when p1work =>
					
					rising_count := rising_count + 1;
					if(rising_count = 1000000) then
						rising_count := 0;
						cur_state <= p1work;
					end if;
					
					case rising_count is
						
						when 1=> -- p1-wallhit
							curs <= "011";
							p1spdm_enable <= '1';
							p1move_enable <= '1';
							init_enable <= '1';
							wallhit_enable <= '0';
						
						when 50000=> -- p1 wallhit set
							wl <= walll;
							wr <= wallr;
							wu <= wallu;
							wd <= walld;
					
						when 100000=> -- p1_spdm
							curs <= "100";
							p1spdm_enable <= '0';
							p1move_enable <= '1';
							init_enable <= '1';
							wallhit_enable <= '1';
						
						when 200000=> -- p1_spdm_g
							curs <= "101";
							players(0).xs <= p1_nxt_xspd;
							players(0).ys <= p1_nxt_yspd;
							wallhit_enable <= '1';
						
						when 300000=> -- p1_mov
							curs <= "110";
							p1spdm_enable <= '1';
							p1move_enable <= '0';
							init_enable <= '1';
							wallhit_enable <= '1';
						
						when 400000=> -- p1_mov_g
							curs <= "111";
							players(0).x <= p1_nxt_x;
							players(0).y <= p1_nxt_y;
						
						when others=>
					
					end case;
				
				when others=>
					rising_count := 0;
					cur_state <= p1work;
					
			end case;
			
		end if;
	end process;
end logic_controller_bhv; 
