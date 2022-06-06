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

  type pixel_matrix is array (integer range <>) of pixel_array(0 to IMAGE_WIDTH-1);

  --signal kernel_data  : pixel_array (0 to (KERNEL_SIZE * KERNEL_SIZE)- 1);
  signal pixel_buffer : pixel_matrix(0 to KERNEL_SIZE - 1);

  constant WIDTH_COUNTER : integer                           := integer(ceil(log2(real(IMAGE_WIDTH)))) + 2;
  signal x_cmp       : unsigned (WIDTH_COUNTER-1 downto 0); --:= (others => '0');
  signal y_cmp       : unsigned (WIDTH_COUNTER-1 downto 0); -- := (others => '0');


begin


  dv_proc : process(clk)
  begin
    if (rising_edge(clk)) then
      if (reset_n = '0') or (in_fv = '0') then
        x_cmp  <=  (others => '0');
        y_cmp  <=  (others => '0');
        out_dv <= '0';
        out_fv <= '0';
        --reset_taps_n <= '0';
        out_data <= (others => (others => '0'));
        pixel_buffer <= (others => (others => (others => '0')));
        --kernel_data <= (others => (others => '0'));
      elsif(enable = '1') and (in_fv = '1') then
        --reset_taps_n <= '1';
        out_fv <= '1';
        if (in_dv = '1') then
          if ( x_cmp >= to_unsigned (KERNEL_SIZE - 1, WIDTH_COUNTER)) and ( x_cmp <= to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) and (y_cmp >= to_unsigned (KERNEL_SIZE-1, WIDTH_COUNTER)) then
            out_dv <= '1';
          else
            out_dv <= '0';
          end if;
          if (x_cmp = to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) then
            x_cmp  <=  (others => '0');
            if (y_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
              --reset_taps_n <= '0';
            --out_dv <= '0';  NO, is still valid
              y_cmp  <=  (others => '0');
            else
              y_cmp  <=  y_cmp + to_unsigned(1, WIDTH_COUNTER);
            end if;
          else
            x_cmp  <=  x_cmp + to_unsigned(1, WIDTH_COUNTER);
          end if;
            --if (x_cmp = to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) and (y_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
            --  -- reset buffer
            --  pixel_buffer <= (others => (others => (others => '0')));
            --  --kernel_data <= (others => (others => '0'));
            --else
            --    -- advance buffer
            --end if;
            -- advance buffer
          pixel_buffer(0)(0) <= in_data;
          first_line_loop: for j in 1 to (IMAGE_WIDTH - 1) loop
            pixel_buffer(0)(j) <= pixel_buffer(0)(j-1);
          end loop first_line_loop;
          outer_buffer_loop: for i in 1 to (KERNEL_SIZE -1 ) loop
            pixel_buffer(i)(0) <= pixel_buffer(i-1)(IMAGE_WIDTH - 1);
            inner_buffer_loop: for j in 1 to (IMAGE_WIDTH - 1) loop
              pixel_buffer(i)(j) <= pixel_buffer(i)(j-1);
            end loop inner_buffer_loop;
          end loop outer_buffer_loop;
          -- set out data
          kernel_loop: for k in 0 to (KERNEL_SIZE-1) loop
            out_data(k*KERNEL_SIZE to (k+1)*KERNEL_SIZE - 1) <= pixel_buffer(k)(0 to KERNEL_SIZE - 1);
          end loop kernel_loop;
        else
          --reset_taps_n <= '0';
          out_dv <= '0';
          out_data <= (others => std_logic_vector(to_unsigned(42, out_data(0)'length)));
        end if;
      -- When enable = 0
      else
        out_dv <= '0';
        out_fv <= '0';
        --reset_taps_n <= '0';
        out_data <= (others => std_logic_vector(to_unsigned(43, out_data(0)'length)));
      end if;
    end if;
  end process;

end architecture;
