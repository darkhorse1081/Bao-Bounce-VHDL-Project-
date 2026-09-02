library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY bird_logic IS
    PORT(
        clk, vert_sync, mouse_click : IN std_logic;
        reset_pos    : IN std_logic;
        game_state   : IN std_logic_vector(1 downto 0);
        pixel_row, pixel_column : IN std_logic_vector(9 downto 0);
        bird_on_out  : OUT std_logic;
        bird_y_out   : OUT std_logic_vector(9 downto 0);
        bird_addr    : OUT std_logic_vector(7 downto 0)
    );
END bird_logic;

ARCHITECTURE behavior OF bird_logic IS
    CONSTANT size         : unsigned(9 downto 0)  := to_unsigned(16, 10);
    CONSTANT ball_x_pos   : unsigned(10 downto 0) := to_unsigned(320, 11);
    SIGNAL ball_y_pos     : unsigned(9 downto 0)  := to_unsigned(240, 10);
    SIGNAL mouse_click_prev : std_logic := '0';
BEGIN
    bird_y_out <= std_logic_vector(ball_y_pos);

    bird_on_out <= '1' WHEN (
        (unsigned('0' & pixel_column) >= ball_x_pos) AND
        (unsigned('0' & pixel_column) <  ball_x_pos + resize(size, 11)) AND
        (unsigned(pixel_row)          >= ball_y_pos) AND
        (unsigned(pixel_row)          <  ball_y_pos + size)
    ) ELSE '0';

    bird_addr <= std_logic_vector(to_unsigned(
        ((to_integer(unsigned(pixel_row)) - to_integer(ball_y_pos)) * 16) +
        (to_integer(unsigned('0' & pixel_column)) - to_integer(ball_x_pos)),
        8
    )) WHEN (
        (unsigned('0' & pixel_column) >= ball_x_pos) AND
        (unsigned('0' & pixel_column) <  ball_x_pos + resize(size, 11)) AND
        (unsigned(pixel_row)          >= ball_y_pos) AND
        (unsigned(pixel_row)          <  ball_y_pos + size)
    ) ELSE (others => '0');

    Move_Ball: PROCESS (vert_sync, reset_pos)
    BEGIN
        IF reset_pos = '1' THEN
            ball_y_pos <= to_unsigned(240, 10);
            mouse_click_prev <= '0';

        ELSIF rising_edge(vert_sync) THEN
            mouse_click_prev <= mouse_click;

            IF game_state = "01" THEN
                IF mouse_click = '1' AND mouse_click_prev = '0' THEN
                    IF ball_y_pos > to_unsigned(40, 10) THEN
                        ball_y_pos <= ball_y_pos - to_unsigned(40, 10);
                    ELSE
                        ball_y_pos <= size;
                    END IF;
                ELSE
                    IF ball_y_pos + size < to_unsigned(450, 10) THEN
                        ball_y_pos <= ball_y_pos + to_unsigned(3, 10);
                    ELSE
                        ball_y_pos <= to_unsigned(450, 10) - size;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS Move_Ball;
END behavior;