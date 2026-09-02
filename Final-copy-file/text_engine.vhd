LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity text_engine is
	 generic (text_to_print : string);
    port (
        clk_25mhz    : in std_logic;
        pixel_row    : in std_logic_vector(9 downto 0);
        pixel_col    : in std_logic_vector(9 downto 0);
		  position_x : in  std_logic_vector(9 downto 0);
        position_y : in  std_logic_vector(9 downto 0);
        text_scale : in  std_logic_vector(1 downto 0);
        text_on      : out std_logic;
        text_rgb     : out std_logic_vector(2 downto 0)
    );
end text_engine;
  
architecture behavior of text_engine is
	 constant text_len : integer := text_to_print'length;
    signal char_addr  : std_logic_vector(5 downto 0);
	 signal font_row_s   : std_logic_vector(2 downto 0);
    signal font_col_s   : std_logic_vector(2 downto 0);
    signal rom_out    : std_logic;
	 signal in_region    : std_logic;
    signal delay : std_logic;

    component char_rom is
        port(
            character_address  : in std_logic_vector(5 downto 0);
            font_row, font_col : in std_logic_vector(2 downto 0);
            clock              : in std_logic;
            rom_mux_output     : out std_logic
        );
    end component;
	 
	 function char_to_addr(c : character) return std_logic_vector is
    begin
        case c is
            when 'A'|'a' => return "000001";
            when 'B'|'b' => return "000010";
            when 'C'|'c' => return "000011";
            when 'D'|'d' => return "000100";
            when 'E'|'e' => return "000101";
            when 'F'|'f' => return "000110";
            when 'G'|'g' => return "000111";
            when 'H'|'h' => return "001000";
            when 'I'|'i' => return "001001";
            when 'J'|'j' => return "001010";
            when 'K'|'k' => return "001011";
            when 'L'|'l' => return "001100";
            when 'M'|'m' => return "001101";
            when 'N'|'n' => return "001110";
            when 'O'|'o' => return "001111";
            when 'P'|'p' => return "010000";
            when 'Q'|'q' => return "010001";
            when 'R'|'r' => return "010010";
            when 'S'|'s' => return "010011";
            when 'T'|'t' => return "010100";
            when 'U'|'u' => return "010101";
            when 'V'|'v' => return "010110";
            when 'W'|'w' => return "010111";
            when 'X'|'x' => return "011000";
            when 'Y'|'y' => return "011001";
            when 'Z'|'z' => return "011010";
            when others  => return "100000";
        end case;
    end function;

begin
	
	-- instantiate the rom
	-- scaling logic: by using bits (3 downto 1) instead of (2 downto 0),
	-- each pixel in the 8x8 font becomes a 2x2 block on the screen! (16x16 total)
	rom_inst : char_rom port map (
		
	   character_address => char_addr,
	   font_row          => font_row_s,
	   font_col          => font_col_s,
	   clock             => clk_25mhz,
	   rom_mux_output    => rom_out
	);
		
	process(pixel_row, pixel_col, text_scale, position_x, position_y)
		  variable row_ref   : unsigned(9 downto 0);
        variable col_ref   : unsigned(9 downto 0);
        variable row_current   : unsigned(9 downto 0);
        variable col_current    : unsigned(9 downto 0);
        variable px       : integer;
        variable py       : integer;
        variable row_end  : integer;
        variable col_end  : integer;
        variable char_idx : integer range 0 to 63;
        variable current_char : character;
	begin
		
		row_ref := unsigned(pixel_row);
	   col_ref := unsigned(pixel_col);
	   px    := to_integer(unsigned(position_x));
	   py    := to_integer(unsigned(position_y));
		
		case text_scale is
            when "00"   => row_end := py + 8;  col_end := px + text_len * 8;
            when "01"   => row_end := py + 16; col_end := px + text_len * 16;
            when "10"   => row_end := py + 32; col_end := px + text_len * 32;
            when others => row_end := py + 64; col_end := px + text_len * 64;
      end case;
		
	   if (to_integer(row_ref) >= py and to_integer(row_ref) < row_end and
			 to_integer(col_ref) >= px and to_integer(col_ref) < col_end) then

			 in_region <= '1';
			 row_current := row_ref - unsigned(position_y);
			 col_current := col_ref - unsigned(position_x);

			 case text_scale is
					 when "00" =>
						  font_row_s <= std_logic_vector(row_current(2 downto 0));
						  font_col_s <= std_logic_vector(col_current(2 downto 0));
						  char_idx   := to_integer(col_current(9 downto 3));
					 when "01" =>
						  font_row_s <= std_logic_vector(row_current(3 downto 1));
						  font_col_s <= std_logic_vector(col_current(3 downto 1));
						  char_idx   := to_integer(col_current(9 downto 4));
					 when "10" =>
						  font_row_s <= std_logic_vector(row_current(4 downto 2));
						  font_col_s <= std_logic_vector(col_current(4 downto 2));
						  char_idx   := to_integer(col_current(9 downto 5));
					 when others =>
						  font_row_s <= std_logic_vector(row_current(5 downto 3));
						  font_col_s <= std_logic_vector(col_current(5 downto 3));
						  char_idx   := to_integer(col_current(9 downto 6));
			 end case;
			 
			 if char_idx < text_len then
                current_char := text_to_print(text_to_print'left + char_idx);
          else
                current_char := ' ';
          end if;
			 
			 char_addr <= char_to_addr(current_char);
		else
			in_region  <= '0';
			char_addr  <= "100000";
			font_row_s <= (others => '0');
			font_col_s <= (others => '0');
		end if;

	end process;

	process(clk_25mhz)
   begin
        if rising_edge(clk_25mhz) then
            delay <= in_region;
        end if;
   end process;

   text_on  <= rom_out and delay;
   text_rgb <= "111";

end behavior;