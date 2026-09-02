LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;


ENTITY bird_logic IS
	PORT
		( pb1, pb2, clk, vert_sync, mouse_click	: IN std_logic;
          pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		  red, green, blue, bird_on_out 			: OUT std_logic);		
END bird_logic;

architecture behavior of bird_logic is

SIGNAL ball_on					: std_logic;
SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
SIGNAL ball_y_pos				: std_logic_vector(9 DOWNTO 0);
SiGNAL ball_x_pos				: std_logic_vector(10 DOWNTO 0);
SIGNAL ball_y_motion			: std_logic_vector(9 DOWNTO 0);
signal mouse_click_prev : std_logic := '0';
signal mouse_click_flag : std_logic; 


BEGIN           

size <= CONV_STD_LOGIC_VECTOR(8,10);
-- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball
ball_x_pos <= CONV_STD_LOGIC_VECTOR(320,11);

ball_on <= '1' when ( ('0' & ball_x_pos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & ball_x_pos + size) 	-- x_pos - size <= pixel_column <= x_pos + size
					and ('0' & ball_y_pos <= pixel_row + size) and ('0' & pixel_row <= ball_y_pos + size) )  else	-- y_pos - size <= pixel_row <= y_pos + size
			'0';


-- Colours for pixel data on video signal
-- Changing the background and ball colour by pushbuttons
Red <=  pb1;
Green <= (not pb2) and (not ball_on);
Blue <=  not ball_on;
bird_on_out <= ball_on;
mouse_click_flag <= mouse_click and (not mouse_click_prev);

Move_Ball: process (vert_sync)  	
begin
	-- Move ball once every vertical sync
	if (rising_edge(vert_sync)) then
		mouse_click_prev <= mouse_click;
		
		if mouse_click = '1' and mouse_click_prev = '0' then
			if ball_y_pos > CONV_STD_LOGIC_VECTOR(20, 10) then
				 ball_y_pos <= ball_y_pos - CONV_STD_LOGIC_VECTOR(60, 10);
			else
				 ball_y_pos <= size;
			end if;
		else
			if ball_y_pos + size < CONV_STD_LOGIC_VECTOR(479, 10) then
				 ball_y_pos <= ball_y_pos + CONV_STD_LOGIC_VECTOR(2, 10);
			else
				 ball_y_pos <= CONV_STD_LOGIC_VECTOR(479, 10) - size;
			end if;
		end if;
	end if;
end process Move_Ball;

END behavior;

