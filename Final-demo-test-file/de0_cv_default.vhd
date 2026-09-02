LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use work.layers_pack.ALL;

ENTITY de0_cv_default IS
    PORT(
        clock_50    : IN std_logic;
        reset_n     : IN std_logic;
        sw          : IN std_logic_vector(9 downto 0);
        key         : IN std_logic_vector(3 downto 0);
        
        hex0, hex1, hex2, hex3, hex4, hex5 : OUT std_logic_vector(6 downto 0);
        led         : OUT std_logic_vector(9 downto 0);
        
        vga_r, vga_g, vga_b : OUT std_logic_vector(3 downto 0);
        vga_hs, vga_vs      : OUT std_logic;
        
        ps2_clk, ps2_dat    : INOUT std_logic
    );
END de0_cv_default;

ARCHITECTURE structural OF de0_cv_default IS

	 signal layers : layers_array_t;
	 
    SIGNAL clk_25mhz      : std_logic;
    SIGNAL reset_sys      : std_logic;
    
    SIGNAL pixel_row, pixel_col : std_logic_vector(9 downto 0);
    SIGNAL vga_vert_sync, vga_horiz_sync : std_logic;
    
    -- Intermediate color signals
    SIGNAL vr, vg, vb : std_logic;
    SIGNAL vga_r_sync, vga_g_sync, vga_b_sync : std_logic; -- NEW SIGNALS FOR THE FIX
    
    SIGNAL left_btn, right_btn : std_logic;
    
    SIGNAL game_state     : std_logic_vector(1 downto 0);
    SIGNAL reset_game     : std_logic;
    SIGNAL collision      : std_logic;
    SIGNAL lives_zero     : std_logic;
    SIGNAL score_tick, gift_tick : std_logic;
    
    SIGNAL bird_y         : std_logic_vector(9 downto 0);
    SIGNAL bird_on, pipe_on, ground_on, gift_on : std_logic;
    
    SIGNAL s_ones, s_tens, l_count : std_logic_vector(3 downto 0);
    SIGNAL current_level  : integer;
    SIGNAL level_bcd      : std_logic_vector(3 downto 0);
    
    SIGNAL lfsr_rand      : std_logic_vector(7 downto 0);
    
    SIGNAL text_menu, text_train, text_game, text_play, text_over : std_logic;
    SIGNAL text_menu_rgb, text_train_rgb, text_game_rgb, dummy_rgb : std_logic_vector(2 downto 0);
	 

BEGIN
    reset_sys <= NOT reset_n;
    level_bcd <= std_logic_vector(to_unsigned(current_level, 4));

    -- CLOCK
    clk_inst : ENTITY work.clk25_gen PORT MAP (clk_50 => clock_50, clk_25 => clk_25mhz);

    -- VGA SYNC
    vga_sync_inst : ENTITY work.vga_sync PORT MAP(
            clock_25mhz => clk_25mhz,
				red => vr,
				green => vg,
				blue => vb,
            red_out => vga_r_sync,
				green_out => vga_g_sync,
				blue_out => vga_b_sync, -- Assigned to internal wires
            horiz_sync_out => vga_hs,
				vert_sync_out => vga_vert_sync,
            pixel_row => pixel_row,
				pixel_column => pixel_col);
            
    -- Expand 1-bit color internal wire to 4-bit DAC output pins (THIS FIXES THE ERROR)
    vga_r <= (others => vga_r_sync);
    vga_g <= (others => vga_g_sync);
    vga_b <= (others => vga_b_sync);
    vga_vs <= vga_vert_sync;

    -- MOUSE
    mouse_inst : ENTITY work.mouse PORT MAP (
            clock_25mhz => clk_25mhz,
				reset => reset_sys,
            mouse_data => ps2_dat,
				mouse_clk => ps2_clk,
            left_button => left_btn,
				right_button => right_btn,
            mouse_cursor_row => OPEN,
				mouse_cursor_column => OPEN);

    -- RANDOM NUMBER GENERATOR (LFSR)
    lfsr_inst : ENTITY work.lfsr PORT MAP (
            clk => clk_25mhz,
				reset => reset_sys,
				q_out => lfsr_rand);

    -- FSM
    fsm_inst : ENTITY work.game_fsm PORT MAP(
            clk => clk_25mhz,
				reset_btn => NOT key(0),
				play_btn  => NOT key(1),
				pause_btn => NOT key(2), 
            collision_event => collision,
				lives_zero => lives_zero,
				state_out => game_state,
				reset_game_sigs => reset_game);

    -- SCORE / LIVES / LEVEL TRACKER
    score_inst : ENTITY work.score_lives PORT MAP(
            clk => clk_25mhz,
				vert_sync => vga_vert_sync,
				reset_game => reset_game,
				game_state => game_state,
            sw_training => sw(9),
				score_tick => score_tick,
				gift_tick => gift_tick,
				collision => collision,
            score_ones => s_ones,
				score_tens => s_tens,
				lives => l_count,
				current_level => current_level,
				lives_zero => lives_zero);

    -- BIRD PHYSICS
    bird_inst : ENTITY work.bird_logic PORT MAP(
            clk => clk_25mhz,
				vert_sync => vga_vert_sync,
				mouse_click => left_btn,
            reset_pos => reset_game,
				game_state => game_state,
            pixel_row => pixel_row,
				pixel_column => pixel_col,
				bird_on_out => layers(bird_layer).layer_on,
				bird_y_out => bird_y);

    -- LEVEL MAP (PIPES/GIFTS)
    level_inst : ENTITY work.conveyor_belt PORT MAP(
            clk => clk_25mhz,
				vert_sync => vga_vert_sync,
				game_state => game_state,
				reset_level => reset_game,
            current_lvl => current_level,
				lfsr_rand => lfsr_rand,
            pixel_row => pixel_row,
				pixel_col => pixel_col,
				bird_y => bird_y,
            pipe_on => layers(obstacle_layer).layer_on,
				ground_on => layers(floor_layer).layer_on,
				gift_on => layers(gift_layer).layer_on, 
            collision => collision,
				score_tick => score_tick,
				gift_tick => gift_tick);

    -- TEXT OVERLAYS
    t_menu : ENTITY work.text_engine 
				GENERIC MAP ("MAIN MENU")
				PORT MAP(
					clk_25mhz => clk_25mhz,
					pixel_row => pixel_row,
					pixel_col => pixel_col,
					position_x => std_logic_vector(to_unsigned(220, 10)),
					position_y => std_logic_vector(to_unsigned(200, 10)),
					text_scale => "10",
					text_on => text_menu,
					text_rgb => text_menu_rgb
				);
	
    t_train : ENTITY work.text_engine 
				GENERIC MAP ("TRAINING") 
				PORT MAP(
					clk_25mhz => clk_25mhz,
					pixel_row => pixel_row,
					pixel_col => pixel_col,
					position_x => std_logic_vector(to_unsigned(0, 10)),
					position_y => std_logic_vector(to_unsigned(0, 10)),
					text_scale => "01",
					text_on => text_train,
					text_rgb => text_train_rgb
				);
    t_game : ENTITY work.text_engine 
				GENERIC MAP ("GAME")
				PORT MAP(
					clk_25mhz => clk_25mhz,
					pixel_row => pixel_row,
					pixel_col => pixel_col,
					position_x => std_logic_vector(to_unsigned(0, 10)),
					position_y => std_logic_vector(to_unsigned(0, 10)),
					text_scale => "01",
					text_on => text_game,
					text_rgb => text_game_rgb
				);
    t_over : ENTITY work.text_engine 
				GENERIC MAP ("GAME OVER")
				PORT MAP(
					clk_25mhz => clk_25mhz,
					pixel_row => pixel_row,
					pixel_col => pixel_col,
					position_x => std_logic_vector(to_unsigned(200, 10)),
					position_y => std_logic_vector(to_unsigned(200, 10)),
					text_scale => "10",
					text_on => text_over,
					text_rgb => dummy_rgb
				);

    text_play <= text_train WHEN sw(9) = '1' ELSE text_game;
	 
    -- PIXEL ROUTER
    router_inst : ENTITY work.display_pixel_router PORT MAP(
            layers => layers,
            vid_r => vr,
				vid_g => vg,
				vid_b => vb);
	 
	 -- Temp hard coded values for rgb colours of temp sprites
	 -- These rgb values should be handled by the ROM and not in here to match
	 -- the sprites pixel colour.
	 layers(background_layer).layer_on <= '1';
	 layers(background_layer).rgb  <= "001";
	 layers(floor_layer).rgb   <= "010";
	 layers(obstacle_layer).rgb <= "010";
	 layers(gift_layer).rgb     <= "110";
	 layers(bird_layer).rgb     <= "110";
	 
	 layers(text_layer).layer_on <= text_menu or text_play;
	 layers(text_layer).rgb <= 
		 text_menu_rgb when text_menu = '1' else
		 text_train_rgb when text_play = '1' else
		 text_menu_rgb;
	

    -- SEVEN SEGMENTS
    seg_score0 : ENTITY work.seven_seg PORT MAP(BCD_digit => s_ones, SevenSeg_out => hex0);
    seg_score1 : ENTITY work.seven_seg PORT MAP(BCD_digit => s_tens, SevenSeg_out => hex1);
    seg_lvl    : ENTITY work.seven_seg PORT MAP(BCD_digit => level_bcd, SevenSeg_out => hex2);
    hex3 <= "1111111"; hex4 <= "1111111"; 
    seg_lives  : ENTITY work.seven_seg PORT MAP(BCD_digit => l_count, SevenSeg_out => hex5);

    led(1 downto 0) <= game_state; led(9) <= sw(9);
END structural;