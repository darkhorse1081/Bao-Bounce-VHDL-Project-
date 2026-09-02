LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY game_fsm IS
    PORT(
        clk             : IN  std_logic;
        reset_btn       : IN  std_logic; -- Returns to Menu
        play_btn        : IN  std_logic; -- Starts game
        pause_btn       : IN  std_logic; -- Pauses/Resumes
        collision_event : IN  std_logic;
        lives_zero      : IN  std_logic;
        state_out       : OUT std_logic_vector(1 downto 0); -- 00:Menu, 01:Play, 10:Pause, 11:GameOver
        reset_game_sigs : OUT std_logic  -- Tells other modules to reset positions/scores
    );
END game_fsm;

ARCHITECTURE behavior OF game_fsm IS
    TYPE state_type IS (MAIN_MENU, PLAYING, PAUSED, GAME_OVER);
    SIGNAL current_state, next_state : state_type := MAIN_MENU;
    
    -- Edge detection for buttons
    SIGNAL play_prev, pause_prev : std_logic := '0';
    SIGNAL play_pulse, pause_pulse : std_logic;
BEGIN
    -- Edge detectors for pushbuttons
    PROCESS(clk) BEGIN
        IF rising_edge(clk) THEN
            play_prev <= play_btn;
            pause_prev <= pause_btn;
        END IF;
    END PROCESS;
    play_pulse <= play_btn AND NOT play_prev;
    pause_pulse <= pause_btn AND NOT pause_prev;

    -- State Register
    PROCESS(clk, reset_btn) BEGIN
        IF reset_btn = '1' THEN
            current_state <= MAIN_MENU;
        ELSIF rising_edge(clk) THEN
            current_state <= next_state;
        END IF;
    END PROCESS;

    -- Next State Logic
    PROCESS(current_state, play_pulse, pause_pulse, lives_zero) BEGIN
        next_state <= current_state;
        reset_game_sigs <= '0';
        state_out <= "00";

        CASE current_state IS
            WHEN MAIN_MENU =>
                state_out <= "00";
                reset_game_sigs <= '1'; -- Hold game components in reset
                IF play_pulse = '1' THEN
                    next_state <= PLAYING;
                END IF;

            WHEN PLAYING =>
                state_out <= "01";
                IF pause_pulse = '1' THEN
                    next_state <= PAUSED;
                ELSIF lives_zero = '1' THEN
                    next_state <= GAME_OVER;
                END IF;

            WHEN PAUSED =>
                state_out <= "10";
                IF pause_pulse = '1' THEN
                    next_state <= PLAYING;
                END IF;

            WHEN GAME_OVER =>
                state_out <= "11";
                IF play_pulse = '1' THEN
                    next_state <= MAIN_MENU;
                END IF;
        END CASE;
    END PROCESS;
END behavior;