library ieee;
use ieee.std_logic_1164.all;

-- Generates the 25 MHz clock required by the VGA sync and mouse modules.
entity clk25_gen is
    port(
        clk_50 : in  std_logic;
        clk_25 : out std_logic
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