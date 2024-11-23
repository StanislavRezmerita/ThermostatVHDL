library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity THERMOSTAT is
  port (
    CLK            : in std_logic;
    CURRENT_TEMP   : in std_logic_vector(7 downto 0);
    DESIRED_TEMP   : in std_logic_vector(7 downto 0);
    DISPLAY_SELECT : in std_logic;
    COOL           : in std_logic;
    HEAT           : in std_logic;
    FURNACE_HOT    : in std_logic;
    AC_READY       : in std_logic;
    AC_ON          : out std_logic;
    FURNACE_ON     : out std_logic;
    FAN_ON         : out std_logic;
    TEMP_DISPLAY   : out std_logic_vector(7 downto 0)
  );
end THERMOSTAT;

architecture BEHAV of THERMOSTAT is
  
  -- States declarations
  type IO_THR_STATE is (IDLE, COOLON, ACNOWREADY, ACDONE, HEATON, FURNACENOWHOT, FURNACECOOL);
  
  -- Signal declarations
  signal IO_STATE            : IO_THR_STATE := IDLE;
  signal NEXT_IO_STATE       : IO_THR_STATE := IDLE;
  signal CURRENT_TEMP_REG    : std_logic_vector(7 downto 0);
  signal DESIRED_TEMP_REG    : std_logic_vector(7 downto 0);
  signal AC_READY_REG        : std_logic;
  signal FURNACE_HOT_REG     : std_logic;
  signal FAN_ON_REG          : std_logic;
  signal DISPLAY_SELECT_REG  : std_logic;
  signal HEAT_REG            : std_logic;
  signal COOL_REG            : std_logic;
  signal AC_ON_REG           : std_logic;
  signal FURNACE_ON_REG      : std_logic;
  signal TEMP_DISPLAY_REG    : std_logic_vector(7 downto 0);
  signal COUNTDOWN 	     : std_logic_vector(4 downto 0);

begin

  -- Single clocked process for registers
  process (CLK)
  begin
    if rising_edge(CLK) then
      CURRENT_TEMP_REG     <= CURRENT_TEMP;   
      DESIRED_TEMP_REG     <= DESIRED_TEMP;   
      DISPLAY_SELECT_REG   <= DISPLAY_SELECT;   
      HEAT_REG             <= HEAT;   
      COOL_REG             <= COOL;
      AC_READY_REG         <= AC_READY;
      FURNACE_HOT_REG      <= FURNACE_HOT;
    end if;
  end process;

  -- Process for updating the temperature display
  process (CLK)
  begin
    if rising_edge(CLK) then
      if DISPLAY_SELECT_REG = '1' then
        TEMP_DISPLAY_REG <= CURRENT_TEMP_REG;
      else
        TEMP_DISPLAY_REG <= DESIRED_TEMP_REG;
      end if;
    end if;
  end process;

  -- Process for state machine logic
process (CLK)
begin
if CLK'event and CLK = '1' then
    -- Default state
    NEXT_IO_STATE <= IO_STATE;
    case IO_STATE is
      when IDLE =>
        if HEAT_REG = '1' and DESIRED_TEMP_REG > CURRENT_TEMP_REG then
          NEXT_IO_STATE <= HEATON;
        elsif COOL_REG = '1' and DESIRED_TEMP_REG < CURRENT_TEMP_REG then
          NEXT_IO_STATE <= COOLON;
        else
          NEXT_IO_STATE <= IDLE;
        end if;
      when COOLON => 
        if AC_READY_REG = '1' then
          NEXT_IO_STATE <= ACNOWREADY;
        else
          NEXT_IO_STATE <= COOLON;
        end if;
      when ACNOWREADY =>
        if not (COOL_REG = '1' and CURRENT_TEMP_REG > DESIRED_TEMP_REG) then
	  COUNTDOWN 	<= "10100";
          NEXT_IO_STATE <= ACDONE; 
        else
          NEXT_IO_STATE <= ACNOWREADY;
        end if;
      when ACDONE =>
        if AC_READY_REG = '0' and COUNTDOWN = "00000" then
          NEXT_IO_STATE <= IDLE;
        else
          NEXT_IO_STATE <= ACDONE;
	  COUNTDOWN 	<= COUNTDOWN - 1;
        end if;
      when HEATON => 
        if FURNACE_HOT_REG = '1' then
          NEXT_IO_STATE <= FURNACENOWHOT;
        else
          NEXT_IO_STATE <= HEATON;
        end if;
      when FURNACENOWHOT =>
        if not (HEAT_REG = '1' and CURRENT_TEMP_REG < DESIRED_TEMP_REG) then
          NEXT_IO_STATE <= FURNACECOOL; 
      	  COUNTDOWN 	<= "01010";
        else
          NEXT_IO_STATE <= FURNACENOWHOT;
        end if;
      when FURNACECOOL =>
        if FURNACE_HOT_REG = '0' and COUNTDOWN = "00000" then
          NEXT_IO_STATE <= IDLE;
        else
          NEXT_IO_STATE <= FURNACECOOL;
	  COUNTDOWN	<= COUNTDOWN - 1;
        end if;
      when others =>
        NEXT_IO_STATE <= IDLE; 
    end case;
end if;
end process;

  -- Process for state update
  process (CLK)
  begin
    if rising_edge(CLK) then
      IO_STATE <= NEXT_IO_STATE;
    end if;
  end process;

  -- Process for updating state registers
  process(CLK)
  begin
    if rising_edge(CLK) then
      if (IO_STATE = HEATON or IO_STATE = FURNACENOWHOT) then
        FURNACE_ON_REG <= '1';
      else
        FURNACE_ON_REG <= '0';
      end if;
      
      if (IO_STATE = COOLON or IO_STATE = ACNOWREADY) then
        AC_ON_REG <= '1';
      else
        AC_ON_REG <= '0';
      end if;

      if (IO_STATE = IDLE or IO_STATE = HEATON or IO_STATE = COOLON) then
        FAN_ON_REG <= '0';
      else
        FAN_ON_REG <= '1';
      end if;
    end if;
  end process;

  -- Clocked processes for outputs
  process (CLK)
  begin
    if rising_edge(CLK) then
      AC_ON      <= AC_ON_REG;   
      FURNACE_ON  <= FURNACE_ON_REG;
      FAN_ON      <= FAN_ON_REG;
      TEMP_DISPLAY <= TEMP_DISPLAY_REG;   
    end if;
  end process;

end BEHAV;

