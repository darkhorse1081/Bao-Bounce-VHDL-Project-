LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY lfsr IS
    PORT (
        clk    : IN  std_logic;
        reset  : IN  std_logic;
        q_out  : OUT std_logic_vector(7 downto 0)
    );
END lfsr;

ARCHITECTURE behavior OF lfsr IS
    SIGNAL q : std_logic_vector(7 downto 0) := "10101010"; -- Non-zero seed
BEGIN
    q_out <= q;

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            q <= "10101010";
        ELSIF rising_edge(clk) THEN
            -- 8-bit Galois LFSR with polynomial x^8 + x^6 + x^5 + x^4 + 1
            q(0) <= q(7);
            q(1) <= q(0);
            q(2) <= q(1);
            q(3) <= q(2);
            q(4) <= q(3) XOR q(7);
            q(5) <= q(4) XOR q(7);
            q(6) <= q(5) XOR q(7);
            q(7) <= q(6);
        END IF;
    END PROCESS;
END behavior;