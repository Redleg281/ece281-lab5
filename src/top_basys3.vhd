--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
  
signal w_cycle: std_logic_vector (3 downto 0);
signal w_TDM4_clk: std_logic;
signal w_i_A: std_logic_vector (7 downto 0);
signal w_i_B: std_logic_vector (7 downto 0);
signal w_op : std_logic_vector (2 downto 0);
signal w_result:std_logic_vector (7 downto 0);
signal w_mux_result:std_logic_vector (7 downto 0);

signal w_hund: std_logic_vector(3 downto 0);
signal w_tens: std_logic_vector(3 downto 0);
signal w_ones: std_logic_vector(3 downto 0);
signal w_sign: std_logic_vector(3 downto 0);


signal w_hex: std_logic_vector(3 downto 0);
signal w_seg_out: std_logic_vector(6 downto 0);

signal w_sel: std_logic_vector(3 downto 0);

  
  
	-- declare components and signals
    
component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component twos_comp;
    
component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end component ALU;


component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
end component TDM4;

component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end component controller_fsm;


component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
end component clock_divider;

component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
end component sevenseg_decoder;



begin
	-- PORT MAPS ----------------------------------------

clock_Div_inst : clock_divider
	generic map (k_DIV => 50000)
	port map(
	   i_clk => clk,
	   i_reset => btnU,
	   o_clk => w_TDM4_clk
	);
	
controller_fsm_inst : controller_fsm port map(
        
    i_reset => btnU,
    i_adv => btnC,
    o_cycle => w_cycle ---maybe add 3 down to 0
    );


DFlipFlop: process(w_cycle)---- maybe have to add a signal, not directly link to sw (7-0)
begin 
    if rising_edge(w_cycle(0)) then
        w_i_A <= sw(7 downto 0);
     end if;
     if rising_edge(w_cycle(1)) then
        w_i_B <= sw(7 downto 0);
     end if;
     if rising_edge(w_cycle(2)) then
        w_op <= sw(2 downto 0);
     end if;
end process;


ALU_inst: ALU port map(
    i_op => w_op,
    i_A => w_i_A,
    i_B => w_i_B,
    o_flags => led(15 downto 12),
    o_result => w_result
);

---mux after ALU:
MuxProc : process(w_cycle)
begin
--    with w_cycle select
--    w_mux_result <= w_i_A when "0001",  
--            w_i_B when "0010",
--            w_result when "0100",
--            "00000000" when "1000",
--            "00000000" when others;
    if (w_cycle = "0001") then
    w_mux_result <= w_i_A;
    elsif (w_cycle = "0010") then
    w_mux_result <= w_i_B;
    elsif(w_cycle = "0100") then
    w_mux_result <= w_result;
    end if;
end process;
        
TwosComp_inst: twos_comp port map(
    i_bin => w_mux_result,
    o_sign => w_sign(0),
    o_hund => w_hund,
    o_tens => w_tens,
    o_ones => w_ones
);	

TDM4_inst: TDM4
	generic map (k_WIDTH => 4)
    port map (
        i_reset => btnU,
        i_clk => w_TDM4_clk,
        i_D3 => w_sign,
        i_D2 => w_hund,
        i_D1 => w_tens,
        i_D0 => w_ones,
        o_data => w_hex,
        o_sel => w_sel      
	);
	
sevenseg_decoder_inst: sevenseg_decoder 
     port map(
     i_Hex => w_hex,
     o_seg_n => w_seg_out
     );
     
--seg <= w_seg_out;
 
an <= w_sel;
led(3 downto 0) <= w_cycle;


seg <= "1111111" when w_cycle= "1000" else
         w_seg_out when not(w_sel = "0111") else
         "0111111" when (w_sign = "0001") else
         "1111111";--- test case
	-- CONCURRENT STATEMENTS ----------------------------
	
--doc: C3C Anders looked over my work to help see why I was getting an error on one of the flags on the test bench, the problem was I mistakenly had a 1 where it should have been a 0
--      We used chatGPT when we were stuck on new parts that we had not learned yet. We did not overlly use this tool or directly paste sections of code from it
end top_basys3_arch;
