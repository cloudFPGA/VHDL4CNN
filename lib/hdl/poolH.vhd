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
--  *     Created/Refactored: Apr 2022
--  *     Authors: NGL
--  *

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity poolH is
  generic(
    BITWIDTH  : integer;
    IMAGE_WIDTH : integer; --not used?
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

architecture rtl of poolH is
  --------------------------------------------------------------------------
  -- Signals
  --------------------------------------------------------------------------
  type buffer_data_type is array (integer range <>) of signed (BITWIDTH-1 downto 0);

  signal buffer_data      : buffer_data_type (KERNEL_SIZE - 1 downto 0);
  signal buffer_fv        : std_logic_vector(KERNEL_SIZE downto 0);
  signal delay_fv         : std_logic := '0';
  signal tmp_dv           : std_logic := '0';
  signal x_cmp : unsigned(15 downto 0);
  signal delay_dv         : std_logic;



begin

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset_n = '0') or (in_fv = '0') then
        tmp_dv           <= '0';
        buffer_data      <= (others => (others => '0'));
        x_cmp  <= to_unsigned(0, 16);
        delay_dv <= '0';

      elsif (enable = '1') and (in_fv = '1') then
        delay_dv <= tmp_dv;
        if (in_dv = '1') then
            -- Bufferize data --------------------------------------------------------
          buffer_data(KERNEL_SIZE - 1) <= signed(in_data);
          BUFFER_LOOP : for i in (KERNEL_SIZE - 1) downto 1 loop
            buffer_data(i-1) <= buffer_data(i);
          end loop;

          -- H Subsample -------------------------------------------------------------
          if (x_cmp >= to_unsigned(KERNEL_SIZE-1, 16)) then
            tmp_dv <= '1';
            x_cmp <=  to_unsigned(0, 16);
          else
            tmp_dv <= '0';
            x_cmp  <=  x_cmp + to_unsigned(1, 16);
          end if;
        --------------------------------------------------------------------------
        else
          -- Data is not valid
          tmp_dv <= '0';
        end if;
      else
        tmp_dv <= '0';
        delay_dv <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------

  delay : process(clk)
  begin
    if (rising_edge(clk)) then
      if (reset_n = '0') then
        delay_fv  <= '0';
        buffer_fv <= (others => '0');
      else
        if (enable = '1') then
          buffer_fv <= buffer_fv(buffer_fv'high -1 downto 0) & in_fv;
          delay_fv  <= buffer_fv(buffer_fv'high);
        else
          delay_fv  <= '0';
        end if;
      end if;
    end if;
  end process;


  out_data <= std_logic_vector(buffer_data(0)) when (buffer_data(0) > buffer_data(1)) else
              std_logic_vector(buffer_data(1));

  out_fv   <= delay_fv;
  out_dv   <= tmp_dv;

end architecture;

