library ieee;
use ieee.std_logic_1164.all;

package layers_pack is

    type layers_t is record
        layer_on : std_logic;
        rgb      : std_logic_vector(2 downto 0);
    end record;

    constant num_layers : integer := 7;

    type layers_array_t is array (0 to num_layers - 1) of layers_t;

    -- Lower index means higher display priority.
    constant cursor_layer     : integer := 0;
    constant text_layer       : integer := 1;
    constant bird_layer       : integer := 2;
    constant obstacle_layer   : integer := 3;
    constant gift_layer       : integer := 4;
    constant floor_layer      : integer := 5;
    constant background_layer : integer := 6;

end package;