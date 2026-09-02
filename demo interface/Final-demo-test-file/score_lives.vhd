library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity score_lives is
    port(
        clk           : in  std_logic;
        vert_sync     : in  std_logic;
        reset_game    : in  std_logic;
        game_state    : in  std_logic_vector(1 downto 0);
        sw_training   : in  std_logic;

        score_tick    : in  std_logic;
        gift_tick     : in  std_logic;
        ground_col    : in  std_logic;
        pipe_col      : in  std_logic;

        score_ones    : out std_logic_vector(3 downto 0);
        score_tens    : out std_logic_vector(3 downto 0);
        lives         : out std_logic_vector(3 downto 0);
        current_level : out integer;
        lives_zero    : out std_logic
    );
end score_lives;

architecture behavior of score_lives is

    signal s_ones        : unsigned(3 downto 0) := "0000";
    signal s_tens        : unsigned(3 downto 0) := "0000";
    signal total_s       : integer := 0;
    signal l_count       : unsigned(3 downto 0) := "0011";
    signal cooldown_timer : integer := 0;
    signal vsync_prev    : std_logic := '0';

begin

    score_ones <= std_logic_vector(s_ones);
    score_tens <= std_logic_vector(s_tens);
    lives      <= std_logic_vector(l_count);

    lives_zero <= '1' when l_count = 0 else '0';

    -- Training mode stays on level 1. Game mode increases level based on score.
    current_level <= 1 when sw_training = '1' else
                     1 when total_s < 5 else
                     2 when total_s < 15 else
                     3;

    process(clk, reset_game)
        variable points_to_add : integer := 0;
    begin
        if reset_game = '1' then
            s_ones        <= "0000";
            s_tens        <= "0000";
            total_s       <= 0;
            l_count       <= "0011";
            cooldown_timer <= 0;
            vsync_prev    <= '0';

        elsif rising_edge(clk) then
            vsync_prev <= vert_sync;

            if game_state = "01" then

                -- Score and cooldown update once per frame.
                if vert_sync = '1' and vsync_prev = '0' then
                    if cooldown_timer > 0 then
                        cooldown_timer <= cooldown_timer - 1;
                    end if;

                    points_to_add := 0;

                    if score_tick = '1' then
                        points_to_add := points_to_add + 1;
                    end if;

                    if gift_tick = '1' then
                        points_to_add := points_to_add + 2;
                    end if;

                    if points_to_add > 0 then
                        total_s <= total_s + points_to_add;

                        if (s_ones + points_to_add) > 9 then
                            s_ones <= (s_ones + points_to_add) - 10;

                            if s_tens < 9 then
                                s_tens <= s_tens + 1;
                            end if;
                        else
                            s_ones <= s_ones + points_to_add;
                        end if;
                    end if;
                end if;

                -- Pipe collision removes one life after cooldown; ground collision ends the run.
                if pipe_col = '1' and cooldown_timer = 0 then
                    if l_count > 0 then
                        l_count <= l_count - 1;
                    end if;

                    cooldown_timer <= 60;

                elsif ground_col = '1' then
                    l_count <= "0000";
                end if;

            end if;
        end if;
    end process;

end behavior;