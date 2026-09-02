LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY display_pixel_router IS
    PORT(
        game_state   : IN std_logic_vector(1 downto 0);
        sw_training  : IN std_logic;
        
        text_menu_on : IN std_logic;
        text_play_on : IN std_logic;
        text_over_on : IN std_logic;
        
        bird_on      : IN std_logic;
        pipe_on      : IN std_logic;
        ground_on    : IN std_logic;
        gift_on      : IN std_logic;
        
        -- Expanded to 4-bits per channel for rich colors
        vid_r        : OUT std_logic_vector(3 downto 0);
        vid_g        : OUT std_logic_vector(3 downto 0);
        vid_b        : OUT std_logic_vector(3 downto 0)
    );
END display_pixel_router;

ARCHITECTURE behavior OF display_pixel_router IS
BEGIN
    PROCESS(game_state, sw_training, text_menu_on, text_play_on, text_over_on, bird_on, pipe_on, ground_on, gift_on)
    BEGIN
        -- Default Background Colors based on State/Mode
        IF game_state = "00" THEN
            -- Main Menu: Dark Blue
            vid_r <= "0000"; vid_g <= "0010"; vid_b <= "1000";
        ELSIF sw_training = '1' THEN
            -- Training Mode: Red Background
            vid_r <= "1000"; vid_g <= "0000"; vid_b <= "0000";
        ELSE
            -- Single Player Mode: Sky Blue Background
            vid_r <= "0101"; vid_g <= "1010"; vid_b <= "1111";
        END IF;

        -- Priority 1: Text Overlays (White)
        IF (text_menu_on = '1' AND game_state = "00") OR 
           (text_play_on = '1' AND (game_state = "01" OR game_state = "10")) OR
           (text_over_on = '1' AND game_state = "11") THEN
            vid_r <= "1111"; vid_g <= "1111"; vid_b <= "1111";
            
        -- Priority 2: Game Objects (Only visible if not in Menu)
        ELSIF game_state /= "00" THEN
            IF bird_on = '1' THEN
                -- Yellow Bird
                vid_r <= "1111"; vid_g <= "1111"; vid_b <= "0000";
            ELSIF gift_on = '1' THEN
                -- Magenta Gift
                vid_r <= "1111"; vid_g <= "0000"; vid_b <= "1111";
            ELSIF pipe_on = '1' THEN
                -- Green Pipe
                vid_r <= "0000"; vid_g <= "1111"; vid_b <= "0000";
            ELSIF ground_on = '1' THEN
                -- Brown Ground
                vid_r <= "1000"; vid_g <= "0100"; vid_b <= "0000";
            END IF;
        END IF;
    END PROCESS;
END behavior;