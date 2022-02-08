-- Implements a relu activation
-- author: NGL, based on Haddoc2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work;
use work.cnn_types.all;

entity ReluLayer is
  generic(
    BITWIDTH   : integer;
    SUM_WIDTH  : integer
    );
  port(
    in_data  : in  std_logic_vector (SUM_WIDTH-1 downto 0);
    out_data : out std_logic_vector (BITWIDTH-1 downto 0)
    );
end entity;

architecture Bhv of ReluLayer is

begin

  out_data <= (others => '0') when (signed(in_data) < 0 ) else
              std_logic_vector(SHIFT_RIGHT(signed(in_data),BITWIDTH)(BITWIDTH-1 downto 0));

end architecture;
