-- design of a recursive adder
-- to fix wrong haddoc2 implementation
-- helpful link: https://community.element14.com/technologies/fpga-group/b/blog/posts/the-art-of-fpga-design---post-18


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
    SUM_WIDTH    : integer;
    NUM_OPERANDS : integer;
    ORDER: integer
    );
  port(
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    enable    : in  std_logic;
    in_data   : in  sum_array (0 to NUM_OPERANDS - 1);
    in_valid  : in  std_logic;
    out_data  : out std_logic_vector (SUM_WIDTH-1 downto 0);
    out_valid : out std_logic
    );
end RADD;


architecture rtl of RADD is
  -- max 5!
  constant DIVIDER_FACTOR : integer := 5;

begin

 ta: case NUM_OPERANDS generate
  when 1|2|3|4|5 =>
    l1: process(clk)
      --variable acc: sum_array (0 to NUM_OPERANDS - 1) := (others => (others => '0'));
      --variable acc: std_logic_vector(SUM_WIDTH-1 downto 0) := (others => '0');
      variable acc: signed(SUM_WIDTH-1 downto 0) := (others => '0');
    begin
      if (rising_edge(clk)) then
        if (reset_n = '0') then
          out_valid <= '0';
          out_data <= (others => '0');
        elsif (enable = '1') then
          if (in_valid = '1') then
            --out_valid <= in_valid;
            --acc   := (others => '0');
            acc   := to_signed(0, SUM_WIDTH);
            acc_loop : for i in 0 to NUM_OPERANDS-1 loop
              acc := acc + signed(in_data(i));
            end loop acc_loop;
            out_data <= std_logic_vector(acc);
            out_valid <= '1';
          else
            out_data <= (others => '0');
            out_valid <= '0';
          end if;
        end if;
      end if;
    end process l1;
  --when 3 =>
  --  l3: entity work.CSA3 generic map(PIPELINE=>false)
  --                           port map(CLK=>clk,
  --                                    A=>in_data(0),
  --                                    B=>in_data(1),
  --                                    C=>in_data(2),
  --                                    P=>out_data);
  --      out_valid <= in_valid and enable;
  when others =>
    ln: block
      --constant REC_ADDER_NUM: integer  := integer(ceil(real(IMAGE_WIDTH)/3));
      --constant REC_ADDER_NUM: integer  := integer((real(IMAGE_WIDTH)+2)/3);
      signal pip_store : sum_array (0 to ((NUM_OPERANDS+(DIVIDER_FACTOR-1))/DIVIDER_FACTOR) - 1) := (others => (others => '0'));
      --signal pip_store : sum_array (0 to REC_ADDER_NUM - 1) := (others => (others => '0'));
      signal dv_store : std_logic_vector(0 to ((NUM_OPERANDS+(DIVIDER_FACTOR-1))/DIVIDER_FACTOR) - 1) := (others => '0');
      --signal dv_delay : std_logic_vector(0 to 1);
    begin
      lln: for K in pip_store'range generate
        lli_K: if K < (pip_store'length-1) generate
        ala_K: entity work.RADD generic map(BITWIDTH=>BITWIDTH,SUM_WIDTH=>SUM_WIDTH,
                                         NUM_OPERANDS=>DIVIDER_FACTOR,ORDER=>K+ORDER*20)
                              port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
                                       in_data=>in_data(K*DIVIDER_FACTOR to (K+1)*DIVIDER_FACTOR-1),
                                       out_data=>pip_store(K),
                                       out_valid=>dv_store(K));
        end generate lli_K;
        lle_K: if K = (pip_store'length-1) generate
        ale_K: entity work.RADD generic map(BITWIDTH=>BITWIDTH,SUM_WIDTH=>SUM_WIDTH,
                                         NUM_OPERANDS=>NUM_OPERANDS-K*DIVIDER_FACTOR,ORDER=>K+ORDER*20)
                              port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>in_valid,
                                       in_data=>in_data(K*DIVIDER_FACTOR to in_data'length-1),
                                       out_data=>pip_store(K),
                                       out_valid=>dv_store(K));
        end generate lle_K;
      end generate lln;
      --delay_dv: process(clk)
      --begin
      --  if (reset_n = '0') then
      --    dv_delay <= (others => '0');
      --  elsif(rising_edge(clk)) then
      --    if (enable = '1') and (in_valid = '1') then
      --      dv_delay(0) <= dv_store(0);
      --      dv_delay(1) <= dv_delay(0);
      --    end if;
      --  end if;
      --end process;
      ah: entity work.RADD generic map(BITWIDTH=>BITWIDTH,SUM_WIDTH=>SUM_WIDTH,
                                        NUM_OPERANDS=>((NUM_OPERANDS+(DIVIDER_FACTOR-1))/DIVIDER_FACTOR),ORDER=>32*(ORDER+1))
                            port map(clk=>clk,reset_n=>reset_n,enable=>enable,in_valid=>dv_store(dv_store'length-1),
                                     in_data=>pip_store,out_valid=>out_valid,out_data=>out_data);
    end block ln;
 end generate ta;


end architecture rtl;
