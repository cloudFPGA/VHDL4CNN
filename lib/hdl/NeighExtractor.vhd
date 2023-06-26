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
--  *     Created/Refactored: May 2022
--  *     Authors: NGL
------------------------------------------------------------------------------------------------------------
-- == COMPLETELY REWRITTEN BY NGL ==
-------------------------------------------------------------------------------------------------------------
-- Description: Extracts a generic neighborhood from serial in_data
--
--                          ------------------
--          reset_n    --->|                  |
--          clk        --->|                  |
--          enable     --->|                  |
--                         |                  |---> out_data (pixel_array of size KERNEL_SIZE²)
--                         |  neighExtractor  |---> out_dv
--                         |                  |---> out_fv
--          in_data    --->|                  |---> out_valid
--          in_dv      --->|                  |
--          in_fv      --->|                  |
--                         |                  |
--                          ------------------

--------------------------------------------------------------------------------------------------------------

--                        out_data(0)      out_data(1)      out_data(2)
--                           ^                 ^                 ^
--                           |                 |                 |
--               -------     |     -------     |     -------     |    ---------------------------
--              |        |   |    |        |   |    |        |   |   |                           |
--  in_data --->|  p22   |---|--> |  p21   |---|--> |  p20   |---|-->|          BUFFER           |-> to_P1
--              |        |        |        |        |        |       |                           |
--               -------           -------           -------          ---------------------------
--                        out_data(3)      out_data(4)      out_data(5)
--                           ^                 ^                 ^
--                           |                 |                 |
--               -------     |     -------     |     -------     |    ---------------------------
--              |        |   |    |        |   |    |        |   |   |                           |
--  P1      --->|  p12   |---|--> |  p11   |---|--> |  p10   |---|-->|          BUFFER           |-> to_P2
--              |        |        |        |        |        |       |                           |
--               -------           -------           -------          ---------------------------
--                        out_data(6)      out_data(7)      out_data(8)
--                           ^                 ^                 ^
--                           |                 |                 |
--               -------     |     -------     |     -------     |
--              |        |   |    |        |   |    |        |   |
--  P2      --->|   p02  |---|--> |  p01   |---|--> |  p00   |---|
--              |        |        |        |        |        |
--               -------           -------           -------
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work;
use work.cnn_types.all;

entity neighExtractor is

  generic(
    BITWIDTH  : integer;
    IMAGE_WIDTH : integer;
    KERNEL_SIZE : integer
    );

  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    enable   : in  std_logic;
    in_data  : in  std_logic_vector((BITWIDTH-1) downto 0);
    in_dv    : in  std_logic;
    in_fv    : in  std_logic;
    out_data : out pixel_array ((KERNEL_SIZE * KERNEL_SIZE)- 1 downto 0);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end neighExtractor;

architecture rtl of neighExtractor is


  signal pixel_buffer : pixel_matrix(KERNEL_SIZE - 1 downto 0, IMAGE_WIDTH - 1 downto 0);
  signal valid_buffer : valid_matrix(KERNEL_SIZE - 1 downto 0, IMAGE_WIDTH - 1 downto 0);
  -- unused elements of last row will be removed anyhow by synthesis, hopefully

  constant WIDTH_COUNTER : integer  := integer(ceil(log2(real(IMAGE_WIDTH)))) + 2;
  type position_array is array (integer range <>) of unsigned(WIDTH_COUNTER - 1 downto 0);
  type position_matrix is array (integer range <>, integer range <>) of unsigned(WIDTH_COUNTER - 1 downto 0);
  -- signal horizontal_pos_buffer : position_matrix(KERNEL_SIZE - 1 downto 0, IMAGE_WIDTH - 1 downto 0);
  signal vertical_pos_buffer : position_matrix(KERNEL_SIZE - 1 downto 0, IMAGE_WIDTH -1 downto 0);

  signal horizontal_cnt: unsigned(WIDTH_COUNTER - 1 downto 0);
  signal vertical_cnt: unsigned(WIDTH_COUNTER - 1 downto 0);
  signal last_dv: std_logic;
  signal internal_reset: std_logic;

begin

  full_buffering: process(clk)
    variable tmp_valid: std_logic := '1'; -- 1!
    variable position_valid: std_logic := '1'; -- 1!
  begin
    if (rising_edge(clk)) then
      if (reset_n = '0') or (in_fv = '0') then
        pixel_buffer <= (others => (others => (others => '0')));
        valid_buffer <= (others => (others => '0'));
        -- horizontal_pos_buffer <= (others => (others => (others => '0')));
        vertical_pos_buffer <= (others => (others => (others => '0')));
        horizontal_cnt <= (others => '0');
        vertical_cnt <= (others => '0');
        last_dv <= '0';
        internal_reset <= '0';

        out_data <= (others => (others => '0'));
        out_dv <= '0';
        out_fv <= '0';
      else
        out_fv <= '1'; --is anyhow more or less ignored
        last_dv <= in_dv; --to get last pixel per frame
        internal_reset <= '0';
        -- if (enable = '1') and (in_dv = '1') then
        if (enable = '1') and ((in_dv = '1') or (last_dv = '1')) then

          -- advance buffers
          pixel_buffer(0, 0) <= in_data;
          valid_buffer(0, 0) <= in_dv; --yes, the pixel after the last pixel will be invalid and therefore "drain/poison" parts of full buffer
          -- horizontal_pos_buffer(0, 0) <= horizontal_cnt;
          vertical_pos_buffer(0, 0) <= vertical_cnt;

          first_line_loop: for j in 1 to (IMAGE_WIDTH - 1) loop
            pixel_buffer(0, j) <= pixel_buffer(0, j-1);
            valid_buffer(0, j) <= valid_buffer(0, j-1);
            -- horizontal_pos_buffer(0, j) <= horizontal_pos_buffer(0, j-1);
            vertical_pos_buffer(0, j) <= vertical_pos_buffer(0, j-1);
          end loop first_line_loop;

          outer_buffer_loop: for i in 1 to (KERNEL_SIZE - 1) loop
            pixel_buffer(i, 0) <= pixel_buffer(i-1, IMAGE_WIDTH - 1);
            valid_buffer(i, 0) <= valid_buffer(i-1, IMAGE_WIDTH - 1);
            -- horizontal_pos_buffer(i, 0) <= horizontal_pos_buffer(i-1, IMAGE_WIDTH - 1);
            vertical_pos_buffer(i, 0) <= vertical_pos_buffer(i-1, IMAGE_WIDTH - 1);
            inner_buffer_loop: for j in 1 to (IMAGE_WIDTH - 1) loop
              pixel_buffer(i, j) <= pixel_buffer(i, j-1);
              valid_buffer(i, j) <= valid_buffer(i, j-1);
              -- horizontal_pos_buffer(i, j) <= horizontal_pos_buffer(i, j-1);
              vertical_pos_buffer(i, j) <= vertical_pos_buffer(i, j-1);
            end loop inner_buffer_loop;
          end loop outer_buffer_loop;

          -- set out data
          kernel_loop: for k in 0 to (KERNEL_SIZE-1) loop
            inner_kernel_loop: for l in 0 to (KERNEL_SIZE-1) loop
              --out_data((k+1)*KERNEL_SIZE - 1 downto k*KERNEL_SIZE) <= pixel_buffer(k, KERNEL_SIZE - 1 downto 0);
              out_data(k*KERNEL_SIZE + l) <= pixel_buffer(k, l);
            end loop inner_kernel_loop;
          end loop kernel_loop;

          -- calculate valid
          tmp_valid := '1';
          position_valid := '1';
          outer_valid_loop: for k in 0 to (KERNEL_SIZE - 1) loop
            inner_valid_loop: for l in 0 to (KERNEL_SIZE - 1) loop
              if (valid_buffer(k,l) = '0') then
                tmp_valid := '0';
              end if;
            --tmp_valid := tmp_valid and valid_buffer(k, l);
            end loop inner_valid_loop;
            inner_pos_loop: for p in 1 to (KERNEL_SIZE - 1) loop
              --if (vertical_pos_buffer(k, p-1) = vertical_pos_buffer(k, p)) then
              --  position_valid := position_valid;
              --else
              if (vertical_pos_buffer(k, p-1) /= vertical_pos_buffer(k, p)) then
                position_valid := '0';
              end if;
            end loop inner_pos_loop;
          end loop outer_valid_loop;
          out_dv <= tmp_valid and position_valid;

          -- increase counter
          if (horizontal_cnt = (IMAGE_WIDTH - 1)) then
            horizontal_cnt <= (others => '0');
            if (vertical_cnt = (IMAGE_WIDTH - 1)) then
              vertical_cnt <= (others => '0');
              -- here, we are at the end of a frame, so we should reset the complete buffers
              -- but delayed by one cycle
              internal_reset <= '1';
            else
              if (in_dv = '1') then
                vertical_cnt <= vertical_cnt + to_unsigned(1, WIDTH_COUNTER);
              end if;
            end if;
          else
            if (in_dv = '1') then
              horizontal_cnt <= horizontal_cnt + to_unsigned(1, WIDTH_COUNTER);
            end if;
          end if;
        else
          out_data <= (others => (others => '0'));
          out_dv <= '0';
        end if;
        if (internal_reset = '1') then
          -- invalidate buffer, except a potential new input (from the current cycle, i.e. position 0,0)
          valid_buffer <= (others => (others => '0'));
          valid_buffer(0, 0) <= in_dv and enable;
        end if;
      end if;
    end if;
  end process full_buffering;


end architecture;

