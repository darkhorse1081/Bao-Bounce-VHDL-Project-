library ieee;
use ieee.std_logic_1164.all;
use work.layers_pack.all;

entity display_pixel_router is
    port(
        layers : in  layers_array_t;
        vid_r  : out std_logic;
        vid_g  : out std_logic;
        vid_b  : out std_logic
    );
end display_pixel_router;

architecture behavior of display_pixel_router is

begin

    process(layers)
    begin
        vid_r <= '0';
        vid_g <= '0';
        vid_b <= '0';

        -- Lower-index layers have higher priority because later assignments win.
        for i in num_layers - 1 downto 0 loop
            if layers(i).layer_on = '1' then
                vid_r <= layers(i).rgb(2);
                vid_g <= layers(i).rgb(1);
                vid_b <= layers(i).rgb(0);
            end if;
        end loop;
    end process;

end behavior;