-- Implements a relu activation
-- author: NGL, based on Haddoc2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;
library work;
use work.cnn_types.all;

entity ReluLayer is
  generic(
    BITWIDTH   : integer;
    SUM_WIDTH  : integer;
    KERNEL_SIZE : integer
    );
  port(
    in_data  : in  std_logic_vector (SUM_WIDTH-1 downto 0);
    out_data : out std_logic_vector (BITWIDTH-1 downto 0)
    );
end entity;

architecture Bhv of ReluLayer is

  -- KERNEL_SIZE to account for multiple adds?
  -- actually two bits per addition...so 2*BITWIDTH?
  --constant SCALE_SHIFT        : integer := BITWIDTH + KERNEL_SIZE;
  constant SCALE_SHIFT        : integer := 2 * BITWIDTH;
  signal scaled_back_data: std_logic_vector(SUM_WIDTH-1 downto 0);

begin

  scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), SCALE_SHIFT));
  out_data <= (others => '0') when (signed(in_data) < to_signed(0, SUM_WIDTH)) else
              std_logic_vector(to_signed(SCALE_FACTOR, BITWIDTH)) when (signed(scaled_back_data) > to_signed(SCALE_FACTOR, SUM_WIDTH)) else
              scaled_back_data(BITWIDTH-1 downto 0);

end architecture;
