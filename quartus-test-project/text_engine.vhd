LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity text_engine is
    port (
        clk_25mhz    : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_col    : in std_logic_vector(9 downto 0);
        mode_switch  : in std_logic; -- 0 = training, 1 = game
        
        text_on      : out std_logic;
        text_rgb     : out std_logic_vector(2 downto 0)
    );
end text_engine;

architecture behavior of text_engine is
    signal char_addr  : std_logic_vector(5 downto 0);
    signal rom_out    : std_logic;

    component char_rom is
        port(
            character_address  : in std_logic_vector(5 downto 0);
            font_row, font_col : in std_logic_vector(2 downto 0);
            clock              : in std_logic;
            rom_mux_output     : out std_logic
        );
    end component;

begin
    -- instantiate the rom
    -- scaling logic: by using bits (3 downto 1) instead of (2 downto 0),
    -- each pixel in the 8x8 font becomes a 2x2 block on the screen! (16x16 total)
    rom_inst : char_rom port map (
        character_address => char_addr,
        font_row          => pixel_row(3 downto 1),
        font_col          => pixel_col(3 downto 1),
        clock             => clk_25mhz,
        rom_mux_output    => rom_out
    );

    process(pixel_row, pixel_col, mode_switch)
    begin
        -- text bounding box: top center of screen (y: 16 to 31, x: 280 to 359)
        -- 5 characters * 16 pixels wide = 80 pixels total width
        if (pixel_row >= 16 and pixel_row < 32) then
            
            -- character 1
            if (pixel_col >= 280 and pixel_col < 296) then 
                if mode_switch = '0' then char_addr <= "010100"; else char_addr <= "000111"; end if; -- 't' or 'g'
            
            -- character 2
            elsif (pixel_col >= 296 and pixel_col < 312) then
                if mode_switch = '0' then char_addr <= "010010"; else char_addr <= "000001"; end if; -- 'r' or 'a'
            
            -- character 3
            elsif (pixel_col >= 312 and pixel_col < 328) then
                if mode_switch = '0' then char_addr <= "000001"; else char_addr <= "001101"; end if; -- 'a' or 'm'
                
            -- character 4
            elsif (pixel_col >= 328 and pixel_col < 344) then
                if mode_switch = '0' then char_addr <= "001001"; else char_addr <= "000101"; end if; -- 'i' or 'e'
                
            -- character 5
            elsif (pixel_col >= 344 and pixel_col < 360) then
                if mode_switch = '0' then char_addr <= "001110"; else char_addr <= "100000"; end if; -- 'n' or space
            
            -- outside character boxes
            else
                char_addr <= "100000"; -- space
            end if;
        else
            char_addr <= "100000"; -- space
        end if;
    end process;

    -- output logic: only turn text on if we are in the box and the rom output is '1'
    text_on <= rom_out when (pixel_row >= 16 and pixel_row < 32 and pixel_col >= 280 and pixel_col < 360) else '0';
    text_rgb <= "111"; -- white text

end behavior;