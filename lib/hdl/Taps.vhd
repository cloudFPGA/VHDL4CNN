------------------------------------------------------------------------------
-- Title      : taps
-- Project    : Haddoc2
------------------------------------------------------------------------------
-- File       : taps.vhd
-- Author     : K. Abdelouahab
-- Company    : Institut Pascal
-- Last update: 2018-08-23
------------------------------------------------------------------------------
-- Description: Shift registers used in neighExtractor design.

--                        taps_data(0)                            taps_data(KERNEL_SIZE-1)
--                           ^                                       ^
--                           |                                       |
--               -------     |     -------               -------     |    ---------------------------
--              |        |   |    |        |            |        |   |   |                           |
--  in_data --->|        |---|--> |        |--  ...  -> |        |---|-->|          BUFFER           |---> out_data
--              |        |        |        |            |        |       |  SIZE =(TAPS_WIDTH-KERNEL)|
--              |        |        |        |            |        |       |                           |
--               -------           -------               -------          ---------------------------
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


library work;
use work.cnn_types.all;


entity Taps is
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
    out_dv    : out std_logic
    );
end Taps;


architecture bhv of Taps is

  signal cell : pixel_array (0 to TAPS_WIDTH-1);
  signal dv_buffer : std_logic_vector(0 to TAPS_WIDTH-1);

begin

  process(clk)
    variable i : integer := 0;
  begin

    if (reset_n = '0') then
      cell      <= (others => (others => '0'));
      out_data  <= (others => '0');
      taps_data <= (others => (others => '0'));
      out_dv <= '0';

    elsif (rising_edge(clk)) then
      if (enable = '1') then
        cell(0) <= in_data;
        dv_buffer(0) <= in_dv;
        for i in 1 to (TAPS_WIDTH-1) loop
          cell(i) <= cell(i-1);
          dv_buffer(i) <= dv_buffer(i-1);
        end loop;
        taps_data <= cell(0 to KERNEL_SIZE-1);
        out_data  <= cell(TAPS_WIDTH-1);
        out_dv <= dv_buffer(TAPS_WIDTH-1);
      else
        out_dv <= '0';
      end if;
    end if;
  end process;
end bhv;
