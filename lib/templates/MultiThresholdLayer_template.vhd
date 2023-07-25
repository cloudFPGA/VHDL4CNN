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
--  *     Description: Container for individual multi_threshold operations
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.cnn_types.all;

entity MultiThreshold_Layer is
  generic(
    BITWIDTH   : integer;
    PROD_WIDTH  : integer;
    NB_OUT_FLOWS : integer
    USED_LAYER_ID : integer;
    );
  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    enable   : in  std_logic;
    in_data  : in  prod_array(NB_OUT_FLOWS - 1 downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out pixel_array(NB_OUT_FLOWS - 1 downto 0);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end entity;

architecture STRUCTURAL of MultiThreshold_Layer is
  --------------------------------------------------------------------------------
  -- COMPONENTS
  --------------------------------------------------------------------------------

  -- DOSA_INSERT_COMPONENT_DECLARATIONS

  --component MultiThreshold_Layer_REPLACE_ENTITY_CHANNEL_ID
  --  generic(
  --    BITWIDTH  : integer;
  --    PROD_WIDTH  : integer;
  --    );
  --  port(
  --    clk      : in  std_logic;
  --    reset_n  : in  std_logic;
  --    enable   : in  std_logic;
  --    in_data  : in  std_logic_vector (BITWIDTH - 1 downto 0);
  --    in_dv    : in  std_logic;
  --    in_fv    : in  std_logic;
  --    out_data : out std_logic_vector (BITWIDTH - 1 downto 0);
  --    out_dv   : out std_logic;
  --    out_fv   : out std_logic
  --    );

  --end component;
--------------------------------------------------------------------------------
begin

  -- DOSA_INSERT_COMPONENT_INSTANTIATIONS

  --  multi_threshold_REPLACE_ENTITY_CHANNEL_ID: MultiThreshold_Layer_REPLACE_ENTITY_CHANNEL_ID
  --      generic map(
  --        BITWIDTH  => BITWIDTH,
  --        PROD_WIDTH => PROD_WIDTH
  --        )
  --      port map(
  --        clk      => clk,
  --        reset_n  => reset_n,
  --        enable   => enable,
  --        in_data  => in_data(0),
  --        in_dv    => in_dv,
  --        in_fv    => in_fv,
  --        out_data => out_data(0),
  --        out_dv   => out_dv,
  --        out_fv   => out_fv
  --        );

end STRUCTURAL;

