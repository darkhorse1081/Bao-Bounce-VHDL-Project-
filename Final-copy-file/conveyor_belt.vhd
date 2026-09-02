LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY conveyor_belt IS
    PORT(
        clk          : IN std_logic;
        vert_sync    : IN std_logic;
        game_state   : IN std_logic_vector(1 downto 0); 
        reset_level  : IN std_logic;
        
        current_lvl  : IN integer; 
        lfsr_rand    : IN std_logic_vector(7 downto 0);
        
        pixel_row    : IN std_logic_vector(9 downto 0);
        pixel_col    : IN std_logic_vector(9 downto 0);
        bird_y       : IN std_logic_vector(9 downto 0);
        
        pipe_on      : OUT std_logic;
        ground_on    : OUT std_logic;
        gift_on      : OUT std_logic;
        collision    : OUT std_logic;
        score_tick   : OUT std_logic;
        gift_tick    : OUT std_logic
    );
END conveyor_belt;

ARCHITECTURE behavior OF conveyor_belt IS
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
    -- LOGIC UPDATE: Runs once per frame (60Hz)
    PROCESS(clk, reset_level)
        VARIABLE speed : integer;
        VARIABLE b_y   : integer;
    BEGIN
        IF reset_level = '1' THEN
            pipes(0) <= (x => 640,  gap_y => 200, has_gift => '0');
            pipes(1) <= (x => 940,  gap_y => 150, has_gift => '1');
            pipes(2) <= (x => 1240, gap_y => 250, has_gift => '0');
            pipes(3) <= (x => 1540, gap_y => 100, has_gift => '1');
            vsync_prev <= '0';
            collision <= '0';
            score_tick <= '0';
            gift_tick <= '0';
            
        ELSIF rising_edge(clk) THEN
            vsync_prev <= vert_sync;
            
            -- Default pulse signals to 0 so they only fire for 1 clock cycle
            score_tick <= '0';
            gift_tick <= '0';
            collision <= '0';
            
            IF vert_sync = '1' AND vsync_prev = '0' AND game_state = "01" THEN
                speed := current_lvl + 1; 
                b_y := to_integer(unsigned(bird_y));
                
                -- Ground collision check
                IF (b_y + BIRD_S) >= 450 THEN collision <= '1'; END IF;

                FOR i IN 0 TO 3 LOOP
                    -- 1. Check for Score (Bird passes the pipe completely)
                    -- Using >= and - speed ensures we don't miss the exact pixel jump
                    IF (pipes(i).x + PIPE_W >= BIRD_X) AND (pipes(i).x + PIPE_W - speed < BIRD_X) THEN
                        score_tick <= '1';
                    END IF;

                    -- 2. Check Bird vs Pipe Collision (Mathematical Bounding Box)
                    IF (BIRD_X + BIRD_S > pipes(i).x) AND (BIRD_X < pipes(i).x + PIPE_W) THEN
                        IF b_y < pipes(i).gap_y OR (b_y + BIRD_S) > (pipes(i).gap_y + GAP_H) THEN
                            collision <= '1';
                        END IF;
                    END IF;

                    -- 3. Check Bird vs Gift 
                    IF pipes(i).has_gift = '1' THEN
                        IF (BIRD_X + BIRD_S > pipes(i).x + 15) AND (BIRD_X < pipes(i).x + 35) THEN
                            IF (b_y < pipes(i).gap_y + 80) AND (b_y + BIRD_S > pipes(i).gap_y + 60) THEN
                                pipes(i).has_gift <= '0'; 
                                gift_tick <= '1';
                            END IF;
                        END IF;
                    END IF;
                    
                    -- 4. Move pipe left
                    pipes(i).x <= pipes(i).x - speed;
                    IF pipes(i).x < -PIPE_W THEN
                        pipes(i).x <= 1150; 
                        pipes(i).gap_y <= 50 + to_integer(unsigned(lfsr_rand)); 
                        pipes(i).has_gift <= lfsr_rand(0); 
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END PROCESS;

    -- RENDERING SCANNER: Runs every pixel clock (25MHz)
    PROCESS(pixel_col, pixel_row, pipes)
        VARIABLE p_col : integer;
        VARIABLE p_row : integer;
        VARIABLE is_pipe, is_gift : std_logic;
    BEGIN
        p_col := to_integer(unsigned(pixel_col));
        p_row := to_integer(unsigned(pixel_row));
        is_pipe := '0'; is_gift := '0';

        FOR i IN 0 TO 3 LOOP
            IF p_col >= pipes(i).x AND p_col < (pipes(i).x + PIPE_W) THEN
                IF p_row < pipes(i).gap_y OR p_row > (pipes(i).gap_y + GAP_H) THEN
                    is_pipe := '1';
                END IF;
            END IF;
            
            IF pipes(i).has_gift = '1' THEN
                IF p_col >= (pipes(i).x + 15) AND p_col < (pipes(i).x + 35) THEN
                    IF p_row >= (pipes(i).gap_y + 60) AND p_row < (pipes(i).gap_y + 80) THEN
                        is_gift := '1';
                    END IF;
                END IF;
            END IF;
        END LOOP;
        
        pipe_on <= is_pipe;
        gift_on <= is_gift;
        
        -- CORRECTED IF/ELSE LOGIC
        IF p_row >= 450 THEN
            ground_on <= '1';
        ELSE
            ground_on <= '0';
        END IF;
        
    END PROCESS;
END behavior;