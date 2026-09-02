LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY bird_logic IS
    PORT(
        clk, vert_sync, mouse_click : IN std_logic;
        reset_pos    : IN std_logic;
        game_state   : IN std_logic_vector(1 downto 0);
        pixel_row, pixel_column     : IN std_logic_vector(9 DOWNTO 0);
        bird_on_out  : OUT std_logic;
        bird_y_out   : OUT std_logic_vector(9 downto 0) -- For collision
    );      
END bird_logic;

ARCHITECTURE behavior OF bird_logic IS
    SIGNAL size         : std_logic_vector(9 DOWNTO 0);  
    SIGNAL ball_y_pos   : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(240, 10);
    SIGNAL ball_x_pos   : std_logic_vector(10 DOWNTO 0);
    SIGNAL mouse_click_prev : std_logic := '0';
BEGIN           
    size <= CONV_STD_LOGIC_VECTOR(16, 10);
    ball_x_pos <= CONV_STD_LOGIC_VECTOR(320, 11);
    bird_y_out <= ball_y_pos;

    bird_on_out <= '1' WHEN (('0' & ball_x_pos <= '0' & pixel_column + size) AND 
                             ('0' & pixel_column <= '0' & ball_x_pos + size) AND 
                             ('0' & ball_y_pos <= pixel_row + size) AND 
                             ('0' & pixel_row <= ball_y_pos + size)) ELSE '0';

    Move_Ball: PROCESS (vert_sync, reset_pos)       
    BEGIN
        IF reset_pos = '1' THEN
            ball_y_pos <= CONV_STD_LOGIC_VECTOR(240, 10); -- Reset to center
            mouse_click_prev <= '0';
        ELSIF rising_edge(vert_sync) THEN
            mouse_click_prev <= mouse_click;
            
            -- Only move when Playing
            IF game_state = "01" THEN 
                IF mouse_click = '1' AND mouse_click_prev = '0' THEN
                    -- Flap
                    IF ball_y_pos > CONV_STD_LOGIC_VECTOR(40, 10) THEN
                         ball_y_pos <= ball_y_pos - CONV_STD_LOGIC_VECTOR(40, 10);
                    ELSE
                         ball_y_pos <= size;
                    END IF;
                ELSE
                    -- Gravity
                    IF ball_y_pos + size < CONV_STD_LOGIC_VECTOR(450, 10) THEN
                         ball_y_pos <= ball_y_pos + CONV_STD_LOGIC_VECTOR(3, 10);
                    ELSE
                         ball_y_pos <= CONV_STD_LOGIC_VECTOR(450, 10) - size;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS Move_Ball;
END behavior;