-- Implementation of a Multiple-Constant-Multiplier:
-- This IP multiplies an input array with CONSTANT coefficients (3D convolution kernels)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity MCM is
  generic(
    BITWIDTH       : integer;
    DOT_PRODUCT_SIZE : integer;
    KERNEL_VALUE     : pixel_array
    );
  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    enable    : in  std_logic;
    in_data   : in  pixel_array (DOT_PRODUCT_SIZE - 1 downto 0);
    in_valid  : in  std_logic;
    out_data  : out prod_array (DOT_PRODUCT_SIZE - 1 downto 0);
    out_valid : out std_logic
    );
end MCM;

architecture rtl of MCM is

begin


  process(clk)
  begin
    if (rising_edge(clk)) then
      --if (reset_n = '0') or (enable = '0') or (in_valid = '0') then
      --  out_data  <= (others => (others => '0'));
      --  out_valid <= '0';
      --else
        mcm_loop : for i in 0 to (DOT_PRODUCT_SIZE - 1) loop
            --out_data(i) <= std_logic_vector(signed(signed(KERNEL_VALUE(i)) * signed(in_data(i))));
          --out_data(i) <= std_logic_vector(signed(KERNEL_VALUE(i)) * signed(in_data(i)));
          out_data(i) <= std_logic_vector(signed(KERNEL_VALUE(i)) * signed(in_data(i)));
        end loop;
        out_valid <= in_valid;
      -- end if;
    end if;
  end process;

end architecture;

