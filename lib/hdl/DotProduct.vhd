-- /*******************************************************************************
--  * Copyright 2021 -- 2023 IBM Corporation
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
--  *     Description: Container for the matrix-vector product
--  *

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
   out_fv <= in_fv;

end architecture;

