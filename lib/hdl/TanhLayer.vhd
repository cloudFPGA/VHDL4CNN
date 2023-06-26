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
--  *     Description: Implements a (quantized) TanH activation
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity TanhLayer is
  generic(
    BITWIDTH   : integer;
    PROD_WIDTH  : integer
    );
  port(
    in_data  : in  std_logic_vector (PROD_WIDTH-1 downto 0);
    out_data : out std_logic_vector (BITWIDTH-1 downto 0)
    );
end entity;

architecture Bhv of TanhLayer is
-- Piecewise implementation of TanH

  signal scaled_back_data: std_logic_vector(PROD_WIDTH-1 downto 0);
  signal tmp_out: std_logic_vector(BITWIDTH-1 downto 0);

begin
  --scaled_back_data <= std_logic_vector(SHIFT_RIGHT(signed(in_data), BITWIDTH-1));
  scaled_back_data <= std_logic_vector(SHIFT_RIGHT((signed(in_data) + to_signed(ROUND_FACTOR, PROD_WIDTH)), SCALE_BITS));
  -- DON'T USE resize! https://redirect.cs.umbc.edu/portal/help/VHDL/numeric_std.vhdl
  -- manually take care of sign bit
  -- we scale back only by 8 (i.e. 2^(n-1) + 1 )
  --tmp_out <= in_data(in_data'left) & in_data(2*BITWIDTH downto BITWIDTH + 1);
  tmp_out <= in_data(PROD_WIDTH - 1 downto BITWIDTH);

  --sum_s    <= signed(in_data);
  out_data <= std_logic_vector(to_signed(-V2, BITWIDTH)) when (signed(scaled_back_data) < to_signed(-T2, PROD_WIDTH)) else
              std_logic_vector(to_signed( V2, BITWIDTH)) when (signed(scaled_back_data) > to_signed( T2, PROD_WIDTH)) else
              -- std_logic_vector(SHIFT_RIGHT(signed(in_data), 2*BITWIDTH)(BITWIDTH-1 downto 0));
              -- in_data(BITWIDTH-1 downto 0));
              -- std_logic_vector(resize(signed(scaled_back_data), BITWIDTH));
              tmp_out;

end architecture;

