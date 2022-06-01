------------------------------------------------------------------------------
-- Title      : neighExtractor
-- Project    : Haddoc2
------------------------------------------------------------------------------------------------------------
-- File       : neighExtractor.vhd
-- Author     : K. Abdelouahab
-- Company    : Institut Pascal
-- Last update: 2018-08-23
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
    out_data : out pixel_array (0 to (KERNEL_SIZE * KERNEL_SIZE)- 1);
    out_dv   : out std_logic;
    out_fv   : out std_logic
    );
end neighExtractor;

architecture rtl of neighExtractor is

  -- signals
  signal pixel_out : pixel_array(0 to KERNEL_SIZE-1);
  signal dv_out_vec : std_logic_vector(0 to KERNEL_SIZE-1);
  signal tmp_data  : pixel_array (0 to (KERNEL_SIZE * KERNEL_SIZE)- 1);
  -- signal all_valid : std_logic;
  signal s_valid   : std_logic;
  signal buffer_fv : std_logic_vector(KERNEL_SIZE-1 downto 0);
  signal tmp_dv    : std_logic;
  --signal tmp_fv    : std_logic;
  signal delay_dv  : std_logic;
  signal delay_fv  : std_logic;
  signal taps_valid_data : std_logic;
  signal first_tap_valid: std_logic;

  constant WIDTH_COUNTER : integer                           := integer(ceil(log2(real(IMAGE_WIDTH))));
  signal x_cmp       : unsigned (WIDTH_COUNTER-1 downto 0); --:= (others => '0');
  signal y_cmp       : unsigned (WIDTH_COUNTER-1 downto 0); -- := (others => '0');


  -- components
  component taps
    generic (
      BITWIDTH  : integer;
      TAPS_WIDTH  : integer;
      KERNEL_SIZE : integer
      );

    port (
      clk       : in  std_logic;
      reset_n   : in  std_logic;
      enable    : in  std_logic;
      in_dv     : in std_logic;
      in_data   : in  std_logic_vector (BITWIDTH-1 downto 0);
      taps_data : out pixel_array (0 to KERNEL_SIZE -1);
      out_data  : out std_logic_vector (BITWIDTH-1 downto 0);
      first_tap_valid : out std_logic;
      out_dv    : out std_logic
      );
  end component;


   --component bit_taps
   --  generic (
   --    TAPS_WIDTH : integer
   --    );

   --  port (
   --    clk      : in  std_logic;
   --    reset_n  : in  std_logic;
   --    enable   : in  std_logic;
   --    in_data  : in  std_logic;
   --    out_data : out std_logic
   --    );
   --end component;


begin

  -- All valid : Logic and
  -- all_valid <= in_dv and in_fv;
  -- after some consideration: hold taps on dv=0 sounds good
  --s_valid   <= all_valid and enable;
  -- TODO
  s_valid   <= in_fv and enable and in_dv;
  ----------------------------------------------------
  -- Instantiates taps
  ----------------------------------------------------


  taps_inst : for i in 0 to KERNEL_SIZE-1 generate
    -- First line
    gen_1 : if i = 0 generate
      gen1_inst : taps
        generic map(
          BITWIDTH  => BITWIDTH,
          TAPS_WIDTH  => IMAGE_WIDTH-1,
          KERNEL_SIZE => KERNEL_SIZE
          )
        port map(
          clk       => clk,
          reset_n   => reset_n,
          enable    => s_valid,
          in_dv => in_dv,
          in_data   => in_data,
          taps_data => tmp_data(0 to KERNEL_SIZE-1),
          out_data  => pixel_out(0),
          first_tap_valid => first_tap_valid,
          out_dv => dv_out_vec(0)
          );
    end generate gen_1;

    -- line i
    gen_i : if i > 0 and i < KERNEL_SIZE-1 generate
      geni_inst : taps
        generic map(
          BITWIDTH  => BITWIDTH,
          TAPS_WIDTH  => IMAGE_WIDTH-1,
          KERNEL_SIZE => KERNEL_SIZE
          )
        port map(
          clk       => clk,
          reset_n   => reset_n,
          enable    => s_valid,
          in_dv => dv_out_vec(i-1),
          in_data   => pixel_out(i-1),
          taps_data => tmp_data(i * KERNEL_SIZE to KERNEL_SIZE*(i+1)-1),
          out_data  => pixel_out(i),
          first_tap_valid => open,
          out_dv => dv_out_vec(i)
          );
    end generate gen_i;

    -- Last line
    gen_last : if i = (KERNEL_SIZE-1) generate
      gen_last_inst : taps
        generic map(
          BITWIDTH  => BITWIDTH,
          TAPS_WIDTH  => KERNEL_SIZE,
          KERNEL_SIZE => KERNEL_SIZE
          )
        port map(
          clk       => clk,
          reset_n   => reset_n,
          enable    => s_valid,
          in_dv => dv_out_vec(i-1),
          in_data   => pixel_out(i-1),
          taps_data => tmp_data((KERNEL_SIZE-1) * KERNEL_SIZE to KERNEL_SIZE*KERNEL_SIZE - 1),
          out_data  => open,
          first_tap_valid => open,
          out_dv => taps_valid_data
          );
    end generate gen_last;
  end generate taps_inst;


  --------------------------------------------------------------------------
  -- Manage out_dv and out_fv
  --------------------------------------------------------------------------
  -- Embrace your self : Managing the image borders is quite a pain

  dv_proc : process(clk)
  begin
    if (rising_edge(clk)) then
      if (reset_n = '0') then
        x_cmp  <=  (others => '0');
        y_cmp  <=  (others => '0');
        tmp_dv <= '0';
        delay_fv <= '0';
      elsif(enable = '1') and (in_fv = '1') then
        delay_fv <= '1';
        -- askin both means: we have a valid input and output
        -- if (taps_valid_data = '1') and (in_dv = '1') then
        if (taps_valid_data = '1') and (first_tap_valid = '1') then
          if (y_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
            if (x_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
              tmp_dv <= '0';
              x_cmp  <=  (others => '0');
              y_cmp  <=  (others => '0');
              -- elsif(x_cmp< to_unsigned (KERNEL_SIZE - 1, WIDTH_COUNTER)) then
              --     tmp_dv <='0';
              --     x_cmp := x_cmp + to_unsigned(1,WIDTH_COUNTER);
            else
              tmp_dv <= '1';
              x_cmp  <=  x_cmp + to_unsigned(1, WIDTH_COUNTER);
            end if;
          elsif (y_cmp < to_unsigned (KERNEL_SIZE-1, WIDTH_COUNTER)) then
              --tmp_fv <= '0';
            tmp_dv <= '0';
            if (x_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
              x_cmp <=  (others => '0');
              y_cmp <=  y_cmp + to_unsigned(1, WIDTH_COUNTER);
            else
              x_cmp <=  x_cmp + to_unsigned(1, WIDTH_COUNTER);
            end if;
          else
              -- Start of frame
            if (x_cmp = to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) then
              tmp_dv <= '1';
              x_cmp  <=  (others => '0');
              y_cmp  <=  y_cmp + to_unsigned(1, WIDTH_COUNTER);
            elsif (x_cmp < to_unsigned (KERNEL_SIZE - 1, WIDTH_COUNTER)) then
              tmp_dv <= '0';
              x_cmp  <=  x_cmp + to_unsigned(1, WIDTH_COUNTER);
            else
                --tmp_fv <= '1';
              tmp_dv <= '1';
              x_cmp  <=  x_cmp + to_unsigned(1, WIDTH_COUNTER);
            end if;
          end if;
        -- else
        --   tmp_dv <= '0';
        -- end if;
        --  -- when fv = 0
        --  else
        --    x_cmp  := (others => '0');
        --    y_cmp  := (others => '0');
        --    tmp_dv <= '0';
        --    --tmp_fv <= '0';
        --  end if;
        else
          tmp_dv <= '0';
        end if;
      -- When enable = 0
      else
        -- x_cmp  <=  (others => '0');
        -- y_cmp  <=  (others => '0');
        tmp_dv <= '0';
        delay_fv <= '0';
      --tmp_fv <= '0';
      end if;
    end if;
  end process;

  out_data <= tmp_data;
  out_dv <= tmp_dv;
  out_fv <= delay_fv;
end architecture;
