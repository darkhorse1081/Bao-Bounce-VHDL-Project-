LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

package layers_pack is
	
	type layers_t is record
        layer_on : std_logic;
        rgb : std_logic_vector(2 downto 0);
   end record;
	 
	constant num_layers : integer := 6;

	type layers_array_t is array (0 to num_layers-1) of layers_t;
	 
   constant text_layer : integer := 0;
	constant bird_layer : integer := 1;
	constant obstacle_layer : integer := 2;
	constant gift_layer : integer := 3;
	constant floor_layer : integer := 4;
	constant background_layer : integer := 5;
end package;