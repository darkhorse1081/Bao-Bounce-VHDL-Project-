library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conveyor_belt is
    port(
        clk           : in  std_logic;
        vert_sync     : in  std_logic;
        game_state    : in  std_logic_vector(1 downto 0);
        reset_level   : in  std_logic;

        current_lvl   : in  integer;
        bounce_active : in  std_logic;
        lfsr_rand     : in  std_logic_vector(7 downto 0);

        pixel_row     : in  std_logic_vector(9 downto 0);
        pixel_col     : in  std_logic_vector(9 downto 0);
        bird_y        : in  std_logic_vector(9 downto 0);

        pipe_on       : out std_logic;
        ground_on     : out std_logic;
        gift_on       : out std_logic;
        pipe_col      : out std_logic;
        ground_col    : out std_logic;
        score_tick    : out std_logic;
        gift_tick     : out std_logic;
        ground_addr   : out std_logic_vector(7 downto 0);
        gift_addr     : out std_logic_vector(8 downto 0);
        pipecap_addr  : out std_logic_vector(9 downto 0);
        pipebody_on   : out std_logic
    );
end conveyor_belt;

architecture behavior of conveyor_belt is

    type pipe_record is record
        x        : integer;
        gap_y    : integer;
        has_gift : std_logic;
    end record;

    type pipe_array is array (0 to 3) of pipe_record;

    signal pipes      : pipe_array;
    signal vsync_prev : std_logic := '0';

    constant pipe_w : integer := 50;
    constant gap_h  : integer := 130;
    constant bird_x : integer := 320;
    constant bird_s : integer := 16;

begin

    process(clk, reset_level)
        variable speed : integer;
    begin
        if reset_level = '1' then
            pipes(0) <= (x => 640,  gap_y => 200, has_gift => '0');
            pipes(1) <= (x => 940,  gap_y => 150, has_gift => '1');
            pipes(2) <= (x => 1240, gap_y => 250, has_gift => '0');
            pipes(3) <= (x => 1540, gap_y => 100, has_gift => '1');
            vsync_prev <= '0';

        elsif rising_edge(clk) then
            vsync_prev <= vert_sync;

            if vert_sync = '1' and vsync_prev = '0' and game_state = "01" then
                speed := current_lvl + 1;

                for i in 0 to 3 loop
                    if bounce_active = '1' then
                        pipes(i).x <= pipes(i).x + (speed * 3);
                    else
                        pipes(i).x <= pipes(i).x - speed;
                    end if;

                    if pipes(i).x < -pipe_w then
                        pipes(i).x        <= 1150;
                        pipes(i).gap_y    <= 50 + to_integer(unsigned(lfsr_rand));
                        pipes(i).has_gift <= lfsr_rand(0);
                    end if;

                    if pipes(i).has_gift = '1' then
                        if (bird_x + bird_s > pipes(i).x + 15) and
                           (bird_x < pipes(i).x + 35) then

                            if (to_integer(unsigned(bird_y)) < pipes(i).gap_y + 80) and
                               (to_integer(unsigned(bird_y)) + bird_s > pipes(i).gap_y + 60) then
                                pipes(i).has_gift <= '0';
                            end if;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    process(pixel_col, pixel_row, pipes, bird_y)
        variable p_col         : integer;
        variable p_row         : integer;
        variable b_y           : integer;

        variable is_pipe       : std_logic;
        variable is_gift       : std_logic;
        variable is_col_pipe   : std_logic;
        variable is_col_ground : std_logic;
        variable s_tick        : std_logic;
        variable g_tick        : std_logic;
        variable p_body        : std_logic;

        variable y_rel         : integer;
        variable x_rel         : integer;
    begin
        p_col := to_integer(unsigned(pixel_col));
        p_row := to_integer(unsigned(pixel_row));
        b_y   := to_integer(unsigned(bird_y));
        is_pipe       := '0';
        is_gift       := '0';
        is_col_pipe   := '0';
        is_col_ground := '0';
        s_tick        := '0';
        g_tick        := '0';
        p_body        := '0';

        pipecap_addr <= (others => '0');
        gift_addr    <= (others => '0');

        for i in 0 to 3 loop
            if p_col >= pipes(i).x and p_col < (pipes(i).x + pipe_w) then
                x_rel := p_col - pipes(i).x;

                if p_row >= (pipes(i).gap_y - 16) and p_row < pipes(i).gap_y then
                    is_pipe := '1';
                    y_rel := p_row - (pipes(i).gap_y - 16);
                    pipecap_addr <= std_logic_vector(to_unsigned(y_rel * 50 + x_rel, 10));

                elsif p_row >= (pipes(i).gap_y + gap_h) and
                      p_row <  (pipes(i).gap_y + gap_h + 16) then
                    is_pipe := '1';
                    y_rel := p_row - (pipes(i).gap_y + gap_h);
                    pipecap_addr <= std_logic_vector(to_unsigned(y_rel * 50 + x_rel, 10));

                elsif p_row < (pipes(i).gap_y - 16) or
                      p_row >= (pipes(i).gap_y + gap_h + 16) then
                    is_pipe := '1';
                    p_body  := '1';
                end if;
            end if;

            if pipes(i).has_gift = '1' then
                if p_col >= (pipes(i).x + 15) and p_col < (pipes(i).x + 35) then
                    if p_row >= (pipes(i).gap_y + 60) and p_row < (pipes(i).gap_y + 80) then
                        is_gift := '1';
                        y_rel := p_row - (pipes(i).gap_y + 60);
                        x_rel := p_col - (pipes(i).x + 15);
                        gift_addr <= std_logic_vector(to_unsigned(y_rel * 20 + x_rel, 9));
                    end if;
                end if;
            end if;

            if (bird_x + bird_s > pipes(i).x) and
               (bird_x < pipes(i).x + pipe_w) then

                if b_y < pipes(i).gap_y or
                   (b_y + bird_s) > (pipes(i).gap_y + gap_h) then
                    is_col_pipe := '1';
                end if;
            end if;

            if pipes(i).has_gift = '1' then
                if (bird_x + bird_s > pipes(i).x + 15) and
                   (bird_x < pipes(i).x + 35) then

                    if b_y < (pipes(i).gap_y + 80) and
                       (b_y + bird_s) > (pipes(i).gap_y + 60) then
                        g_tick := '1';
                    end if;
                end if;
            end if;

            if bird_x = pipes(i).x + pipe_w then
                s_tick := '1';
            end if;
        end loop;

        if p_row >= 450 then
            ground_on <= '1';
            ground_addr <= std_logic_vector(to_unsigned(p_row - 450, 4)) &
                           std_logic_vector(to_unsigned(p_col, 4));

            if (b_y + bird_s) >= 450 then
                is_col_ground := '1';
            end if;
        else
            ground_on <= '0';
        end if;

        pipebody_on <= p_body;

        pipe_on    <= is_pipe;
        gift_on    <= is_gift;
        pipe_col   <= is_col_pipe;
        ground_col <= is_col_ground;
        score_tick <= s_tick;
        gift_tick  <= g_tick;
    end process;

end behavior;