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

--  *
--  *                       VHDL4CNN
--  *    =============================================
--  *     Created: Jan 2022
--  *     Authors: NGL
--  *     Description: Implements a ReLU activation
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity ReluLayer is
  generic(
    BITWIDTH   : integer;
    PROD_WIDTH  : integer;
    KERNEL_SIZE : integer
    );
  port(
    in_data  : in  std_logic_vector (PROD_WIDTH-1 downto 0);
    out_data : out std_logic_vector (BITWIDTH-1 downto 0)
    );
end entity;

architecture Bhv of ReluLayer is

  signal scaled_back_data: std_logic_vector(PROD_WIDTH-1 downto 0);

begin

  out_data <= (others => '0') when (signed(in_data) < to_signed(0, PROD_WIDTH)) else
              --in_data(in_data'left) & in_data(2*BITWIDTH downto BITWIDTH + 1);
              in_data(PROD_WIDTH - 1  downto PROD_WIDTH - BITWIDTH);

  -- out_data <= std_logic_vector(resize(signed(scaled_back_data), BITWIDTH));
  -- DON'T USE resize! https://redirect.cs.umbc.edu/portal/help/VHDL/numeric_std.vhdl


end architecture;

