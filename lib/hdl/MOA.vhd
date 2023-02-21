-- Design of a Multi-Operand-Adder block
-- This is a naive implementation with binary adder trees
-- == COMPLETELY REWRITTEN BY NGL ==
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
    in_data   : in  prod_array (NUM_OPERANDS - 1 downto 0);
    in_valid  : in  std_logic;
    out_data  : out std_logic_vector (SUM_WIDTH-1 downto 0);
    out_valid : out std_logic
    );
end MOA;


architecture rtl of MOA is
-- Implementation of Multi Operand Adder with Adder trees

-------------------------------------
---- Removing MOA to Evaluate FMax --
-------------------------------------
--begin
--out_valid <= in_valid;
--out_data  <= "00000000" & in_data(0);


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
    signal array_cast : sum_array(NUM_OPERANDS-1 downto 0);
    signal bias_cast :  std_logic_vector (SUM_WIDTH-1 downto 0);
begin

  tc: for K in array_cast'range generate
    -- array_cast(K) <= (in_data(K)'length-1  downto 0 => in_data(K), others => '0');
    --array_cast(K) <= std_logic_vector(resize(SHIFT_RIGHT(signed(in_data(K)), BITWIDTH), array_cast(K)'length));
    -- TODO: make generic, but -1 because it is 7*7 scale, not 8*8; (and not -2, because one 7 is already accounted for)
    -- array_cast(K) <= std_logic_vector(resize(SHIFT_RIGHT(signed(in_data(K)), BITWIDTH-1), array_cast(K)'length));
    -- TODO: NO BIT-SHIFT! Staying in higher dimension
    --array_cast(K) <= std_logic_vector(resize(signed(in_data(K)), array_cast(K)'length));
    -- NO RESIZE
    --array_cast(K) <= (array_cast(K)'left-1 downto in_data(K)'left => in_data(K)(in_data(K)'left)) & in_data(K);
    array_cast(K) <= (others => in_data(K)(2*BITWIDTH-1));
    array_cast(K)(2*BITWIDTH-1 downto 0) <=  in_data(K);
  end generate tc;

  rec_a: entity work.RADD generic map(BITWIDTH=>BITWIDTH,SUM_WIDTH=>SUM_WIDTH,
                                      NUM_OPERANDS=>NUM_OPERANDS,ORDER=>0)
  port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
           in_data=>array_cast,
           out_data=>tmp_data, out_valid=>tmp_valid);

  bias_cast(SUM_WIDTH - 1 downto 2*BITWIDTH) <= (others => BIAS_VALUE(BITWIDTH-1));
  bias_cast(2*BITWIDTH-1 downto BITWIDTH) <= BIAS_VALUE;
  bias_cast(BITWIDTH -1 downto 0) <= (others => '0');

  process(clk)
  begin
    if (rising_edge(clk)) then
      if (reset_n = '0') then
        out_data <= (others => '0');
        out_valid <= '0';
      -- elsif (enable = '1') then
      elsif (enable = '1') and (tmp_valid = '1') then
        -- if (tmp_valid='1') then
          -- TODO: no bias scaling??
          -- out_data <= std_logic_vector(signed(signed(tmp_data) + signed(BIAS_VALUE)));
          -- resize BIAS to add in higher domain
          -- TODO: shift BITWIDTH or BITWIDTH-1?
          --out_data <= std_logic_vector(signed(signed(tmp_data) + signed(resize(SHIFT_LEFT(signed(BIAS_VALUE), BITWIDTH), tmp_data'length))));
          --out_data <= std_logic_vector(signed(tmp_data) + resize(SHIFT_LEFT(signed(BIAS_VALUE), SCALE_BITS), tmp_data'length));
          -- no RESIZE!
          out_data <= std_logic_vector(signed(tmp_data) + signed(bias_cast));
          out_valid <= '1';
        --else
        --  --out_data <= (others => '0');
        --  out_data <= std_logic_vector(to_unsigned(112, SUM_WIDTH));
        --  out_valid <= '0';
        --end if;
      else
        out_data <= (others => '0');
        --out_data <= std_logic_vector(to_unsigned(114, SUM_WIDTH));
        --cast_loop: for i in 0 to NUM_OPERANDS - 1 loop
        --    out_data(i) <= std_logic_vector(resize(signed(in_data(i)), out_data(i)'length));
        --end loop;
        -- out_data <= std_logic_vector(resize(signed(in_data(0)), out_data'length));
        out_valid <= '0';
      end if;
    end if;
  end process;




end architecture;

