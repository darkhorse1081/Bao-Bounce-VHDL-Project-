LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera_mf;
USE altera_mf.all;

ENTITY sprite_rom IS
    GENERIC (
        mif_file : string;
        depth    : integer;
        addr_w   : integer
    );
    PORT (
        clock   : IN  std_logic;
        address : IN  std_logic_vector(addr_w-1 DOWNTO 0);
        q       : OUT std_logic_vector(2 DOWNTO 0)
    );
END sprite_rom;

ARCHITECTURE SYN OF sprite_rom IS
    COMPONENT altsyncram
    GENERIC (
        clock_enable_input_a   : STRING;
        clock_enable_output_a  : STRING;
        init_file              : STRING;
        intended_device_family : STRING;
        lpm_hint               : STRING;
        lpm_type               : STRING;
        numwords_a             : NATURAL;
        operation_mode         : STRING;
        outdata_aclr_a         : STRING;
        outdata_reg_a          : STRING;
        widthad_a              : NATURAL;
        width_a                : NATURAL
    );
    PORT (
        clock0    : IN STD_LOGIC ;
        address_a : IN STD_LOGIC_VECTOR (addr_w-1 DOWNTO 0);
        q_a       : OUT STD_LOGIC_VECTOR (2 DOWNTO 0)
    );
    END COMPONENT;
BEGIN
    altsyncram_component : altsyncram
    GENERIC MAP (
        clock_enable_input_a   => "BYPASS",
        clock_enable_output_a  => "BYPASS",
        init_file              => mif_file,
        intended_device_family => "Cyclone V",
        lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
        lpm_type               => "altsyncram",
        numwords_a             => depth,
        operation_mode         => "ROM",
        outdata_aclr_a         => "NONE",
        outdata_reg_a          => "UNREGISTERED",
        widthad_a              => addr_w,
        width_a                => 3
    )
    PORT MAP (
        clock0    => clock,
        address_a => address,
        q_a       => q
    );
END SYN;