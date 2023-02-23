------------------------------------------------------------------------------
-- Title      : neighExtractor
-- Project    : Haddoc2
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
  signal vertcal_cnt: unsigned(WIDTH_COUNTER - 1 downto 0);

begin

  full_buffering: process(clk)
    variable tmp_valid: std_logic := '1'; -- 1!
    variable position_valid: std_logic := '1'; -- 1!
  begin
    if (reset_n = '0') or (in_fv = '0') then
      pixel_buffer <= (others => (others => (others => '0')));
      valid_buffer <= (others => (others => '0'));
      -- horizontal_pos_buffer <= (others => (others => (others => '0')));
      vertical_pos_buffer <= (others => (others => (others => '0')));
      horizontal_cnt <= (others => '0');
      vertical_cnt <= (others => '0');

      out_data <= (others => (others => '0'));
      out_dv <= '0';
      out_fv <= '0';
    else
      if (enable = '1') then
        out_fv <= '1';
        
        -- advance buffers
        pixel_buffer(0)(0) <= in_data;
        valid_buffer(0)(0) <= in_dv;
        -- horizontal_pos_buffer(0)(0) <= horizontal_cnt;
        vertical_pos_buffer(0)(0) <= vertical_cnt;

        first_line_loop: for j in 1 to (IMAGE_WIDTH - 1) loop
          pixel_buffer(0)(j) <= pixel_buffer(0)(j-1);
          valid_buffer(0)(j) <= valid_buffer(0)(j-1);
          -- horizontal_pos_buffer(0)(j) <= horizontal_pos_buffer(0)(j-1);
          vertical_pos_buffer(0)(j) <= vertical_pos_buffer(0)(j-1);
        end loop first_line_loop;

        outer_buffer_loop: for i in 1 to (KERNEL_SIZE - 1) loop
          pixel_buffer(i)(0) <= pixel_buffer(i-1)(IMAGE_WIDTH - 1);
          valid_buffer(i)(0) <= valid_buffer(i-1)(IMAGE_WIDTH - 1);
          -- horizontal_pos_buffer(i)(0) <= horizontal_pos_buffer(i-1)(IMAGE_WIDTH - 1);
          vertical_pos_buffer(i)(0) <= vertical_pos_buffer(i-1)(IMAGE_WIDTH - 1);
          inner_buffer_loop: for j in 1 to (IMAGE_WIDTH - 1) loop
            pixel_buffer(i)(j) <= pixel_buffer(i)(j-1);
            valid_buffer(i)(j) <= valid_buffer(i)(j-1);
            -- horizontal_pos_buffer(i)(j) <= horizontal_pos_buffer(i)(j-1);
            vertical_pos_buffer(i)(j) <= vertical_pos_buffer(i)(j-1);
          end loop inner_buffer_loop;
        end loop outer_buffer_loop;
        
        -- set out data
        kernel_loop: for k in 0 to (KERNEL_SIZE-1) loop
          out_data((k+1)*KERNEL_SIZE - 1 downto k*KERNEL_SIZE) <= pixel_buffer(k)(KERNEL_SIZE - 1 downto 0);
        end loop kernel_loop;
        
        -- calculate valid
        outer_valid_loop: for k in 0 to (KERNEL_SIZE - 1) loop
          inner_valid_loop: for l in 0 to (KERNEL_SIZE - 1) loop
            tmp_valid := tmp_valid and valid_buffer(k)(l);
          end loop inner_valid_loop;
          inner_pos_loop: for p in 1 to (KERNEL_SIZE - 1) loop
             --if (vertical_pos_buffer(k)(p-1) = vertical_pos_buffer(k)(p)) then
             --  position_valid := position_valid;
             --else
            if (vertical_pos_buffer(k)(p-1) /= vertical_pos_buffer(k)(p)) then
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
          else
            vertical_cnt <= vertical_cnt + to_unsigned(1, WIDTH_COUNTER);
          end if;
        else
          horizontal_cnt <= horizontal_cnt + to_unsigned(1, WIDTH_COUNTER);
        end if;
      else
        out_data <= (others => (others => '0'));
        out_dv <= '0';
        out_fv <= '0';
      end if;
      end if;
    end process full_buffering;




  -- dv_proc : process(clk)
  -- begin
  --   if (rising_edge(clk)) then
  --     if (reset_n = '0') or (in_fv = '0') then
  --       x_cmp  <=  (others => '0');
  --       y_cmp  <=  (others => '0');
  --       out_dv <= '0';
  --       delay_valid <= '0';
  --       out_fv <= '0';
  --       --reset_taps_n <= '0';
  --       out_data <= (others => (others => '0'));
  --       pixel_buffer <= (others => (others => (others => '0')));
  --     --kernel_data <= (others => (others => '0'));
  --     elsif(enable = '1') and (in_fv = '1') then
  --       --reset_taps_n <= '1';
  --       out_fv <= '1';
  --       out_dv <= delay_valid;

  --       if (in_dv = '1') then
  --         if ( x_cmp >= to_unsigned (KERNEL_SIZE - 1, WIDTH_COUNTER)) and ( x_cmp <= to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) and (y_cmp >= to_unsigned (KERNEL_SIZE-1, WIDTH_COUNTER)) then
  --           delay_valid <= '1';
  --         else
  --           delay_valid <= '0';
  --         end if;
  --         if (x_cmp = to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) then
  --           x_cmp  <=  (others => '0');
  --           if (y_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
  --             --reset_taps_n <= '0';
  --             --delay_valid <= '0';  NO, is still valid
  --             y_cmp  <=  (others => '0');
  --           else
  --             y_cmp  <=  y_cmp + to_unsigned(1, WIDTH_COUNTER);
  --           end if;
  --         else
  --           x_cmp  <=  x_cmp + to_unsigned(1, WIDTH_COUNTER);
  --         end if;
  --         --if (x_cmp = to_unsigned (IMAGE_WIDTH-1, WIDTH_COUNTER)) and (y_cmp = to_unsigned (IMAGE_WIDTH - 1, WIDTH_COUNTER)) then
  --         --  -- reset buffer
  --         --  pixel_buffer <= (others => (others => (others => '0')));
  --         --  --kernel_data <= (others => (others => '0'));
  --         --else
  --         --    -- advance buffer
  --         --end if;
  --         -- advance buffer
  --         pixel_buffer(0)(0) <= in_data;
  --         first_line_loop: for j in (IMAGE_WIDTH - 1) downto 1 loop
  --           pixel_buffer(0)(j) <= pixel_buffer(0)(j-1);
  --         end loop first_line_loop;
  --         outer_buffer_loop: for i in (KERNEL_SIZE -1 ) downto 1 loop
  --           pixel_buffer(i)(0) <= pixel_buffer(i-1)(IMAGE_WIDTH - 1);
  --           inner_buffer_loop: for j in (IMAGE_WIDTH - 1) downto 1 loop
  --             pixel_buffer(i)(j) <= pixel_buffer(i)(j-1);
  --           end loop inner_buffer_loop;
  --         end loop outer_buffer_loop;
  --         -- set out data
  --         kernel_loop: for k in (KERNEL_SIZE-1) downto 0 loop
  --           out_data((k+1)*KERNEL_SIZE - 1 downto k*KERNEL_SIZE) <= pixel_buffer(k)(KERNEL_SIZE - 1 downto 0);
  --         end loop kernel_loop;
  --         -- unused elements of last row will be removed anyhow by synthesis
  --       else
  --         --reset_taps_n <= '0';
  --         delay_valid <= '0';
  --         out_data <= (others => std_logic_vector(to_unsigned(42, out_data(0)'length)));
  --       end if;

  --     -- When enable = 0
  --     else
  --       out_dv <= delay_valid;
  --       delay_valid <= '0';
  --       out_fv <= '0';
  --       --reset_taps_n <= '0';
  --       out_data <= (others => std_logic_vector(to_unsigned(43, out_data(0)'length)));
  --     end if;
  --   end if;
  -- end process;

end architecture;


