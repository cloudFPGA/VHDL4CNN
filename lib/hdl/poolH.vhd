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

