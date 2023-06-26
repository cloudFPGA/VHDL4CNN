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
------------------------------------------------------------------------------
-- Description: 2x2 subsampling with max operator
--
--         -------         -------
--        |       |       |       |
--    --->| PoolH |------>| PoolV | --->
--        |       |       |       |
--         -------         -------
--
-----------------------------------------------------------------------------
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity maxPool is
  generic(
    BITWIDTH  : integer;
    IMAGE_WIDTH : integer;
    KERNEL_SIZE : integer
    );

  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    enable   : in  std_logic;
    in_data  : in  std_logic_vector (BITWIDTH - 1 downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out std_logic_vector (BITWIDTH - 1 downto 0);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end entity;

architecture rtl of maxPool is
  --------------------------------------------------------------------------
  -- Signals
  --------------------------------------------------------------------------
  signal connect_data : std_logic_vector (BITWIDTH - 1 downto 0);
  signal connect_dv   : std_logic;
  signal connect_fv   : std_logic;

  --------------------------------------------------------------------------
  -- components
  --------------------------------------------------------------------------
  component poolH
    generic(
      BITWIDTH  : integer;
      IMAGE_WIDTH : integer;
      KERNEL_SIZE : integer
      );

    port(
      clk      : in  std_logic;
      reset_n  : in  std_logic;
      enable   : in  std_logic;
      in_data  : in  std_logic_vector (BITWIDTH - 1 downto 0);
      in_dv    : in  std_logic;
      in_fv    : in  std_logic;
      out_data : out std_logic_vector (BITWIDTH - 1 downto 0);
      out_dv   : out std_logic;
      out_fv   : out std_logic
      );

  end component;
  --------------------------------------------------------------------------
  component poolV
    generic(
      BITWIDTH  : integer;
      IMAGE_WIDTH : integer;
      KERNEL_SIZE : integer
      );

    port(
      clk      : in  std_logic;
      reset_n  : in  std_logic;
      enable   : in  std_logic;
      in_data  : in  std_logic_vector (BITWIDTH - 1 downto 0);
      in_dv    : in  std_logic;
      in_fv    : in  std_logic;
      out_data : out std_logic_vector (BITWIDTH - 1 downto 0);
      out_dv   : out std_logic;
      out_fv   : out std_logic
      );

  end component;
  --------------------------------------------------------------------------

begin
  poolv_inst : poolV
    generic map (
      BITWIDTH  => BITWIDTH,
      KERNEL_SIZE => KERNEL_SIZE,
      IMAGE_WIDTH => IMAGE_WIDTH
      )

    port map (
      clk      => clk,
      reset_n  => reset_n,
      enable   => enable,
      in_data  => in_data,
      in_dv    => in_dv,
      in_fv    => in_fv,
      out_data => connect_data,
      out_dv   => connect_dv,
      out_fv   => connect_fv
      );

  --------------------------------------------------------------------------

  poolh_inst : poolH
    generic map (
      BITWIDTH  => BITWIDTH,
      KERNEL_SIZE => KERNEL_SIZE,
      IMAGE_WIDTH => IMAGE_WIDTH
      )

    port map (
      clk      => clk,
      reset_n  => reset_n,
      enable   => enable,
      in_data  => connect_data,
      in_dv    => connect_dv,
      in_fv    => connect_fv,
      out_data => out_data,
      out_dv   => out_dv,
      out_fv   => out_fv
      );

end rtl;

