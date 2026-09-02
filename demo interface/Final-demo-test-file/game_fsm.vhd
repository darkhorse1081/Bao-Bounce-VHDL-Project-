library ieee;
use ieee.std_logic_1164.all;

entity game_fsm is
    port(
        clk             : in  std_logic;
        reset_btn       : in  std_logic;
        play_btn        : in  std_logic;
        pause_btn       : in  std_logic;
        collision_event : in  std_logic;
        lives_zero      : in  std_logic;
        state_out       : out std_logic_vector(1 downto 0);
        reset_game_sigs : out std_logic
    );
end game_fsm;

architecture behavior of game_fsm is

    type state_type is (main_menu, playing, paused, game_over);
    signal current_state, next_state : state_type := main_menu;

    signal play_prev, pause_prev   : std_logic := '0';
    signal play_pulse, pause_pulse : std_logic;

begin

    -- Edge-detect play and pause inputs so each press creates one transition pulse.
    process(clk)
    begin
        if rising_edge(clk) then
            play_prev  <= play_btn;
            pause_prev <= pause_btn;
        end if;
    end process;

    play_pulse  <= play_btn and not play_prev;
    pause_pulse <= pause_btn and not pause_prev;

    -- State register. Reset forces the game back to the main menu.
    process(clk, reset_btn)
    begin
        if reset_btn = '1' then
            current_state <= main_menu;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next-state and output logic.
    process(current_state, play_pulse, pause_pulse, lives_zero)
    begin
        next_state      <= current_state;
        reset_game_sigs <= '0';
        state_out       <= "00";

        case current_state is
            when main_menu =>
                state_out       <= "00";
                reset_game_sigs <= '1';

                if play_pulse = '1' then
                    next_state <= playing;
                end if;

            when playing =>
                state_out <= "01";

                if pause_pulse = '1' then
                    next_state <= paused;
                elsif lives_zero = '1' then
                    next_state <= game_over;
                end if;

            when paused =>
                state_out <= "10";

                if pause_pulse = '1' then
                    next_state <= playing;
                end if;

            when game_over =>
                state_out <= "11";

                if play_pulse = '1' then
                    next_state <= main_menu;
                end if;
        end case;
    end process;

end behavior;