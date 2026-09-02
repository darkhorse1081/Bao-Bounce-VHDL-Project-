library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        q_out : out std_logic_vector(7 downto 0)
    );
end lfsr;

architecture behavior of lfsr is

    signal q : std_logic_vector(7 downto 0) := "10101010";

begin

    q_out <= q;

    -- 8-bit Galois LFSR with non-zero reset seed.
    process(clk, reset)
    begin
        if reset = '1' then
            q <= "10101010";
        elsif rising_edge(clk) then
            q(0) <= q(7);
            q(1) <= q(0);
            q(2) <= q(1);
            q(3) <= q(2);
            q(4) <= q(3) xor q(7);
            q(5) <= q(4) xor q(7);
            q(6) <= q(5) xor q(7);
            q(7) <= q(6);
        end if;
    end process;

end behavior;