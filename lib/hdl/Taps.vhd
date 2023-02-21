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
    taps_data : out pixel_array (KERNEL_SIZE -1 downto 0);
    out_data  : out std_logic_vector (BITWIDTH-1 downto 0);
    first_tap_valid : out std_logic;
    out_dv    : out std_logic
    );
end Taps;


architecture bhv of Taps is

  signal cell : pixel_array (TAPS_WIDTH-1 downto 0);
  signal dv_buffer : std_logic_vector(TAPS_WIDTH-1 downto 0);

begin

  process(clk)
  --variable i : integer := 0;
  begin
    if(rising_edge(clk)) then
      if (reset_n = '0') then
        cell      <= (others => (others => '0'));
        out_data  <= (others => '0');
        taps_data <= (others => (others => '0'));
        out_dv <= '0';
        first_tap_valid <= '0';
        dv_buffer <= (others => '0');
      -- enable is only equal in_dv for the first "row", hence we still need both here
      elsif (enable = '1') and (in_dv = '1') then
        cell(0) <= in_data;
        -- dv_buffer(0) <= in_dv;
        dv_buffer(0) <= '1';
        for i in (TAPS_WIDTH-1) downto 1 loop
          cell(i) <= cell(i-1);
          dv_buffer(i) <= dv_buffer(i-1);
        end loop;
        taps_data <= cell(KERNEL_SIZE-1 downto 0);
        out_data  <= cell(TAPS_WIDTH-1);
        out_dv <= dv_buffer(TAPS_WIDTH-1);
        first_tap_valid <= '1';
      else
        out_dv <= '0';
        first_tap_valid <= '0';
        out_data  <= (others => '0');
        -- taps_data <= (others => (others => '0'));
        taps_data <= (others => std_logic_vector(to_unsigned(221, taps_data(0)'length)));
      end if;
    end if;
  end process;
end bhv;

