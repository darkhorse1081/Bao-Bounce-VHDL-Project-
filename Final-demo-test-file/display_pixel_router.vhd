LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use work.layers_pack.ALL;

ENTITY display_pixel_router IS
    PORT(
		  layers : in  layers_array_t;
        vid_r, vid_g, vid_b : out std_logic
    );
END display_pixel_router;

ARCHITECTURE behavior OF display_pixel_router IS
BEGIN
    PROCESS(layers)
    BEGIN
	 
		 vid_r <= '0';
       vid_g <= '0';
       vid_b <= '0';
		 
       for i in num_layers-1 downto 0 loop
            if layers(i).layer_on = '1' then
                vid_r <= layers(i).rgb(0);
                vid_g <= layers(i).rgb(1);
                vid_b <= layers(i).rgb(2);
            end if;
        end loop;
    END PROCESS;
END behavior;