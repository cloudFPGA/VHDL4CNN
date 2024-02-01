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
------------------------------------------------------------------------------
-- Description: A fully pipelined implementation of CNN layers that is able to process
--              one pixel/clock cycle. Each actors of a CNN graph are directly mapped
--              on the hardware following the principals of DHM and DataFlow processing
--                            ______
--                          |       |
--                          |       |-- output_streams-->
--        input_streams---->| conv  |-- output_streams-->
--        input_streams---->| Layer |-- output_streams-->
--        input_streams---->|       |-- output_streams-->
--        input_streams---->|       |-- output_streams-->
--                          |       |-- output_streams-->
--                           ______
-----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;


entity ConvLayer is
  generic(
    BITWIDTH   : integer;
    PROD_WIDTH    : integer;
    IMAGE_WIDTH  : integer;
    KERNEL_SIZE  : integer;
    NB_IN_FLOWS  : integer;
    NB_OUT_FLOWS : integer;
    USE_RELU_ACTIVATION : boolean;
    USE_TANH_ACTIVATION : boolean;
    USE_MULTI_THRESHOLD : boolean;
    USED_MULTI_THRESHOLD_LAYER_ID: integer;
    KERNEL_VALUE : pixel_matrix;
    BIAS_VALUE   : pixel_array
    );

  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    enable   : in  std_logic;
    in_data  : in  pixel_array(NB_IN_FLOWS - 1 downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out pixel_array(NB_OUT_FLOWS - 1 downto 0);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end entity;

architecture STRUCTURAL of ConvLayer is
  --------------------------------------------------------------------------------
  -- COMPONENTS
  --------------------------------------------------------------------------------
  component TensorExtractor
    generic (
      BITWIDTH  : integer;
      IMAGE_WIDTH : integer;
      KERNEL_SIZE : integer;
      NB_IN_FLOWS : integer
      );
    port (
      clk      : in  std_logic;
      reset_n  : in  std_logic;
      enable   : in  std_logic;
      in_data  : in  pixel_array (NB_IN_FLOWS - 1 downto 0);
      in_dv    : in  std_logic;
      in_fv    : in  std_logic;
      out_data : out pixel_array (NB_IN_FLOWS * KERNEL_SIZE * KERNEL_SIZE- 1 downto 0);
      out_dv   : out std_logic;
      out_fv   : out std_logic
      );
  end component TensorExtractor;

  component DotProduct
    generic (
      BITWIDTH       : integer;
      PROD_WIDTH        : integer;
      DOT_PRODUCT_SIZE : integer;
      KERNEL_VALUE     : pixel_array;
      BIAS_VALUE       : std_logic_vector
      );
    port (
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
  end component DotProduct;


  component TanhLayer
    generic (
      BITWIDTH : integer;
      PROD_WIDTH  : integer
      );
    port (
      in_data  : in  std_logic_vector (PROD_WIDTH-1 downto 0);
      out_data : out std_logic_vector (BITWIDTH-1 downto 0)
      );
  end component TanhLayer;


  component ReluLayer
    generic (
      BITWIDTH : integer;
      PROD_WIDTH  : integer;
      KERNEL_SIZE: integer
      );
    port (
      in_data  : in  std_logic_vector (PROD_WIDTH-1 downto 0);
      out_data : out std_logic_vector (BITWIDTH-1 downto 0)
      );
  end component ReluLayer;

  component MultiThresholdOperation
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
  end component;

  ------------------------------------------------------------------------------------------
  signal neighborhood_data : pixel_array (NB_IN_FLOWS * KERNEL_SIZE * KERNEL_SIZE- 1 downto 0);
  signal neighborhood_dv   : std_logic;
  signal neighborhood_fv   : std_logic;
  signal dp_data           : prod_array (NB_OUT_FLOWS-1 downto 0);
  signal dp_dv             : std_logic;
  signal dp_fv             : std_logic;
-----------------------------------------------------------------------------------------
begin

  TensorExtractor_i : TensorExtractor
    generic map (
      BITWIDTH  => BITWIDTH,
      IMAGE_WIDTH => IMAGE_WIDTH,
      KERNEL_SIZE => KERNEL_SIZE,
      NB_IN_FLOWS => NB_IN_FLOWS
      )
    port map (
      clk      => clk,
      reset_n  => reset_n,
      enable   => enable,
      in_data  => in_data,
      in_dv    => in_dv,
      in_fv    => in_fv,
      out_data => neighborhood_data,
      out_dv   => neighborhood_dv,
      out_fv   => neighborhood_fv
      );

  DotProduct_loop : for n in NB_OUT_FLOWS- 1 downto 0 generate
    DotProduct_0 : if n = 0 generate
      DotProduct_0_inst : DotProduct
        generic map (
          BITWIDTH       => BITWIDTH,
          PROD_WIDTH        => PROD_WIDTH,
          DOT_PRODUCT_SIZE => NB_IN_FLOWS * KERNEL_SIZE * KERNEL_SIZE,
          BIAS_VALUE       => BIAS_VALUE(n),
          KERNEL_VALUE     => extractRow(n,
                                     NB_IN_FLOWS * KERNEL_SIZE * KERNEL_SIZE,
                                     KERNEL_VALUE)
          )
        port map (
          clk      => clk,
          reset_n  => reset_n,
          enable   => enable,
          in_data  => neighborhood_data,
          in_dv    => neighborhood_dv,
          in_fv    => neighborhood_fv,
          out_data => dp_data(n),
          out_dv   => dp_dv,
          out_fv   => dp_fv
          );
    end generate DotProduct_0;

    DotProduct_i : if n > 0 generate
      DotProduct_i_inst : DotProduct
        generic map (
          BITWIDTH       => BITWIDTH,
          PROD_WIDTH        => PROD_WIDTH,
          DOT_PRODUCT_SIZE => NB_IN_FLOWS * KERNEL_SIZE * KERNEL_SIZE,
          BIAS_VALUE       => BIAS_VALUE(n),
          KERNEL_VALUE     => extractRow(n,
                                     NB_IN_FLOWS * KERNEL_SIZE * KERNEL_SIZE,
                                     KERNEL_VALUE)
          )
        port map (
          clk      => clk,
          reset_n  => reset_n,
          enable   => enable,
          in_data  => neighborhood_data,
          in_dv    => neighborhood_dv,
          in_fv    => neighborhood_fv,
          out_data => dp_data(n),
          out_dv   => open,
          out_fv   => open
          );
    end generate DotProduct_i;

    relu_activation: if USE_RELU_ACTIVATION generate
      ReluLayer_i: ReluLayer
        generic map (
          BITWIDTH => BITWIDTH,
          PROD_WIDTH  => PROD_WIDTH,
          KERNEL_SIZE => KERNEL_SIZE
          )
        port map (
          in_data  => dp_data(n),
          out_data => out_data(n)
          );
    end generate;

    tanh_activation: if USE_TANH_ACTIVATION generate
      TanhLayer_i : TanhLayer
        generic map (
          BITWIDTH => BITWIDTH,
          PROD_WIDTH  => PROD_WIDTH
          )
        port map (
          in_data  => dp_data(n),
          out_data => out_data(n)
          );
    end generate;

    multi_threshold: if USE_MULTI_THRESHOLD generate
      multi_threshold_operation_i: MultiThresholdOperation
        generic map (
          BITWIDTH => BITWIDTH,
          PROD_WIDTH => PROD_WIDTH,
          USED_LAYER_ID => USED_MULTI_THRESHOLD_LAYER_ID,
          USED_LAYER_CHANNEL_ID => n
          )
        port map (
          in_data => dp_data(n),
          out_data => out_data(n)
          );
    end generate;

    passthrough_activation: if (not USE_RELU_ACTIVATION) and (not USE_TANH_ACTIVATION) and (not USE_MULTI_THRESHOLD) generate
      out_data(n) <= dp_data(n)(PROD_WIDTH-1) & dp_data(n)(PROD_WIDTH-2 downto BITWIDTH);
    end generate;

  end generate DotProduct_loop;

  out_dv <= dp_dv;
  out_fv <= dp_fv;


end architecture;

