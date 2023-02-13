-- Converts the camera output to signals usable by Haddoc layers
-- TODO : Support a variable PIXEL_BIT_WIDTH
-- author: NGL, based on Haddoc2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.cnn_types.all;

entity DynInputLayer is
  generic(
    BITWIDTH      : integer;          -- Bit-width of the activations and FMs
    INPUT_BIT_WIDTH : integer;          -- Bit-width of the input pixel
    NB_OUT_FLOWS    : integer           -- Number of channels in input
    );

  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    enable   : in  std_logic;
    in_data  : in  std_logic_vector(INPUT_BIT_WIDTH-1 downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out pixel_array(0 to NB_OUT_FLOWS-1);
    out_dv   : out std_logic;
    out_fv   : out std_logic

    );
end entity;

architecture bhv of DynInputLayer is
begin
  -- process(clk)
  -- begin
  --   if (reset_n = '0') then
  --     out_data <= (others => (others => '0'));
  --   else
  --     if (enable = '1') then
  --       inDemux : for i in 0 to NB_OUT_FLOWS-1 loop
  --         out_data(i) <= '0' & in_data((i+1)*BITWIDTH-1 downto i*BITWIDTH);
  --       end loop inDemux;
  --     end if;
  --     out_dv <= in_dv;
  --     out_fv <= in_fv;
  --   end if;
  -- end process;

  input_split: for i in 0 to NB_OUT_FLOWS-1 generate
    --out_data(i) <= std_logic_vector(resize(signed(in_data((i+1)*BITWIDTH-1 downto i*BITWIDTH)), out_data(i)'length));
    out_data(i)(out_data(i)'length-1 downto BITWIDTH) <= (others => in_data((i+1)*BITWIDTH-1));
    out_data(i)(BITWIDTH -1 downto 0) <= in_data((i+1)*BITWIDTH-1 downto i*BITWIDTH);
  end generate input_split;

  out_dv <= in_dv;
  out_fv <= in_fv;

end bhv;


