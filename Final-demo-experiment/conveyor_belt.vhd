LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY conveyor_belt IS
    PORT(
        clk          : IN std_logic;
        vert_sync    : IN std_logic;
        game_state   : IN std_logic_vector(1 downto 0); 
        reset_level  : IN std_logic;
        
        -- Game Mechanics
        current_lvl  : IN integer; 
        lfsr_rand    : IN std_logic_vector(7 downto 0);
        
        -- Rendering Inputs
        pixel_row    : IN std_logic_vector(9 downto 0);
        pixel_col    : IN std_logic_vector(9 downto 0);
        bird_y       : IN std_logic_vector(9 downto 0);
        
        -- Outputs
        pipe_on      : OUT std_logic;
        ground_on    : OUT std_logic;
        gift_on      : OUT std_logic;
        collision    : OUT std_logic;
        score_tick   : OUT std_logic;
        gift_tick    : OUT std_logic;
        ground_addr  : OUT std_logic_vector(7 downto 0);
        gift_addr    : OUT std_logic_vector(8 downto 0);
        pipecap_addr : OUT std_logic_vector(9 downto 0);
        pipebody_on  : OUT std_logic
    );
END conveyor_belt;

ARCHITECTURE behavior OF conveyor_belt IS
    -- Array of 4 pipes acts as a treadmill
    TYPE pipe_record IS RECORD
        x         : integer;
        gap_y     : integer;
        has_gift  : std_logic;
    END RECORD;
    TYPE pipe_array IS ARRAY (0 TO 3) OF pipe_record;
    
    SIGNAL pipes : pipe_array;
    
    CONSTANT PIPE_W : integer := 50;
    CONSTANT GAP_H  : integer := 130;
    CONSTANT BIRD_X : integer := 320;
    CONSTANT BIRD_S : integer := 16;
    
    SIGNAL vsync_prev : std_logic := '0';
BEGIN

    -- TREADMILL UPDATE PROCESS
    PROCESS(clk, reset_level)
        VARIABLE speed : integer;
    BEGIN
        IF reset_level = '1' THEN
            -- Initial Map
            pipes(0) <= (x => 640,  gap_y => 200, has_gift => '0');
            pipes(1) <= (x => 940,  gap_y => 150, has_gift => '1');
            pipes(2) <= (x => 1240, gap_y => 250, has_gift => '0');
            pipes(3) <= (x => 1540, gap_y => 100, has_gift => '1');
            vsync_prev <= '0';
            
        ELSIF rising_edge(clk) THEN
            vsync_prev <= vert_sync;
            
            IF vert_sync = '1' AND vsync_prev = '0' AND game_state = "01" THEN
                -- Speed based on level (1, 2, or 3)
                speed := current_lvl + 1; 
                
                FOR i IN 0 TO 3 LOOP
                    -- Move pipe left
                    pipes(i).x <= pipes(i).x - speed;
                    
                    -- If pipe moves off screen, teleport to back & randomize!
                    IF pipes(i).x < -PIPE_W THEN
                        pipes(i).x <= 1150; -- Spacing behind last pipe
                        -- LFSR maps 0-255 to Gap Y (50 to 305)
                        pipes(i).gap_y <= 50 + to_integer(unsigned(lfsr_rand)); 
                        pipes(i).has_gift <= lfsr_rand(0); -- Randomly spawn gift
                    END IF;
                    
                    -- Check Gift Collection
                    IF pipes(i).has_gift = '1' THEN
                        IF (BIRD_X + BIRD_S > pipes(i).x + 15) AND (BIRD_X < pipes(i).x + 35) THEN
                            IF (to_integer(unsigned(bird_y)) < pipes(i).gap_y + 80) AND (to_integer(unsigned(bird_y)) + BIRD_S > pipes(i).gap_y + 60) THEN
                                pipes(i).has_gift <= '0'; -- Consume gift
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END PROCESS;

    -- RENDERING & COLLISION LOGIC
    PROCESS(pixel_col, pixel_row, pipes, bird_y)
        VARIABLE p_col : integer;
        VARIABLE p_row : integer;
        VARIABLE b_y   : integer;
        
        VARIABLE is_pipe, is_gift, is_col, s_tick, g_tick, p_body : std_logic;
        VARIABLE y_rel, x_rel : integer;
    BEGIN
        p_col := to_integer(unsigned(pixel_col));
        p_row := to_integer(unsigned(pixel_row));
        b_y   := to_integer(unsigned(bird_y));
        
        is_pipe := '0'; is_gift := '0'; is_col := '0';
        s_tick  := '0'; g_tick  := '0'; p_body := '0';
        
        pipecap_addr <= (others => '0'); gift_addr <= (others => '0');

        FOR i IN 0 TO 3 LOOP
            -- DRAW PIPE AND CALCULATE SPRITE OFFSETS
            IF p_col >= pipes(i).x AND p_col < (pipes(i).x + PIPE_W) THEN
                x_rel := p_col - pipes(i).x;
                
                IF p_row >= (pipes(i).gap_y - 16) AND p_row < pipes(i).gap_y THEN
                    is_pipe := '1'; -- Top Pipe Cap
                    y_rel := p_row - (pipes(i).gap_y - 16);
                    pipecap_addr <= std_logic_vector(to_unsigned(y_rel * 50 + x_rel, 10));
                ELSIF p_row >= (pipes(i).gap_y + GAP_H) AND p_row < (pipes(i).gap_y + GAP_H + 16) THEN
                    is_pipe := '1'; -- Bottom Pipe Cap
                    y_rel := p_row - (pipes(i).gap_y + GAP_H);
                    pipecap_addr <= std_logic_vector(to_unsigned(y_rel * 50 + x_rel, 10));
                ELSIF p_row < (pipes(i).gap_y - 16) OR p_row >= (pipes(i).gap_y + GAP_H + 16) THEN
                    is_pipe := '1'; -- Solid Pipe Body
                    p_body := '1';
                END IF;
            END IF;
            
            -- DRAW GIFT AND CALCULATE SPRITE OFFSETS
            IF pipes(i).has_gift = '1' THEN
                IF p_col >= (pipes(i).x + 15) AND p_col < (pipes(i).x + 35) THEN
                    IF p_row >= (pipes(i).gap_y + 60) AND p_row < (pipes(i).gap_y + 80) THEN
                        is_gift := '1';
                        y_rel := p_row - (pipes(i).gap_y + 60);
                        x_rel := p_col - (pipes(i).x + 15);
                        gift_addr <= std_logic_vector(to_unsigned(y_rel * 20 + x_rel, 9));
                    END IF;
                END IF;
            END IF;
            
            -- BIRD VS PIPE COLLISION
            IF (BIRD_X + BIRD_S > pipes(i).x) AND (BIRD_X < pipes(i).x + PIPE_W) THEN
                IF b_y < pipes(i).gap_y OR (b_y + BIRD_S) > (pipes(i).gap_y + GAP_H) THEN
                    is_col := '1';
                END IF;
            END IF;
            
            -- BIRD VS GIFT COLLISION (Triggers once)
            IF pipes(i).has_gift = '1' THEN
                IF (BIRD_X + BIRD_S > pipes(i).x + 15) AND (BIRD_X < pipes(i).x + 35) THEN
                    IF b_y < (pipes(i).gap_y + 80) AND (b_y + BIRD_S) > (pipes(i).gap_y + 60) THEN
                        g_tick := '1';
                    END IF;
                END IF;
            END IF;

            -- SCORE TICK (Bird passes pipe)
            IF (BIRD_X = pipes(i).x + PIPE_W) THEN
                s_tick := '1';
            END IF;
        END LOOP;
        
        -- GROUND
-- GROUND
        IF p_row >= 450 THEN
            ground_on <= '1';
            -- Quick math for 16x16 tiling using the lowest 4 bits
            ground_addr <= std_logic_vector(to_unsigned(p_row - 450, 4)) & std_logic_vector(to_unsigned(p_col, 4));
            IF (b_y + BIRD_S) >= 450 THEN is_col := '1'; END IF;
        ELSE
            ground_on <= '0';
        END IF;
        
        pipebody_on <= p_body; -- Add this at the bottom!
        
        pipe_on <= is_pipe;
        gift_on <= is_gift;
        collision <= is_col;
        score_tick <= s_tick;
        gift_tick <= g_tick;
    END PROCESS;
END behavior;