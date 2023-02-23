-- Design of a Multi-Operand-Adder block
-- This is a naive implementation with binary adder trees
-- == COMPLETELY REWRITTEN BY NGL ==

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity MOA is
  generic(
    BITWIDTH     : integer;
    PROD_WIDTH    : integer;
    NUM_OPERANDS : integer;
    BIAS_VALUE   : std_logic_vector
    );

  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    enable    : in  std_logic;
    in_data   : in  prod_array (NUM_OPERANDS - 1 downto 0);
    in_valid  : in  std_logic;
    out_data  : out std_logic_vector(PROD_WIDTH-1 downto 0);
    out_valid : out std_logic
    );
end MOA;


architecture rtl of MOA is

-------------------------------
-- recursive implementation
-- fixes original haddoc2 implementation
-------------------------------

    signal tmp_data: std_logic_vector (PROD_WIDTH-1 downto 0);
    signal tmp_valid: std_logic;
    signal bias_cast :  std_logic_vector (PROD_WIDTH-1 downto 0);
begin

  rec_a: entity work.RADD generic map(BITWIDTH=>BITWIDTH,PROD_WIDTH=>PROD_WIDTH,
                                      NUM_OPERANDS=>NUM_OPERANDS,ORDER=>0)
  port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
           in_data=>in_data,
           out_data=>tmp_data, out_valid=>tmp_valid);

  -- TODO
  bias_cast(PROD_WIDTH-1 downto BITWIDTH) <= BIAS_VALUE;
  bias_cast(BITWIDTH -1 downto 0) <= (others => '0');

  process(clk)
  begin
    if (rising_edge(clk)) then
      --if (reset_n = '0') or (enable = '0') or (tmp_valid = '0') then
      --  out_data <= (others => '0');
      --  out_valid <= '0';
      --else
          out_data <= std_logic_vector(signed(tmp_data) + signed(bias_cast));
          out_valid <= tmp_valid;
      --end if;
    end if;
  end process;


end architecture;

