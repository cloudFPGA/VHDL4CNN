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
    PROD_WIDTH  : integer;
    KERNEL_SIZE : integer
    );
  port(
    in_data  : in  std_logic_vector (PROD_WIDTH-1 downto 0);
    out_data : out std_logic_vector (BITWIDTH-1 downto 0)
    );
end entity;

architecture Bhv of ReluLayer is

  -- KERNEL_SIZE to account for multiple adds?
  -- actually two bits per addition...so 2*BITWIDTH?
  --constant SCALE_SHIFT        : integer := BITWIDTH + KERNEL_SIZE;
  --constant SCALE_SHIFT        : integer := 2 * BITWIDTH;
  signal scaled_back_data: std_logic_vector(PROD_WIDTH-1 downto 0);

begin

  --scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), SCALE_SHIFT));
  --scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), BITWIDTH-1));
  -- including rounding
  --scaled_back_data <= std_logic_vector(SHIFT_RIGHT((signed(in_data) + to_signed(ROUND_FACTOR, SUM_WIDTH)), SCALE_BITS));
  -- without rounding
  -- +1 for the sum
  -- scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), ( SCALE_BITS + 1)));
  --scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), ( 2* SCALE_BITS)));

  -- TODO: clean up, scale back happens before adder tree (MOA)
  -- scaled_back_data <= in_data;
  -- TODO for debugging
  out_data <= (others => '0') when (signed(in_data) < to_signed(0, PROD_WIDTH)) else
              --in_data(in_data'left) & in_data(2*BITWIDTH downto BITWIDTH + 1);
              in_data(PROD_WIDTH - 1  downto PROD_WIDTH - BITWIDTH);
  -- -- out_data <= (others => '1') when (signed(in_data) < to_signed(0, SUM_WIDTH)) else
  --             std_logic_vector(to_signed(SCALE_FACTOR, BITWIDTH)) when (signed(scaled_back_data) > to_signed(SCALE_FACTOR, SUM_WIDTH)) else
  --             --scaled_back_data(BITWIDTH-1 downto 0);
  --             std_logic_vector(resize(signed(scaled_back_data), BITWIDTH));

  -- out_data <= std_logic_vector(resize(signed(scaled_back_data), BITWIDTH));
  -- DON'T USE resize! https://redirect.cs.umbc.edu/portal/help/VHDL/numeric_std.vhdl
  -- we scale back only by 8 (i.e. 2^(n-1) + 1 )
  -- manually take care of sign bit
  --out_data <= scaled_back_data(scaled_back_data'left) & scaled_back_data(BITWIDTH - 2 downto 0);
  --out_data <= scaled_back_data(scaled_back_data'left) & scaled_back_data(BITWIDTH downto 2);
  --out_data <= in_data(in_data'left) & in_data(2*BITWIDTH downto BITWIDTH + 1);


end architecture;

