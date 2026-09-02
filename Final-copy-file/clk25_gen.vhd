LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- this generates the 25mhz clock required by vga sync and mouse
entity clk25_gen is
    port (
        clk_50  : in  std_logic;
        clk_25  : out std_logic
    );
end clk25_gen;

architecture behavior of clk25_gen is
    signal clk_div : std_logic := '0';
begin
    process(clk_50)
    begin
        if rising_edge(clk_50) then
            clk_div <= not clk_div;
        end if;
    end process;
    
    clk_25 <= clk_div;
end behavior;