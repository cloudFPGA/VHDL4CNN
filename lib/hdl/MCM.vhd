-- Implementation of a Multiple-Constant-Multiplier:
-- This IP multiplies an input array with CONSTANT coefficients (3D convolution kernels)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;
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
  -- Generate DOT_PRODUCT_SIZE Multipliers
  --signal mult : prod_array (0 to DOT_PRODUCT_SIZE - 1);

  -- attribute to force DSP usage
  -- update: better not...otherwise we have 75% DSP usage with only 20% LUT usage and a difficult timing
  -- attribute use_dsp : string;
  -- attribute use_dsp of out_data: signal is "yes";

begin
  ---------------------------------
  -- Assynchronous implmentation --
  ---------------------------------
  -- mcm_loop : for i in 0 to DOT_PRODUCT_SIZE - 1 generate
  --     out_data(i) <=  KERNEL_VALUE(i) * in_data(i);
  -- end generate mcm_loop;
  -- out_valid <= in_valid;

  ---------------------------------
  --  synchronous implmentation  --
  ---------------------------------

  process(clk)
  begin
    if (rising_edge(clk)) then
      if(reset_n = '0') then
        out_data  <= (others => (others => '0'));
        out_valid <= '0';
       -- elsif (enable = '1') then
      elsif (enable = '1') and (in_valid = '1') then
        --if (in_valid = '1') then
          mcm_loop : for i in DOT_PRODUCT_SIZE - 1 downto 0 loop
            --out_data(i) <= std_logic_vector(signed(signed(KERNEL_VALUE(i)) * signed(in_data(i))));
            out_data(i) <= std_logic_vector(signed(KERNEL_VALUE(i)) * signed(in_data(i)));
          end loop;
          out_valid <= '1';
        --else
        --  out_data <= (others => (others => '0'));
        --  out_valid <= '0';
        --end if;
    --out_valid <= in_valid;
      else
        out_data <= (others => (others => '0'));
        -- for debugging: pass the data through if not valid
        --out_data <= (others => std_logic_vector(to_unsigned(201, out_data(0)'length)));
        -- cast_loop: for i in 0 DOT_PRODUCT_SIZE - 1 downto 0 loop
        --     --out_data(i) <= std_logic_vector(resize(signed(in_data(i)), out_data(i)'length));
        --     -- for debugging, we can ignore the sign bit?
        --     out_data(i) <= (out_data(i)'left -1 downto in_data(i)'left => '0') & in_data(i);
        -- end loop;
        out_valid <= '0';
      end if;
    end if;
  end process;

end architecture;

