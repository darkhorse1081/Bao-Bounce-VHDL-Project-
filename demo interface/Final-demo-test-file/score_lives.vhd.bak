LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY score_lives IS
    PORT(
        clk             : IN  std_logic;
        vert_sync       : IN  std_logic;
        reset_game      : IN  std_logic;
        game_state      : IN  std_logic_vector(1 downto 0);
        sw_training     : IN  std_logic; -- SW(9)
        
        score_tick      : IN  std_logic;
        gift_tick       : IN  std_logic;
        collision       : IN  std_logic;
        
        score_ones      : OUT std_logic_vector(3 downto 0);
        score_tens      : OUT std_logic_vector(3 downto 0);
        lives           : OUT std_logic_vector(3 downto 0);
        current_level   : OUT integer;
        lives_zero      : OUT std_logic
    );
END score_lives;

ARCHITECTURE behavior OF score_lives IS
    SIGNAL s_ones  : unsigned(3 downto 0) := "0000";
    SIGNAL s_tens  : unsigned(3 downto 0) := "0000";
    SIGNAL total_s : integer := 0;
    SIGNAL l_count : unsigned(3 downto 0) := "0011"; 
    SIGNAL cooldown_timer : integer := 0;
    SIGNAL vsync_prev : std_logic := '0';
BEGIN
    score_ones <= std_logic_vector(s_ones);
    score_tens <= std_logic_vector(s_tens);
    lives <= std_logic_vector(l_count);
    lives_zero <= '1' WHEN l_count = 0 ELSE '0';

    -- Level Calculation (Level 1, 2, or 3)
    -- If in Training Mode (SW9 = 1), lock to level 1.
    current_level <= 1 WHEN sw_training = '1' ELSE
                     1 WHEN total_s < 5 ELSE
                     2 WHEN total_s < 15 ELSE 
                     3;

    PROCESS(clk, reset_game) 
        VARIABLE points_to_add : integer := 0;
    BEGIN
        IF reset_game = '1' THEN
            s_ones <= "0000"; s_tens <= "0000"; total_s <= 0;
            l_count <= "0011"; cooldown_timer <= 0; vsync_prev <= '0';
            
        ELSIF rising_edge(clk) THEN
            vsync_prev <= vert_sync;
            
            IF game_state = "01" THEN
                IF vert_sync = '1' AND vsync_prev = '0' THEN
                    IF cooldown_timer > 0 THEN cooldown_timer <= cooldown_timer - 1; END IF;
                    
                    points_to_add := 0;
                    IF score_tick = '1' THEN points_to_add := points_to_add + 1; END IF;
                    IF gift_tick = '1' THEN points_to_add := points_to_add + 2; END IF; -- Gift = 2 points
                    
                    IF points_to_add > 0 THEN
                        total_s <= total_s + points_to_add;
                        -- BCD Counter logic
                        IF (s_ones + points_to_add) > 9 THEN
                            s_ones <= (s_ones + points_to_add) - 10;
                            IF s_tens < 9 THEN s_tens <= s_tens + 1; END IF;
                        ELSE
                            s_ones <= s_ones + points_to_add;
                        END IF;
                    END IF;
                END IF;
                
                -- Collision Damage
                IF collision = '1' AND cooldown_timer = 0 THEN
                    IF l_count > 0 THEN l_count <= l_count - 1; END IF;
                    cooldown_timer <= 60; 
                END IF;
            END IF;
        END IF;
    END PROCESS;
END behavior;