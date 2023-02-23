library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity DotProduct is
  generic(
    BITWIDTH       : integer;
    PROD_WIDTH        : integer;
    DOT_PRODUCT_SIZE : integer;
    KERNEL_VALUE     : pixel_array;
    BIAS_VALUE       : std_logic_vector
    );
  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    enable   : in  std_logic;
    in_data  : in  pixel_array (DOT_PRODUCT_SIZE - 1 downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out std_logic_vector (PROD_WIDTH-1 downto 0);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end DotProduct;

architecture rtl of DotProduct is

  component MCM
     generic (
       BITWIDTH       : integer;
       DOT_PRODUCT_SIZE : integer;
       KERNEL_VALUE     : pixel_array
       );
     port (
       clk       : in  std_logic;
       reset_n   : in  std_logic;
       enable    : in  std_logic;
       in_data   : in  pixel_array (DOT_PRODUCT_SIZE - 1 downto 0);
       in_valid  : in  std_logic;
       out_data  : out prod_array (DOT_PRODUCT_SIZE - 1 downto 0);
       out_valid : out std_logic
       );
  end component MCM;
  --
  component MOA
     generic (
       BITWIDTH   : integer;
       PROD_WIDTH    : integer;
       NUM_OPERANDS : integer;
       BIAS_VALUE   : std_logic_vector
       );
     port (
       clk       : in  std_logic;
       reset_n   : in  std_logic;
       enable    : in  std_logic;
       in_data   : in  prod_array (NUM_OPERANDS - 1 downto 0);
       in_valid  : in  std_logic;
       out_data  : out std_logic_vector (PROD_WIDTH-1 downto 0);
       out_valid : out std_logic
       );
  end component MOA;
  --
     signal p_prod_data  : prod_array (DOT_PRODUCT_SIZE - 1 downto 0);
     signal p_prod_valid : std_logic;
     signal s_out_valid  : std_logic;

   begin
   MCM_i : MCM
     generic map (
       BITWIDTH       => BITWIDTH,
       DOT_PRODUCT_SIZE => DOT_PRODUCT_SIZE,
       KERNEL_VALUE     => KERNEL_VALUE
       )
     port map (
       clk       => clk,
       reset_n   => reset_n,
       enable    => (enable and in_fv),
       in_data   => in_data,
       -- in_valid  => (in_dv and in_fv),
       in_valid  => in_dv,
       out_data  => p_prod_data,
       out_valid => p_prod_valid
       );
   MOA_i : MOA
     generic map (
       BITWIDTH   => BITWIDTH,
       PROD_WIDTH    => PROD_WIDTH,
       NUM_OPERANDS => DOT_PRODUCT_SIZE,
       BIAS_VALUE   => BIAS_VALUE
       )
     port map (
       clk       => clk,
       reset_n   => reset_n,
       enable    => (enable and in_fv),
       in_data   => p_prod_data,
       in_valid  => p_prod_valid,
       out_data  => out_data,
       out_valid => s_out_valid
       );
   out_dv <= s_out_valid;
   -- out_fv <= s_out_valid;
   -- TODO
   out_fv <= in_fv;

end architecture;

