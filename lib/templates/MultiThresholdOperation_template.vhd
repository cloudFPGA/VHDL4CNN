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
--  *     Created: July 2023
--  *     Authors: NGL
--  *     Description: Implements all multi_threshold operations within a block
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;

entity MultiThresholdOperation is
  generic(
    BITWIDTH   : integer;
    PROD_WIDTH  : integer;
    USED_LAYER_ID: integer;
    USED_LAYER_CHANNEL_ID: integer
    );
  port(
    in_data  : in  std_logic_vector(PROD_WIDTH-1 downto 0);
    out_data : out std_logic_vector(BITWIDTH-1 downto 0)
    );
end entity;

architecture Behaviour of MultiThresholdOperation is

begin

-- multi_threshold_X_Y : if USED_LAYER_OP_ID = 42 generate
--   out_data <= "1000" when in_data = "00" else
--               "0100" when in_data = "01" else
--               "0010" when in_data = "10" else
--               "0001" when in_data = "11";
--  end generate multi_threshold_X_Y;

-- DOSA_INSERT_GENRICS_FOR_WHEN_ELSE


end architecture;

