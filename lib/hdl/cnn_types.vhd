------------------------------------------------------------------------------
-- Title      : cnn_types
-- Project    : Haddoc2
------------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.bitwidths.all;  -- must stay line number 9, will be overwritten by Haddoc2OSG

package cnn_types is
  ------------------------------------------------------------------------------
  -- Types
  type pixel_array is array (integer range <>) of std_logic_vector (GENERAL_BITWIDTH-1 downto 0);
  type prod_array is array (integer range <>) of std_logic_vector (PROD_WIDTH-1 downto 0);
  type pixel_matrix is array (integer range <>, integer range <>) of std_logic_vector (GENERAL_BITWIDTH-1 downto 0);
  type valid_array is array (integer range <>) of std_logic;
  type valid_matrix is array (integer range <>, integer range <>) of std_logic;

  ------------------------------------------------------------------------------
  -- Constants to implement piecewize TanH : cf DotProduct.vhd
  constant SCALE_FACTOR : integer := 2 **(GENERAL_BITWIDTH-1);  -- TODO: NO -1!!
  constant ROUND_FACTOR : integer := SCALE_FACTOR / 2;
  constant SCALE_BITS   : integer := GENERAL_BITWIDTH - 1; -- TODO: make dynamic=> signed/unsigned, how much integer...
  constant A1           : integer := GENERAL_BITWIDTH - 1;
  constant A2           : integer := GENERAL_BITWIDTH;
  constant T1           : integer := SCALE_FACTOR * SCALE_FACTOR / 2;
  constant T2           : integer := SCALE_FACTOR * SCALE_FACTOR * 5/4;
  constant V1           : integer := SCALE_FACTOR / 4;
  constant V2           : integer := SCALE_FACTOR - 10;
  ------------------------------------------------------------------------------
  -- Functions:
  -- extractRow : Extracts a row of pixel_array data from a pixel_matrix.
  function extractRow(target_row : integer;
                      nb_col     : integer;
                      in_matrix  : pixel_matrix)
  return pixel_array;
------------------------------------------------------------------------------
end cnn_types;


package body cnn_types is
  function extractRow(target_row : integer;
                      nb_col     : integer;
                      in_matrix  : pixel_matrix)
  return pixel_array is
  variable out_vec : pixel_array (nb_col - 1 downto 0);
  begin
    for index_col in (nb_col - 1) downto 0 loop
      out_vec(index_col) := in_matrix(target_row, index_col);
    end loop;
    return out_vec;
  end extractRow;
end cnn_types;

