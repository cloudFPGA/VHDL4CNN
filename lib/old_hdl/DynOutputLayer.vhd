------------------------------------------------------------------------------
-- Title      : DynOutputLayer 
-- Project    : Haddoc2/DOSA
-- author: NGL, based on Haddoc2
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


library work;
use work.cnn_types.all;

entity DynOutputLayer is
  generic(
    BITWIDTH  : integer;
    NB_IN_FLOWS : integer
    );
  port(
    in_data  : in  pixel_array (NB_IN_FLOWS-1 downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out std_logic_vector(NB_IN_FLOWS*BITWIDTH-1 downto 0);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end entity;

architecture bhv of DynOutputLayer is
begin

  output_combine: for i in NB_IN_FLOWS-1 downto 0 generate
    out_data((i+1)*BITWIDTH-1 downto i*BITWIDTH) <= in_data(i);
  end generate output_combine;

  out_dv   <= in_dv;
  out_fv   <= in_fv;

end bhv;

