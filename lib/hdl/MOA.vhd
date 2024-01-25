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
--  *     Description: Design of a Multi-Operand-Adder block;
--  *                  This is a naive implementation with binary adder trees.
--  *                  (COMPLETELY REWRITTEN BY NGL)
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity MOA is
  generic(
    BITWIDTH     : integer;
    PROD_WIDTH    : integer;
    NUM_OPERANDS : integer;
    BIAS_VALUE   : std_logic_vector
    );

  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    enable    : in  std_logic;
    in_data   : in  prod_array (NUM_OPERANDS - 1 downto 0);
    in_valid  : in  std_logic;
    out_data  : out std_logic_vector(PROD_WIDTH-1 downto 0);
    out_valid : out std_logic
    );
end MOA;


architecture rtl of MOA is

-------------------------------
-- recursive implementation
-- fixes original haddoc2 implementation
-------------------------------

    signal tmp_data: std_logic_vector (PROD_WIDTH-1 downto 0);
    signal tmp_valid: std_logic;
    signal bias_cast :  std_logic_vector (PROD_WIDTH-1 downto 0);
begin

  rec_a: entity work.RADD generic map(BITWIDTH=>BITWIDTH,PROD_WIDTH=>PROD_WIDTH,
                                      NUM_OPERANDS=>NUM_OPERANDS,ORDER=>0)
  port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
           in_data=>in_data,
           out_data=>tmp_data, out_valid=>tmp_valid);

  bias_cast(PROD_WIDTH-1 downto 0) <= (others => '0');
  bias_cast(BITWIDTH+BITWIDTH-3 downto BITWIDTH-1) <= BIAS_VALUE(BITWIDTH-2 downto 0);
  -- sign bit
  bias_cast(PROD_WIDTH-1) <= BIAS_VALUE(BITWIDTH-1);

  process(clk)
  begin
    if (rising_edge(clk)) then
      --if (reset_n = '0') or (enable = '0') or (tmp_valid = '0') then
      --  out_data <= (others => '0');
      --  out_valid <= '0';
      --else
          out_data <= std_logic_vector(signed(tmp_data) + signed(bias_cast));
          out_valid <= tmp_valid;
      --end if;
    end if;
  end process;


end architecture;

