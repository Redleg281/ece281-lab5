----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
signal w_CoutAdd : std_logic;
signal w_ResAdd : std_logic_vector (7 downto 0);
signal w_CoutSub : std_logic;
signal w_ResSub : std_logic_vector (7 downto 0);
signal w_ResAnd : std_logic_vector (7 downto 0);
signal w_ResOr : std_logic_vector (7 downto 0);
signal w_iBNot : std_logic_vector (7 downto 0);
signal w_zeroFlag : std_logic;
signal w_overflowFlag : std_logic;
signal w_carryFlag : std_logic;
signal w_negativeFlag : std_logic;
signal w_result : std_logic_vector (7 downto 0);




component ripple_adder is 
    Port(
           A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC
           );
     end component ripple_adder;
   
begin
    w_iBNot <= not i_B;
    
    Add_inst : ripple_adder
    Port map (
        A => i_A,
        B => i_B,
        Cin => '0',
        S => w_ResAdd,
        Cout => w_CoutAdd
    );
    
    Subinst : ripple_adder
    Port map (
        A => i_A,
        B => w_iBNot,
        Cin => '1',
        S => w_ResSub,
        Cout => w_CoutSub
    );
    
    w_ResAnd <= i_A and i_B;
    w_ResOr <= i_A or i_B;
    
    
process is 
begin 

    if i_Op = "000" then
        w_result <= w_ResAdd;
    elsif i_Op = "001" then
        w_result <= w_ResSub;
    elsif i_Op = "010" then
        w_result <= w_ResAnd;
    elsif i_Op = "011" then
        w_result <= w_ResOr;
    else
        w_result <= "00000000";
    end if;
        o_result <= w_result;
    
 ---------- Flags
 
    if w_result = "00000000" then
        w_zeroFlag <= '1';
    else 
        w_zeroFlag <= '0';
    end if;
        
    if w_result(7) = '1' then
        w_negativeFlag <= '1';
     else 
        w_negativeFlag <= '0';
     end if;
    
    if w_CoutSub = '1' and i_Op = "001" then
        w_carryFlag <= '1';
    elsif w_CoutAdd = '1' and i_Op = "000" then
        w_carryFlag <= '1';
    else 
        w_carryFlag <= '0';
    end if;
    
    
end process;
            


end Behavioral;
