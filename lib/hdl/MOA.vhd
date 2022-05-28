-- Design of a Multi-Operand-Adder block
-- This is a naive implementation with binary adder trees
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
library work;
use work.cnn_types.all;

entity MOA is
  generic(
    BITWIDTH     : integer;
    SUM_WIDTH    : integer;
    NUM_OPERANDS : integer;
    BIAS_VALUE   : std_logic_vector
    );

  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    enable    : in  std_logic;
    in_data   : in  prod_array (0 to NUM_OPERANDS - 1);
    in_valid  : in  std_logic;
    out_data  : out std_logic_vector (SUM_WIDTH-1 downto 0);
    out_valid : out std_logic
    );
end MOA;


architecture rtl of MOA is
-- Implementation of Multi Operand Adder with Adder trees

-----------------------------------
-- Removing MOA to Evaluate FMax --
-----------------------------------
-- begin
-- out_valid <= in_valid;
-- out_data  <= "00000000" & in_data(0);
-- end architecture;


---------------------------------
-- Assynchronous implmentation --
---------------------------------
--signal s_acc   : std_logic_vector (SUM_WIDTH-1 downto 0);
--signal pip_acc : prod_array (0 to NUM_OPERANDS - 1);
--begin
--  add_process : process(clk)
--    variable v_acc : std_logic_vector (SUM_WIDTH-1 downto 0) := (others => '0');
--  begin
--    if (reset_n = '0') then
--      v_acc     := (others => '0');
--      out_valid <= '0';
--
--    elsif (rising_edge(clk)) then
--      if (enable = '1') then
--        if (in_valid = '1') then
--          acc_loop : for i in 0 to NUM_OPERANDS-1 loop
--            v_acc := v_acc + in_data(i);
--          end loop acc_loop;
--          v_acc := v_acc + BIAS_VALUE;
--        end if;
--      end if;
--      s_acc     <= v_acc;
--      v_acc     := (others => '0');
--      out_valid <= in_valid;
--    end if;
--  end process;
--  out_data <= s_acc;

-------------------------------
---- Pipelined implmentation --
-------------------------------
-- signal pip_acc : sum_array (0 to NUM_OPERANDS - 1) := (others => (others => '0'));
-- signal dv_delay : std_logic_vector(0 to NUM_OPERANDS - 1);
--
--begin
--   process(clk)
--   begin
--     if (reset_n = '0') then
--       pip_acc   <= (others => (others => '0'));
--       dv_delay <= (others => '0');
--       out_valid <= '0';
--
--     elsif(rising_edge(clk)) then
--       if (enable = '1') then
--         if (in_valid = '1') then
--           pip_acc(0)(2*BITWIDTH-1 downto 0) <= in_data(0);
--           dv_delay(0) <= in_valid;
--           acc_loop : for i in 1 to NUM_OPERANDS-1 loop
--             pip_acc(i) <= pip_acc(i-1) + in_data(i);
--             dv_delay(i) <= dv_delay(i-1);
--           end loop acc_loop;
--           out_valid <= '1';
--         else
--           pip_acc   <= (others => (others => '0'));
--           dv_delay <= (others => '0');
--         end if;
--         out_data <= pip_acc(NUM_OPERANDS-1) + BIAS_VALUE;
--         out_valid <= dv_delay(NUM_OPERANDS - 1);
--       else
--         out_data <= (others => (others => '0'));
--         out_valid <= '0';
--       end if;
--     end if;
--   end process;

-------------------------------
-- recursive implementation
-- fixes original haddoc2 implementation
-------------------------------

    signal tmp_data: std_logic_vector (SUM_WIDTH-1 downto 0);
    signal tmp_valid: std_logic;
    signal array_cast : sum_array(0 to NUM_OPERANDS-1);
begin

  tc: for K in array_cast'range generate
    array_cast(K)(2*BITWIDTH-1 downto 0) <= in_data(K);
  end generate tc;

  rec_a: entity work.RADD generic map(BITWIDTH=>BITWIDTH,SUM_WIDTH=>SUM_WIDTH,
                                  NUM_OPERANDS=>NUM_OPERANDS,ORDER=>0)
                      port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
                               in_data=>array_cast,
                               out_data=>tmp_data, out_valid=>tmp_valid);

  process(clk)
  begin
    if (reset_n = '0') then
      out_data <= (others => '0');
      out_valid <= '0';

    elsif(rising_edge(clk)) then
      if (enable = '1') and (tmp_valid='1') then
        out_data <= tmp_data + BIAS_VALUE;
        out_valid <= '1';
      else
        out_data <= (others => '0');
        out_valid <= '0';
      end if;
    end if;
  end process;




end architecture;
