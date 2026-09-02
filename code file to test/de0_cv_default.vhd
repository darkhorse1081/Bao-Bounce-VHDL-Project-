LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity de0_cv_default is
    port(
        -- clock & reset from de0-cv board
        clock_50    : in std_logic;
        reset_n     : in std_logic;
        sw : in std_logic_vector(9 downto 0);
        key : in std_logic_vector(3 downto 0);
        
        -- user i/o 
        -- sw          : in std_logic_vector(9 downto 0);
        hex0, hex1, hex2, hex3, hex4, hex5 : out std_logic_vector(6 downto 0);
        led : out std_logic_vector(9 downto 0);

        
        
        -- vga outputs 
        vga_r       : out std_logic_vector(3 downto 0);
        vga_g       : out std_logic_vector(3 downto 0);
        vga_b       : out std_logic_vector(3 downto 0);
        vga_hs      : out std_logic;
        vga_vs      : out std_logic;
        
        -- ps/2 mouse 
        ps2_clk     : inout std_logic;
        ps2_dat     : inout std_logic
    );
end de0_cv_default;

architecture structural of de0_cv_default is

    -- internal system signals
    signal clk_25mhz      : std_logic;
    signal reset_sys      : std_logic;

    -- mouse signals
    signal mouse_row      : std_logic_vector(9 downto 0);
    signal mouse_col      : std_logic_vector(9 downto 0);
    signal left_btn, right_btn : std_logic;

    -- vga sync & routing signals 
    signal pixel_row      : std_logic_vector(9 downto 0);
    signal pixel_col      : std_logic_vector(9 downto 0);
    
    signal mux_red        : std_logic;
    signal mux_green      : std_logic;
    signal mux_blue       : std_logic;
    
    signal vga_red_out    : std_logic;
    signal vga_green_out  : std_logic;
    signal vga_blue_out   : std_logic;
	 signal vga_vert_sync  : std_logic;

    -- graphics pipeline signals
    signal wire_bird_on   : std_logic;
    signal wire_bird_rgb  : std_logic_vector(2 downto 0);
    signal wire_text_on   : std_logic;
    signal wire_text_rgb  : std_logic_vector(2 downto 0);
	 signal wire_sprite_on   : std_logic;
    signal wire_sprite_rgb  : std_logic_vector(2 downto 0);
	 
	 signal text_on_1, text_on_2, text_on_3 : std_logic;
	 signal text_rgb_1, text_rgb_2, text_rgb_3 : std_logic_vector(2 downto 0);
	 
	 signal text_x_1, text_y_1 : std_logic_vector(9 downto 0);
	 signal text_x_2, text_y_2 : std_logic_vector(9 downto 0);
	 signal text_x_3, text_y_3 : std_logic_vector(9 downto 0);
	 
	 signal text_on_training, text_on_game : std_logic;
	 signal text_rgb_training, text_rgb_game : std_logic_vector(2 downto 0);
	 
	 signal bird_rgb        : std_logic_vector(2 downto 0);
	 signal bird_on         : std_logic;
	 signal bird_red        : std_logic;
    signal bird_green      : std_logic;
    signal bird_blue       : std_logic;
	 
	 signal ball_red, ball_green, ball_blue : std_logic;
	 signal ball_rgb : std_logic_vector(2 downto 0);
	 signal ball_on  : std_logic;
	 
	 

    -- component declarations

    component clk25_gen is
        port ( clk_50 : in std_logic; clk_25 : out std_logic );
    end component;

    component vga_sync is
        port( clock_25mhz, red, green, blue : in std_logic;
              red_out, green_out, blue_out, horiz_sync_out, vert_sync_out : out std_logic;
              pixel_row, pixel_column : out std_logic_vector(9 downto 0));
    end component;

    component mouse is
        port( clock_25mhz, reset : in std_logic;
              mouse_data, mouse_clk : inout std_logic;
              left_button, right_button : out std_logic;
              mouse_cursor_row, mouse_cursor_column : out std_logic_vector(9 downto 0));       	
    end component;
	 
	 component bird_logic is
        PORT( pb1, pb2, clk, vert_sync, mouse_click	: IN std_logic;
              pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		        red, green, blue, bird_on_out 			: OUT std_logic);       	
    end component;
	 
	 component bouncy_ball is
        PORT( pb1, pb2, clk, vert_sync	: IN std_logic;
              pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		        red, green, blue 			: OUT std_logic);       	
    end component;

    -- text engine 
    component text_engine is
		  generic (text_to_print : string);
        port( clk_25mhz : in std_logic;
              pixel_row, pixel_col : in std_logic_vector(9 downto 0);
              position_x : in  std_logic_vector(9 downto 0);
				  position_y : in  std_logic_vector(9 downto 0);
              text_scale : in  std_logic_vector(1 downto 0);
              text_on : out std_logic; text_rgb : out std_logic_vector(2 downto 0));
    end component;

    component seven_seg is
        port( BCD_digit : in std_logic_vector(3 downto 0); SevenSeg_out : out std_logic_vector(6 downto 0));
    end component;

begin

    -- 1. system control logic
    -- convert active-low push button to active-high logic
    reset_sys <= not reset_n;

    clk_inst : clk25_gen 
        port map ( clk_50 => clock_50, clk_25 => clk_25mhz );

    -- 2. input layer 
    mouse_inst : mouse 
        port map (
            clock_25mhz => clk_25mhz,
				reset => reset_sys,
            mouse_data => ps2_dat,
				mouse_clk => ps2_clk,
            left_button => left_btn, 
				right_button => right_btn,
            mouse_cursor_row => mouse_row,
				mouse_cursor_column => mouse_col
        );

    -- 3. graphics layer (your focus: role a)
    -- new sprite rasterizer (the bird)
    sprite_inst : entity work.sprite_rasterizer
        port map (
            scan_coord_y  => pixel_row,      -- from vga_sync
            scan_coord_x  => pixel_col,      -- from vga_sync
            entity_base_y => mouse_row,
				entity_base_x => mouse_col,
            render_flag   => wire_bird_on,   
            output_chroma => wire_bird_rgb   
        );
	 
    -- text engine (needs the module provided earlier)
    text_training : text_engine
		 generic map (text_to_print => "TRAINING")
		 port map (
			  clk_25mhz  => clk_25mhz,
			  pixel_row  => pixel_row,
			  pixel_col  => pixel_col,
			  position_x => text_x_1,
			  position_y => text_y_1,
			  text_scale => "01",
			  text_on    => text_on_training,
			  text_rgb   => text_rgb_training
		 );

	 text_game : text_engine
		 generic map (text_to_print => "GAME")
		 port map (
			  clk_25mhz  => clk_25mhz,
			  pixel_row  => pixel_row,
			  pixel_col  => pixel_col,
			  position_x => text_x_1,
			  position_y => text_y_1,
			  text_scale => "01",
			  text_on    => text_on_game,
			  text_rgb   => text_rgb_game
		 );
		
	 text_inst_2 : text_engine
		  generic map (
			  text_to_print => "Hello World"
		  )
        port map (
            clk_25mhz     => clk_25mhz,
            pixel_row     => pixel_row,
            pixel_col     => pixel_col,
            position_x => text_x_2,
				position_y => text_y_2,
				text_scale => "10",
				text_on    => text_on_2,
				text_rgb   => text_rgb_2
        );
		  
	 text_inst_3 : text_engine
		  generic map (
			  text_to_print => "Hello"
		  )
        port map (
            clk_25mhz     => clk_25mhz,
            pixel_row     => pixel_row,
            pixel_col     => pixel_col,
            position_x => text_x_3,
				position_y => text_y_3,
				text_scale => "11",
				text_on    => text_on_3,
				text_rgb   => text_rgb_3
        );

    -- display pixel router (the mux)
    router_inst : entity work.display_pixel_router
        port map (
            sprite_active  => wire_sprite_on,  
            sprite_chroma  => wire_sprite_rgb,
            overlay_active => wire_text_on,  
            overlay_chroma => wire_text_rgb, 
            base_chroma    => sw(2 downto 0), -- sw0,1,2 change background!
            vid_r          => mux_red,        
            vid_g          => mux_green,      
            vid_b          => mux_blue        
        );

    -- 4. hardware sync (provided module)
    vga_sync_inst : vga_sync 
        port map(
            clock_25mhz => clk_25mhz,
            red => mux_red, green => mux_green, blue => mux_blue,
            red_out => vga_red_out, green_out => vga_green_out, blue_out => vga_blue_out,
            horiz_sync_out => vga_hs, vert_sync_out => vga_vert_sync,
            pixel_row => pixel_row, pixel_column => pixel_col
        );
		 
	 bird_inst : bird_logic
        port map (
            pb1 => not key(0),
            pb2 => not key(1),   
            clk => clk_25mhz,
            vert_sync => vga_vert_sync,
				mouse_click => left_btn,
				pixel_row => pixel_row,
				pixel_column => pixel_col,
            red => bird_red,
				green => bird_green,
				blue => bird_blue,
				bird_on_out => bird_on
        );
		  
	 ball_inst : bouncy_ball
		 port map (
			  pb1 => not key(0),
			  pb2 => not key(1),
			  clk => clk_25mhz,
			  vert_sync => vga_vert_sync,
			  pixel_row => pixel_row,
			  pixel_column => pixel_col,
			  red => ball_red,
			  green => ball_green,
			  blue => ball_blue
		 );

    -- drive the 4-bit de0-cv vga dac
    vga_r <= vga_red_out & vga_red_out & vga_red_out & vga_red_out;
    vga_g <= vga_green_out & vga_green_out & vga_green_out & vga_green_out;
    vga_b <= vga_blue_out & vga_blue_out & vga_blue_out & vga_blue_out;
	 vga_vs <= vga_vert_sync;
	 
	 bird_rgb <= bird_red & bird_green & bird_blue;
	 ball_rgb <= ball_red & ball_green & ball_blue;
	 ball_on  <= ball_red or ball_green or ball_blue;
	 
	 text_on_1  <= text_on_training  when sw(9) = '1' else text_on_game;
	 text_rgb_1 <= text_rgb_training when sw(9) = '1' else text_rgb_game;
	 
	 wire_sprite_on <= bird_on or ball_on;
	 wire_sprite_rgb <=
		 bird_rgb when bird_on = '1' else
		 ball_rgb when ball_on = '1' else
		 "000";

	 wire_text_on <= text_on_1 or text_on_2 or text_on_3;
	 wire_text_rgb <= 
		 text_rgb_1 when text_on_1 = '1' else
		 text_rgb_2 when text_on_2 = '1' else
		 text_rgb_3;
	 
	 text_x_1 <= std_logic_vector(to_unsigned(240, 10));
	 text_y_1 <= std_logic_vector(to_unsigned(10, 10));

	 text_x_2 <= std_logic_vector(to_unsigned(340, 10));
	 text_y_2 <= std_logic_vector(to_unsigned(150, 10));

	 text_x_3 <= std_logic_vector(to_unsigned(340, 10));
	 text_y_3 <= std_logic_vector(to_unsigned(250, 10));

    led(9 downto 5) <= sw(9 downto 5);
	 led(3 downto 0) <= not key;
	 led(4) <= left_btn;
	 

    -- debugging output
    -- displaying mouse x-coordinate
    seg_x0: seven_seg port map(BCD_digit => mouse_col(3 downto 0), SevenSeg_out => hex0);
    seg_x1: seven_seg port map(BCD_digit => mouse_col(7 downto 4), SevenSeg_out => hex1);
    seg_x2: seven_seg port map(BCD_digit => "00" & mouse_col(9 downto 8), SevenSeg_out => hex2);

    -- displaying mouse y-coordinate
    seg_y0: seven_seg port map(BCD_digit => mouse_row(3 downto 0), SevenSeg_out => hex3);
    seg_y1: seven_seg port map(BCD_digit => mouse_row(7 downto 4), SevenSeg_out => hex4);
    seg_y2: seven_seg port map(BCD_digit => "00" & mouse_row(9 downto 8), SevenSeg_out => hex5);

end structural; 