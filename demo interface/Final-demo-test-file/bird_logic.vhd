library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bird_logic is
    port(
        clk          : in  std_logic;
        vert_sync    : in  std_logic;
        mouse_click  : in  std_logic;
        reset_pos    : in  std_logic;
        game_state   : in  std_logic_vector(1 downto 0);

        pixel_row    : in  std_logic_vector(9 downto 0);
        pixel_column : in  std_logic_vector(9 downto 0);

        pipe_col     : in  std_logic;
        death        : in  std_logic;

        bounce       : out std_logic;
        bird_on_out  : out std_logic;
        bird_y_out   : out std_logic_vector(9 downto 0);
        bird_addr    : out std_logic_vector(7 downto 0)
    );
end bird_logic;

architecture behavior of bird_logic is

    constant size       : unsigned(9 downto 0)  := to_unsigned(16, 10);
    constant ball_x_pos : unsigned(10 downto 0) := to_unsigned(320, 11);

    signal ball_y_pos      : unsigned(9 downto 0) := to_unsigned(240, 10);
    signal mouse_click_prev : std_logic := '0';
    signal velocity        : integer := 0;
    signal flash_timer     : integer := 0;
    signal flash_visible   : std_logic := '1';

begin
    bird_y_out <= std_logic_vector(ball_y_pos);

    -- Top level uses to indicate the temporary post-collision bounce.
    bounce <= '1' when flash_timer > 40 else '0';

    -- Current pixel is inside the 16x16 bird box and the bird is visible.
    bird_on_out <= '1' when (
        (unsigned('0' & pixel_column) >= ball_x_pos) and
        (unsigned('0' & pixel_column) <  ball_x_pos + resize(size, 11)) and
        (unsigned(pixel_row)          >= ball_y_pos) and
        (unsigned(pixel_row)          <  ball_y_pos + size) and
        flash_visible = '1'
    ) else '0';
	 
	 Bird_Rom : process(pixel_row, pixel_column, ball_y_pos, death)
	 begin
			if (unsigned('0' & pixel_column) >= ball_x_pos) AND
				(unsigned('0' & pixel_column) <  ball_x_pos + resize(size, 11)) AND
				(unsigned(pixel_row)          >= ball_y_pos) AND
				(unsigned(pixel_row)          <  ball_y_pos + size)
			then
				if death = '1' then
						bird_addr <= std_logic_vector(to_unsigned(
							((15 - (to_integer(unsigned(pixel_row)) - to_integer(ball_y_pos))) * 16) +
							(to_integer(unsigned('0' & pixel_column)) - to_integer(ball_x_pos)),
							8
						));
				else
						bird_addr <= std_logic_vector(to_unsigned(
							((to_integer(unsigned(pixel_row)) - to_integer(ball_y_pos)) * 16) +
							(to_integer(unsigned('0' & pixel_column)) - to_integer(ball_x_pos)),
							8
						));
				end if;
			else
				bird_addr <= (others => '0');
			end if;
	 end process Bird_Rom;

    -- Bird movement updates once per frame using vert_sync.
    move_ball : process(vert_sync, reset_pos)
    begin
        if reset_pos = '1' then
            ball_y_pos       <= to_unsigned(240, 10);
            mouse_click_prev <= '0';
            velocity         <= 0;
            flash_timer      <= 0;
            flash_visible    <= '1';

        elsif rising_edge(vert_sync) then
            mouse_click_prev <= mouse_click;
            IF game_state = "01" or (death = '1' and ball_y_pos + size < to_unsigned(450, 10)) THEN
					 if death = '1' then
							if velocity < 10 then
								velocity <= velocity + 2;
							end if;
					 else
							if mouse_click = '1' and mouse_click_prev = '0' then
								velocity <= -8;
							else
									
								if velocity < 6 then
										velocity <= velocity + 1;
								else
										velocity <= 6;
								end if;
							end if;
				    end if;
					 if pipe_col = '1' and flash_timer = 0 and death = '0' then
							flash_timer <= 60;
					 end if;
					 if ball_y_pos + velocity < to_unsigned(40, 10) then
                    ball_y_pos <= to_unsigned(40, 10);
                    velocity   <= 0;

                elsif ball_y_pos + size + velocity >= to_unsigned(450, 10) then
                    ball_y_pos <= to_unsigned(450, 10) - size;
                    velocity   <= 0;

                else
                    ball_y_pos <= ball_y_pos + velocity;
                end if;

                if flash_timer > 0 then
                    flash_timer <= flash_timer - 1;

                    if (flash_timer mod 4) = 0 then
                        flash_visible <= not flash_visible;
                    end if;
                else
                    flash_visible <= '1';
                end if;

            end if;
        end if;
    end process move_ball;

end behavior;