-- /*******************************************************************************
--  * Copyright 2021 -- 2024 IBM Corporation
--  *
--  * Licensed under the Apache License, Version 2.0 (the "License");
--  * you may not use this file except in compliance with the License.
--  * You may obtain a copy of the License at
--  *
--  *     http://www.apache.org/licenses/LICENSE-2.0
--  *
--  * Unless required by applicable law or agreed to in writing, software
--  * distributed under the License is distributed on an "AS IS" BASIS,
--  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  * See the License for the specific language governing permissions and
--  * limitations under the License.
-- *******************************************************************************/

-- ************************************************
-- Copyright (c) 2017, Kamel ABDELOUAHAB
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
--
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- ************************************************

--  *
--  *                       VHDL4CNN
--  *    =============================================
--  *     Created/Refactored: Feb 2022
--  *     Authors: NGL
--  *     Description: Declares necessary types
--  *

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.bitwidths.all;  -- must stay line number 54, will be overwritten by vhdl4cnnOSG

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
  constant SCALE_FACTOR : integer := 2 **(GENERAL_BITWIDTH-1);
  constant ROUND_FACTOR : integer := SCALE_FACTOR / 2;
  constant SCALE_BITS   : integer := GENERAL_BITWIDTH - 1; -- only for TANH layer, not for thresholding
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

