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
--  *     Created: Apr 2022
--  *     Authors: NGL
--  *     Description: Recursive Adder
--  *


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.cnn_types.all;


-- the parameter ORDER is just there to simplify (a little bit) debugging with recursive entities
-- e.g. to help with error messages like: "ComMsgMgrException: illegal recursive instantiation of design '%s': Invalid c_string in format."
entity RADD is
  generic(
    BITWIDTH     : integer;
    PROD_WIDTH    : integer;
    NUM_OPERANDS : integer;
    ORDER: integer
    );
  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    enable    : in  std_logic;
    in_data   : in  prod_array (NUM_OPERANDS - 1 downto 0);
    in_valid  : in  std_logic;
    out_data  : out std_logic_vector (PROD_WIDTH-1 downto 0);
    out_valid : out std_logic
    );
end RADD;


architecture rtl of RADD is
  -- max 5!
  constant DIVIDER_FACTOR : integer := 5;

begin

  ta: case NUM_OPERANDS generate

  when 1|2|3|4|5 =>
    l_base_add: process(clk)
      variable acc: signed(PROD_WIDTH-1 downto 0) := (others => '0');
    begin
      if (rising_edge(clk)) then
        --if (reset_n = '0') or (enable = '0') or (in_valid = '0') then
        --  out_valid <= '0';
        --  out_data <= (others => '0');
        -- else
            acc   := to_signed(0, PROD_WIDTH);
            --acc_loop : for i in NUM_OPERANDS-1 downto 0 loop
            acc_loop : for i in 0 to (NUM_OPERANDS-1) loop
              acc := acc + signed(in_data(i));
            end loop acc_loop;
            out_data <= std_logic_vector(acc);
            --out_valid <= '1';
            out_valid <= in_valid;
       -- end if;
      end if;
    end process l_base_add;

  when others =>
    ln: block
      signal pip_store : prod_array (((NUM_OPERANDS+(DIVIDER_FACTOR-1))/DIVIDER_FACTOR) - 1 downto 0) := (others => (others => '0'));
      signal dv_store : std_logic_vector(((NUM_OPERANDS+(DIVIDER_FACTOR-1))/DIVIDER_FACTOR) - 1 downto 0) := (others => '0');
    begin
      lln_first_stage: for K in pip_store'range generate
        lln_full_K: if K < (pip_store'length-1) generate
        lln_full_K_inst: entity work.RADD generic map(BITWIDTH=>BITWIDTH,PROD_WIDTH=>PROD_WIDTH,
                                         NUM_OPERANDS=>DIVIDER_FACTOR,ORDER=>K+ORDER*20)
                              port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
                                       in_data=>in_data((K+1)*DIVIDER_FACTOR-1 downto K*DIVIDER_FACTOR),
                                       out_data=>pip_store(K),
                                       out_valid=>dv_store(K));
        end generate lln_full_K;
        lln_remaining_K: if K = (pip_store'length-1) generate
        lln_remaining_K_inst: entity work.RADD generic map(BITWIDTH=>BITWIDTH,PROD_WIDTH=>PROD_WIDTH,
                                         NUM_OPERANDS=>NUM_OPERANDS-K*DIVIDER_FACTOR,ORDER=>K+ORDER*20)
                              port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
                                       in_data=>in_data(in_data'length-1 downto K*DIVIDER_FACTOR),
                                       out_data=>pip_store(K),
                                       out_valid=>dv_store(K));
        end generate lln_remaining_K;
      end generate lln_first_stage;
      ln_second_stage_inst: entity work.RADD generic map(BITWIDTH=>BITWIDTH,PROD_WIDTH=>PROD_WIDTH,
                                        NUM_OPERANDS=>((NUM_OPERANDS+(DIVIDER_FACTOR-1))/DIVIDER_FACTOR),ORDER=>32*(ORDER+1))
                            port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>dv_store(dv_store'length-1),
                                     in_data=>pip_store,out_valid=>out_valid,out_data=>out_data);
    end block ln;
 end generate ta;


end architecture rtl;

