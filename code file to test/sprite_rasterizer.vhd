LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL; -- Modern IEEE standard replacement for deprecated arithmetic libs

entity sprite_rasterizer is
    port (
        scan_coord_y      : in  std_logic_vector(9 downto 0);
        scan_coord_x      : in  std_logic_vector(9 downto 0);
        entity_base_y     : in  std_logic_vector(9 downto 0);
		  entity_base_x     : in  std_logic_vector(9 downto 0);
        render_flag       : out std_logic;
        output_chroma     : out std_logic_vector(2 downto 0)
    );
end sprite_rasterizer;

architecture comb_flow of sprite_rasterizer is
    constant block_dimension  : positive := 16;
    constant locked_x_origin  : unsigned(9 downto 0) := to_unsigned(150, 10);

    signal x_bound_met        : std_logic;
    signal y_bound_met        : std_logic;
    signal draw_qualified     : std_logic;
begin
    -- stage 1: boundary evaluation process
    eval_bounds_proc : process(scan_coord_x, scan_coord_y, entity_base_y)
    begin
        -- default to inactive to prevent latches
        x_bound_met <= '0';
        y_bound_met <= '0';

        -- horizontal range check
        if (unsigned(scan_coord_x) >= unsigned(entity_base_x)) and
           (unsigned(scan_coord_x) < (unsigned(entity_base_x) + block_dimension)) then
            x_bound_met <= '1';
        end if;

        -- vertical range check
        if (unsigned(scan_coord_y) >= unsigned(entity_base_y)) and
           (unsigned(scan_coord_y) < (unsigned(entity_base_y) + block_dimension)) then
            y_bound_met <= '1';
        end if;
    end process;

    -- stage 2: logic consolidation & output mapping (concurrent)
    draw_qualified <= x_bound_met and y_bound_met;
    render_flag    <= draw_qualified;

    with draw_qualified select
        output_chroma <= "110" when '1',
                         "000" when others;
end comb_flow;