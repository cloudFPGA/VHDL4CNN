library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;
library work;
use work.cnn_types.all;

entity TanhLayer is
  generic(
    BITWIDTH   : integer;
    PROD_WIDTH  : integer
    );
  port(
    in_data  : in  std_logic_vector (PROD_WIDTH-1 downto 0);
    out_data : out std_logic_vector (BITWIDTH-1 downto 0)
    );
end entity;

architecture Bhv of TanhLayer is
-- Piecewise implementation of TanH

  signal scaled_back_data: std_logic_vector(PROD_WIDTH-1 downto 0);
  signal tmp_out: std_logic_vector(BITWIDTH-1 downto 0);

begin
  --scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), BITWIDTH-1));
  scaled_back_data <= std_logic_vector(SHIFT_RIGHT((signed(in_data) + to_signed(ROUND_FACTOR, PROD_WIDTH)), SCALE_BITS));
  -- DON'T USE resize! https://redirect.cs.umbc.edu/portal/help/VHDL/numeric_std.vhdl
  -- manually take care of sign bit
  -- we scale back only by 8 (i.e. 2^(n-1) + 1 )
  --tmp_out <= in_data(in_data'left) & in_data(2*BITWIDTH downto BITWIDTH + 1);
  tmp_out <= in_data(PROD_WIDTH - 1 downto BITWIDTH);

  --sum_s    <= signed(in_data);
  out_data <= std_logic_vector(to_signed(-V2, BITWIDTH)) when (signed(scaled_back_data) < to_signed(-T2, PROD_WIDTH)) else
              std_logic_vector(to_signed( V2, BITWIDTH)) when (signed(scaled_back_data) > to_signed( T2, PROD_WIDTH)) else
              -- std_logic_vector(SHIFT_RIGHT(signed(in_data), 2*BITWIDTH)(BITWIDTH-1 downto 0));
              -- in_data(BITWIDTH-1 downto 0));
              -- std_logic_vector(resize(signed(scaled_back_data), BITWIDTH));
              tmp_out;

end architecture;

