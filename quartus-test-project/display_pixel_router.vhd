LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity display_pixel_router is
    port (
        -- inputs from other modules (bird & text)
        sprite_active    : in  std_logic;
        sprite_chroma    : in  std_logic_vector(2 downto 0);
        overlay_active   : in  std_logic;
        overlay_chroma   : in  std_logic_vector(2 downto 0);
        
        -- input (switches for background color)
        base_chroma      : in  std_logic_vector(2 downto 0);
        
        -- output going into the vga_sync.vhd component
        vid_r            : out std_logic;
        vid_g            : out std_logic;
        vid_b            : out std_logic
    );
end display_pixel_router;

architecture combinational_flow of display_pixel_router is
    -- internal bus capturing the winning pixel color after priority resolution
    signal selected_pixel_word : std_logic_vector(2 downto 0);
begin
    -- priority-based concurrent assignment (evaluates left-to-right)
    -- preserves exact original hierarchy: text > bird > background
    selected_pixel_word <= overlay_chroma  when overlay_active = '1' else
                           sprite_chroma   when sprite_active  = '1' else
                           base_chroma;

    -- direct bit-slicing to individual rgb output drivers
    vid_r <= selected_pixel_word(2);
    vid_g <= selected_pixel_word(1);
    vid_b <= selected_pixel_word(0);
end combinational_flow;