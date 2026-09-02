library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.layers_pack.all;

entity de0_cv_default is
    port(
        clock_50 : in std_logic;
        reset_n  : in std_logic;
        sw       : in std_logic_vector(9 downto 0);
        key      : in std_logic_vector(3 downto 0);

        hex0, hex1, hex2, hex3, hex4, hex5 : out std_logic_vector(6 downto 0);
        led                                : out std_logic_vector(9 downto 0);

        vga_r, vga_g, vga_b : out std_logic_vector(3 downto 0);
        vga_hs, vga_vs      : out std_logic;

        ps2_clk, ps2_dat : inout std_logic
    );
end de0_cv_default;

architecture structural of de0_cv_default is

    signal layers : layers_array_t;

    signal clk_25mhz : std_logic;
    signal reset_sys : std_logic;

    signal pixel_row, pixel_col             : std_logic_vector(9 downto 0);
    signal vga_vert_sync, vga_horiz_sync    : std_logic;

    signal vr, vg, vb                       : std_logic;
    signal vga_r_sync, vga_g_sync, vga_b_sync : std_logic;

    signal left_btn, right_btn              : std_logic;

    -- Mouse cursor signals.
    signal mouse_row, mouse_col             : std_logic_vector(9 downto 0);
    signal cursor_on                        : std_logic;

    signal game_state                       : std_logic_vector(1 downto 0);
    signal reset_game                       : std_logic;
    signal ground_col                       : std_logic;
    signal pipe_col                         : std_logic;
    signal lives_zero                       : std_logic;
    signal score_tick, gift_tick            : std_logic;
    signal play_request                     : std_logic;

    -- Menu mode selection.
    signal selected_training                : std_logic := '0'; -- 1 = training, 0 = game
    signal menu_train_hover                 : std_logic;
    signal menu_game_hover                  : std_logic;
    signal menu_click_start                 : std_logic;

    -- Game object signals.
    signal bird_y                           : std_logic_vector(9 downto 0);
    signal bird_on_raw, pipe_on_raw         : std_logic;
    signal ground_on_raw, gift_on_raw       : std_logic;
    signal pipebody_on_raw                  : std_logic;
    signal game_visible                     : std_logic;
    signal bounce_flag                      : std_logic;

    -- Delayed signals to align with the 1-clock ROM data.
    signal bird_on_d1, pipe_on_d1           : std_logic := '0';
    signal ground_on_d1, gift_on_d1         : std_logic := '0';
    signal pipebody_on_d1                   : std_logic := '0';

    -- Score, lives, and level.
    signal s_ones, s_tens, l_count          : std_logic_vector(3 downto 0);
    signal current_level                    : integer;
    signal level_bcd                        : std_logic_vector(3 downto 0);

    signal lfsr_rand                        : std_logic_vector(7 downto 0);

    -- Text overlay signals.
    signal text_title, text_train           : std_logic;
    signal text_game                        : std_logic;
    signal text_pause, text_over            : std_logic;
    signal text_press_start                 : std_logic;
    signal text_combined                    : std_logic;
	 
	 signal text_game_position_x  : std_logic_vector(9 downto 0);
	 signal text_game_position_y  : std_logic_vector(9 downto 0);
	 signal text_train_position_x : std_logic_vector(9 downto 0);
	 signal text_train_position_y : std_logic_vector(9 downto 0);

    signal text_title_rgb, text_train_rgb : std_logic_vector(2 downto 0);
    signal text_game_rgb                  : std_logic_vector(2 downto 0);
    signal text_pause_rgb, text_over_rgb       : std_logic_vector(2 downto 0);
    signal text_press_start_rgb                : std_logic_vector(2 downto 0);

    -- Sprite ROM signals.
    signal bird_addr                        : std_logic_vector(7 downto 0);
    signal bird_rgb                         : std_logic_vector(2 downto 0);

    signal gift_addr                        : std_logic_vector(8 downto 0);
    signal gift_rgb                         : std_logic_vector(2 downto 0);

    signal ground_addr                      : std_logic_vector(7 downto 0);
    signal ground_rgb                       : std_logic_vector(2 downto 0);

    signal pipecap_addr                     : std_logic_vector(9 downto 0);
    signal pipecap_rgb                      : std_logic_vector(2 downto 0);

begin

    reset_sys <= not reset_n;
    level_bcd <= std_logic_vector(to_unsigned(current_level, 4));

    -- Clock divider.
    clk_inst : entity work.clk25_gen
        port map(
            clk_50 => clock_50,
            clk_25 => clk_25mhz
        );

    -- VGA sync and pixel coordinate generator.
    vga_sync_inst : entity work.vga_sync
        port map(
            clock_25mhz   => clk_25mhz,
            red           => vr,
            green         => vg,
            blue          => vb,
            red_out       => vga_r_sync,
            green_out     => vga_g_sync,
            blue_out      => vga_b_sync,
            horiz_sync_out => vga_hs,
            vert_sync_out => vga_vert_sync,
            pixel_row     => pixel_row,
            pixel_column  => pixel_col
        );

    -- Expand 1-bit VGA colour signals to the 4-bit DAC outputs.
    vga_r  <= (others => vga_r_sync);
    vga_g  <= (others => vga_g_sync);
    vga_b  <= (others => vga_b_sync);
    vga_vs <= vga_vert_sync;

    -- PS/2 mouse interface.
    mouse_inst : entity work.mouse
        port map(
            clock_25mhz        => clk_25mhz,
            reset              => reset_sys,
            mouse_data         => ps2_dat,
            mouse_clk          => ps2_clk,
            left_button        => left_btn,
            right_button       => right_btn,
            mouse_cursor_row   => mouse_row,
            mouse_cursor_column => mouse_col
        );

    -- Menu hover regions.
    menu_train_hover <= '1' when (
        game_state = "00" and
        unsigned(mouse_col) >= to_unsigned(240, 10) and
        unsigned(mouse_col) <  to_unsigned(400, 10) and
        unsigned(mouse_row) >= to_unsigned(240, 10) and
        unsigned(mouse_row) <  to_unsigned(280, 10)
    ) else '0';

    menu_game_hover <= '1' when (
        game_state = "00" and
        unsigned(mouse_col) >= to_unsigned(270, 10) and
        unsigned(mouse_col) <  to_unsigned(370, 10) and
        unsigned(mouse_row) >= to_unsigned(290, 10) and
        unsigned(mouse_row) <  to_unsigned(330, 10)
    ) else '0';

    -- Menu mode selection. The switch provides the default when the cursor is not hovering.
    process(clk_25mhz, reset_sys)
    begin
        if reset_sys = '1' then
            selected_training <= sw(9);
        elsif rising_edge(clk_25mhz) then
            if game_state = "00" then
                if menu_train_hover = '1' then
                    selected_training <= '1';
                elsif menu_game_hover = '1' then
                    selected_training <= '0';
                else
                    selected_training <= sw(9);
                end if;
            end if;
        end if;
    end process;

    menu_click_start <= left_btn when (
        game_state = "00" and
        (menu_train_hover = '1' or menu_game_hover = '1')
    ) else '0';

    play_request <= (not key(1)) or menu_click_start;

    -- Random number generator.
    lfsr_inst : entity work.lfsr
        port map(
            clk   => clk_25mhz,
            reset => reset_sys,
            q_out => lfsr_rand
        );

    -- Main game state machine.
    fsm_inst : entity work.game_fsm
        port map(
            clk              => clk_25mhz,
            reset_btn        => not key(0),
            play_btn         => play_request,
            pause_btn        => not key(2),
            collision_event  => pipe_col or ground_col,
            lives_zero       => lives_zero,
            state_out        => game_state,
            reset_game_sigs  => reset_game
        );

    -- Score, lives, and level tracking.
    score_inst : entity work.score_lives
        port map(
            clk           => clk_25mhz,
            vert_sync     => vga_vert_sync,
            reset_game    => reset_game,
            game_state    => game_state,
            sw_training   => selected_training,
            score_tick    => score_tick,
            gift_tick     => gift_tick,
            ground_col    => ground_col,
            pipe_col      => pipe_col,
            score_ones    => s_ones,
            score_tens    => s_tens,
            lives         => l_count,
            current_level => current_level,
            lives_zero    => lives_zero
        );

    -- Bird movement and sprite address generation.
    bird_inst : entity work.bird_logic
        port map(
            clk          => clk_25mhz,
            vert_sync    => vga_vert_sync,
            mouse_click  => left_btn,
            reset_pos    => reset_game,
            game_state   => game_state,
            pipe_col     => pipe_col,
            death        => lives_zero,
            bounce       => bounce_flag,
            pixel_row    => pixel_row,
            pixel_column => pixel_col,
            bird_on_out  => bird_on_raw,
            bird_y_out   => bird_y,
            bird_addr    => bird_addr
        );

    -- Pipe, gift, ground, and collision logic.
    level_inst : entity work.conveyor_belt
        port map(
            clk           => clk_25mhz,
            vert_sync     => vga_vert_sync,
            game_state    => game_state,
            reset_level   => reset_game,
            current_lvl   => current_level,
            bounce_active => bounce_flag,
            lfsr_rand     => lfsr_rand,
            pixel_row     => pixel_row,
            pixel_col     => pixel_col,
            bird_y        => bird_y,
            pipe_on       => pipe_on_raw,
            ground_on     => ground_on_raw,
            gift_on       => gift_on_raw,
            pipe_col      => pipe_col,
            ground_col    => ground_col,
            score_tick    => score_tick,
            gift_tick     => gift_tick,
            ground_addr   => ground_addr,
            gift_addr     => gift_addr,
            pipecap_addr  => pipecap_addr,
            pipebody_on   => pipebody_on_raw
        );
    -- Sprite ROMs.
    bird_rom : entity work.sprite_rom
        generic map("bao.mif", 256, 8)
        port map(clk_25mhz, bird_addr, bird_rgb);

    ground_rom : entity work.sprite_rom
        generic map("ground.mif", 256, 8)
        port map(clk_25mhz, ground_addr, ground_rgb);

    gift_rom : entity work.sprite_rom
        generic map("gift.mif", 400, 9)
        port map(clk_25mhz, gift_addr, gift_rgb);

    pipecap_rom : entity work.sprite_rom
        generic map("pipecap.mif", 800, 10)
        port map(clk_25mhz, pipecap_addr, pipecap_rgb);

    -- Text overlays.
    t_title : entity work.text_engine
        generic map("BAO BOUNCE")
        port map(
            clk_25mhz => clk_25mhz,
            pixel_row => pixel_row,
            pixel_col => pixel_col,
            position_x => std_logic_vector(to_unsigned(160, 10)),
            position_y => std_logic_vector(to_unsigned(100, 10)),
            text_scale => "10",
            text_on    => text_title,
            text_rgb   => text_title_rgb
        );

    t_train : entity work.text_engine
        generic map("TRAINING")
        port map(
            clk_25mhz => clk_25mhz,
            pixel_row => pixel_row,
            pixel_col => pixel_col,
            position_x => text_train_position_x,
            position_y => text_train_position_y,
            text_scale => "01",
            text_on    => text_train,
            text_rgb   => text_train_rgb
        );

    t_game : entity work.text_engine
        generic map("GAME")
        port map(
            clk_25mhz => clk_25mhz,
            pixel_row => pixel_row,
            pixel_col => pixel_col,
            position_x => text_game_position_x,
            position_y => text_game_position_y,
            text_scale => "01",
            text_on    => text_game,
            text_rgb   => text_game_rgb
        );

    t_pause : entity work.text_engine
        generic map("PAUSED")
        port map(
            clk_25mhz => clk_25mhz,
            pixel_row => pixel_row,
            pixel_col => pixel_col,
            position_x => std_logic_vector(to_unsigned(224, 10)),
            position_y => std_logic_vector(to_unsigned(200, 10)),
            text_scale => "10",
            text_on    => text_pause,
            text_rgb   => text_pause_rgb
        );

    t_over : entity work.text_engine
        generic map("GAME OVER")
        port map(
            clk_25mhz => clk_25mhz,
            pixel_row => pixel_row,
            pixel_col => pixel_col,
            position_x => std_logic_vector(to_unsigned(176, 10)),
            position_y => std_logic_vector(to_unsigned(150, 10)),
            text_scale => "10",
            text_on    => text_over,
            text_rgb   => text_over_rgb
        );

    t_press_start : entity work.text_engine
        generic map("PRESS START")
        port map(
            clk_25mhz => clk_25mhz,
            pixel_row => pixel_row,
            pixel_col => pixel_col,
            position_x => std_logic_vector(to_unsigned(232, 10)),
            position_y => std_logic_vector(to_unsigned(300, 10)),
            text_scale => "01",
            text_on    => text_press_start,
            text_rgb   => text_press_start_rgb
        );

    -- Select which text is visible for each game state.
    process(
        game_state,
        selected_training,
        text_title,
        text_train,
        text_game,
        text_pause,
        text_over,
        text_press_start
    )
    begin
		 text_game_position_x  <= std_logic_vector(to_unsigned(288, 10));
		 text_game_position_y  <= std_logic_vector(to_unsigned(300, 10));
		 text_train_position_x <= std_logic_vector(to_unsigned(256, 10));
		 text_train_position_y <= std_logic_vector(to_unsigned(250, 10));
		 
       case game_state is 
				-- main menu
				when "00" => 
					text_game_position_x <= std_logic_vector(to_unsigned(288, 10));
					text_game_position_y <= std_logic_vector(to_unsigned(300, 10));
					text_train_position_x <= std_logic_vector(to_unsigned(256, 10));
					text_train_position_y <= std_logic_vector(to_unsigned(250, 10));
					text_combined <= text_title or text_train or text_game;
				-- game state
				when "01" => 
						text_game_position_x <= std_logic_vector(to_unsigned(16, 10));
						text_game_position_y <= std_logic_vector(to_unsigned(16, 10));
						text_train_position_x <= std_logic_vector(to_unsigned(16, 10));
						text_train_position_y <= std_logic_vector(to_unsigned(16, 10));
						if selected_training = '1' then 
							text_combined <= text_train;
						else
							text_combined <= text_game;
						end if;
				when "10" =>
					text_combined <= text_pause;
				when "11" => 
					text_combined <= text_over or text_press_start;
				
				when others => 
					text_combined <= '0';
			
		 end case;
    end process;

    -- Delay object boundaries to align with the 1-clock ROM output delay.
    process(clk_25mhz)
    begin
        if rising_edge(clk_25mhz) then
            bird_on_d1     <= bird_on_raw;
            pipe_on_d1     <= pipe_on_raw;
            ground_on_d1   <= ground_on_raw;
            gift_on_d1     <= gift_on_raw;
            pipebody_on_d1 <= pipebody_on_raw;
        end if;
    end process;

    -- Synchronous layer routing for ROM sprites and chroma-key transparency.
    process(clk_25mhz)
    begin
        if rising_edge(clk_25mhz) then
            layers(background_layer).layer_on <= '1';
            layers(background_layer).rgb      <= "011";

            if ground_on_d1 = '1' and game_visible = '1' then
                layers(floor_layer).layer_on <= '1';
            else
                layers(floor_layer).layer_on <= '0';
            end if;
            layers(floor_layer).rgb <= ground_rgb;

            if gift_on_d1 = '1' and gift_rgb /= "101" and game_visible = '1' then
                layers(gift_layer).layer_on <= '1';
            else
                layers(gift_layer).layer_on <= '0';
            end if;
            layers(gift_layer).rgb <= gift_rgb;

            if bird_on_d1 = '1' and bird_rgb /= "101" and game_visible = '1' then
                layers(bird_layer).layer_on <= '1';
            else
                layers(bird_layer).layer_on <= '0';
            end if;
            layers(bird_layer).rgb <= bird_rgb;

            if pipe_on_d1 = '1' and game_visible = '1' then
                if pipebody_on_d1 = '1' then
                    layers(obstacle_layer).layer_on <= '1';
                    layers(obstacle_layer).rgb      <= "010";
                else
                    if pipecap_rgb /= "000" then
                        layers(obstacle_layer).layer_on <= '1';
                        layers(obstacle_layer).rgb      <= pipecap_rgb;
                    else
                        layers(obstacle_layer).layer_on <= '0';
                    end if;
                end if;
            else
                layers(obstacle_layer).layer_on <= '0';
            end if;
        end if;
    end process;
	 
	 -- Display layers
    game_visible <= '0' when (game_state = "00") else '1';

    -- Cursor and menu selection marker.
    process(pixel_col, pixel_row, mouse_col, mouse_row, game_state, selected_training)
        variable pc : integer;
        variable pr : integer;
        variable mx : integer;
        variable my : integer;
    begin
        pc := to_integer(unsigned(pixel_col));
        pr := to_integer(unsigned(pixel_row));
        mx := to_integer(unsigned(mouse_col));
        my := to_integer(unsigned(mouse_row));

        layers(cursor_layer).layer_on <= '0';

        if game_state = "00" then
            if pc >= mx and pc < mx + 12 and pr >= my and pr < my + 12 then
                layers(cursor_layer).layer_on <= '1';
            end if;

            if selected_training = '1' then
                if pc >= 238 and pc < 248 and pr >= 253 and pr < 263 then
                    layers(cursor_layer).layer_on <= '1';
                end if;
            else
                if pc >= 270 and pc < 280 and pr >= 303 and pr < 313 then
                    layers(cursor_layer).layer_on <= '1';
                end if;
            end if;
        end if;
    end process;

    layers(cursor_layer).rgb <= "111";

    layers(text_layer).layer_on <= text_combined;
    layers(text_layer).rgb      <= "111";

    -- Final pixel router.
    router_inst : entity work.display_pixel_router
        port map(
            layers => layers,
            vid_r  => vr,
            vid_g  => vg,
            vid_b  => vb
        );

    -- Seven-segment displays.
    seg_score0 : entity work.seven_seg
        port map(
            bcd_digit    => s_ones,
            sevenseg_out => hex0
        );

    seg_score1 : entity work.seven_seg
        port map(
            bcd_digit    => s_tens,
            sevenseg_out => hex1
        );

    seg_lvl : entity work.seven_seg
        port map(
            bcd_digit    => level_bcd,
            sevenseg_out => hex2
        );

    hex3 <= "1111111";
    hex4 <= "1111111";

    seg_lives : entity work.seven_seg
        port map(
            bcd_digit    => l_count,
            sevenseg_out => hex5
        );

    -- Debug LEDs.
    led(1 downto 0) <= game_state;
    led(2)          <= selected_training;
    led(3)          <= menu_train_hover;
    led(4)          <= menu_game_hover;
    led(5)          <= left_btn;
    led(6)          <= pipe_col or ground_col;
    led(7)          <= lives_zero;
    led(8)          <= reset_game;
    led(9)          <= sw(9);

end structural;