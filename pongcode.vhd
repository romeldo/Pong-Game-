library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA is
    Port ( clk : in  STD_LOGIC;
           H : out  STD_LOGIC;
           V : out  STD_LOGIC;
           DAC_CLK : inout  STD_LOGIC;
           Bout : out  STD_LOGIC_VECTOR (7 downto 0);
           Gout : out  STD_LOGIC_VECTOR (7 downto 0);
           Rout : out  STD_LOGIC_VECTOR (7 downto 0);
           SW : in  STD_LOGIC_VECTOR (3 downto 0));
end VGA;

architecture Behavioral of VGA is

--------------HSYNC COUNTER AND VSYNC COUNTER------------------
signal hcounter : integer range 0 to 800;
signal vcounter : integer range 0 to 525;
---------------------GAME CLOCK---------------------------------
signal clk100: std_logic;
signal clk_counter : integer := 0;
--------------------------------------------------------------
--PIXEL X AND PIXEL Y
signal x : integer range 0 to 639; --PIXEL X COUNTER
signal y : integer range 0 to 479; --PIXEL Y COUNTER
------------------------------------------------------------
constant MAX_Y : integer := 480; --MAX Y PIXEL IN ACTIVE REGION
constant MAX_X : integer := 640; --MAX X PIXEL IN ACTIVE REGION
----------------STATIC FRAME CONSTANTS---------------------------
constant leftwall_r: integer := 30; -- LEFT WALL RIGHT BOUNDARY
constant leftwall_l: integer := 10; -- LEFT WALL LEFT BOUNDARY
constant leftwall_b_y: integer := 160;-- LEFT WALL LOWER BOUNDARY
constant leftwall_u_y: integer := 310; -- LEFT WALL UPPER BOUNDARY

constant rightwall_r: integer := 630;-- RIGHT WALL RIGHT BOUNDARY
constant rightwall_l: integer := 610;-- RIGHT WALL LEFT BOUNDARY
constant rightwall_b_y: integer := 160;-- RIGHT WALL LOWER BOUNDARY
constant rightwall_u_y: integer := 310; -- RIGHT WALL UPPER BOUNDARY
------------------RIGHT BAR----------------------------------------
constant bar_r_size : integer := 100; -- RIGHT BAR LENGTH
constant bar_r_x_l : integer:=585; -- RIGHT BAR LEFT X BOUNDARY
constant bar_r_x_r : integer:=600;-- RIGHT BAR RIGHT X BOUNDARY
constant bar_v: integer := 4; -- BAR VELOCITY FOR RIGHT AND LEFT 
signal bar_r_y_t : integer:= 220; ---- RIGHT BAR TOP Y BOUNDARY
signal bar_r_y_b : integer:= 320;---- RIGHT BAR BOTTOM Y BOUNDARY
signal bar_r_on : std_logic; --RIGHT BAR 'ON' SIGNAL
------------------LEFT BAR----------------------------------------
constant bar_l_size : integer := 100; -- LEFT BAR LENGTH
constant bar_l_x_l : integer:=40;-- LEFT BAR LEFT X BOUNDARY
constant bar_l_x_r : integer:=55;-- LEFT BAR RIGHT X BOUNDARY
signal bar_l_y_t : integer:= 220;-- LEFT BAR TOP Y BOUNDARY
signal bar_l_y_b : integer:= 320;-- LEFT BAR BOTTOM Y BOUNDARY
signal bar_l_on : std_logic;-- LEFT BAR 'ON' SIGNAL
-----------------------BALL-------------------------
constant BALL_V_P:integer := 5; --POSITIVE BALL VELOCITY
constant BALL_V_N:integer := -5; --NEGATIVE BALL VELOCITY
signal ball_x_l:integer:= 310; --BALL LEFT X BOUNDARY START IN MIDDLE
signal ball_x_r:integer:= 330; --BALL RIGHT X BOUNDARY START IN MIDDLE
signal ball_y_t:integer:= 230; --BALL TOP Y BOUNDARY START IN MIDDLE
signal ball_y_b:integer:= 250;--BALL BOTTOM Y BOUNDARY START IN MIDDLE
signal x_delta: integer; --SETS BALL X VELOCITY
signal y_delta: integer; --SETS BALL Y VELOCITY
signal ball_on : STD_LOGIC; --BALL 'ON' SIGNAL
-------------------------------------------------------------------
signal reset : STD_LOGIC; --RESET SIGNAL

begin
---------------------------------------------------
--DAC_CLK
-- generate a 25Mhz clock
process (clk)
	begin
	if clk'event and clk='1' then
		DAC_CLK <= not DAC_CLK;
	end if;
end process;
---------------------------------------------------
------GAME CLOCK-----------------------------
process(clk)	
	begin
		if clk'event and clk='1' then
			clk_counter <= clk_counter + 1;
				if (clk_counter = 500000) then
                clk100 <= NOT(clk100);
                clk_counter <= 0;               
            end if;
		end if;
end process;
------------------------------------------------------------
--updating right bar
process (SW,clk100)
begin
	if clk100'EVENT and clk100 = '1' then
		if SW(1) = '0' then  
			if bar_r_y_b < 450 then -- IF NOT REACH BOTTOM WALL
				bar_r_y_b <= bar_r_y_b + BAR_V;
				bar_r_y_t <= bar_r_y_t + BAR_V;
			end if;
		elsif SW(1)= '1' then
			if bar_r_y_t > 30 then -- IF NOT REACH TOP WALL
				bar_r_y_b <= bar_r_y_b - BAR_V;
				bar_r_y_t <= bar_r_y_t - BAR_V;
			end if;
		end if;
	end if;
end process;
--------------------------------------------------------------
--updating left bar
process (SW,clk100)
begin
	if clk100'EVENT and clk100 = '1' then
		if SW(0) = '0' then 
			if (bar_l_y_b < 450) then -- IF NOT REACH BOTTOM WALL
				bar_l_y_b <= bar_l_y_b + BAR_V;
				bar_l_y_t <= bar_l_y_t + BAR_V;
			end if;
		elsif SW(0)= '1' then
			if bar_l_y_t > 30 then -- IF NOT REACH TOP WALL
				bar_l_y_b <= bar_l_y_b - BAR_V;
				bar_l_y_t <= bar_l_y_t - BAR_V;
			end if;
		end if;
	end if;
end process;
----------------------------------------------------------
------update ball velocity
process(clk100,ball_y_t,ball_y_b,ball_x_l,ball_x_r,x_delta,y_delta)
begin
if clk100'EVENT and clk100 = '1' then
	-- when ball reaches top wall,  y_delta<= 5 , to make it go down
	if ball_y_t < 30 then
		y_delta <= BALL_V_P;
	-- when ball reaches bottom wall, y_delta<= -5 , to make it go up
	elsif ball_y_b > 450 then 
		y_delta <= BALL_V_N;
	-- when ball hits right bar, x_delta <= -5, to make it go left
	elsif BAR_r_X_L <= ball_x_r and ball_x_r <= bar_r_x_r then 
		if bar_r_y_t <= ball_y_b and ball_y_t <= bar_r_y_b then
			x_delta <= ball_v_n;
		end if;
	-- when ball hits left bar, x_delta <= 5, to make it go right
	elsif BAR_l_X_L <= ball_x_l and ball_x_l <= bar_l_x_r then
		if bar_l_y_t <= ball_y_b and ball_y_t <= bar_l_y_b then
			x_delta <= ball_v_p;
		end if;
	-- when ball hits left wall, x_delta <= 5, to make it go right
	elsif	leftwall_l <= ball_x_l and ball_x_l <= leftwall_r then --left wall
		if ball_y_b <= leftwall_b_y or ball_y_t > leftwall_u_y then
			x_delta <= ball_v_p;
		end if;
		-- when ball hits right wall, x_delta <= -5, to make it go left
	elsif rightwall_l <= ball_x_r and  ball_x_r <= rightwall_r then
		if ball_y_b <= leftwall_b_y or ball_y_t > leftwall_u_y then
			x_delta <= ball_v_n;
		end if;
	end if;
end if;
end process;


-----------------------------------------------------------
---------------update ball coordinates
process(clk100,x_delta,y_delta,reset)
begin
	if clk100'EVENT and clk100 = '1' then
	--SET TO MIDDLE COORDINATES TO START AT MIDDLE ONCE REACH THE GOAL 
		if reset = '1' then
			ball_x_r <= 330; 
			ball_x_l <= 310;
			ball_y_t <= 230;
			ball_y_b <= 250;
		else
	--ADD x_delta and y_delta to x and y axis boundaries of ball
			ball_x_r <= ball_x_r + x_delta;
			ball_x_l <= ball_x_l + x_delta;
			ball_y_t <= ball_y_t + y_delta;
			ball_y_b <= ball_y_b + y_delta;
		end if;
	end if;
end process;
------------------------------------------------------------
--------PROCESS TO SET RGB SIGNALS TO SHOW ON SCREEN--------
--------THIS PROCESS RESPONSIBLE FOR ALL PRINTING ON SCREEN------
p2: process (DAC_CLK, hcounter, vcounter,bar_r_on)
	variable x: integer range 0 to 640;
	variable y: integer range 0 to 480;
begin
	x := hcounter - 160;
	y := vcounter - 45;
if DAC_CLK'event and DAC_CLK = '1' then
	----------------------TURN RIGHT BAR ON ------------------------
	if x > bar_r_x_l and x < bar_r_x_r then
		if y > bar_r_y_t and y< bar_r_y_b then
			bar_r_on <= '1';
		else
			bar_r_on<='0';
		end if;
	else
		bar_r_on <= '0';
	end if;
----------------------TURN LEFT BAR ON ------------------------
	if x > bar_l_x_l and x < bar_l_x_r then
		if y > bar_l_y_t and y< bar_l_y_b then
			bar_l_on <= '1';
		else
			bar_l_on<='0';
		end if;
	else
		bar_l_on <= '0';
	end if;
----------------------TURN BALL ON----------------------------------
	if x > ball_x_l and x < ball_x_r then
		if y > ball_y_t and y < ball_y_b then
			ball_on <= '1';
		else
			ball_on <= '0';
		end if;
	else
		ball_on <= '0';
	end if;
---------------------------SET RESET---------------------------
	if ball_x_l < 5 then
		reset <= '1';
	elsif ball_x_r > 635 then
		reset <= '1';
	else 
		reset <= '0';
	end if;
---------------------------------------------------------	
	--setting Hsync signal to '0' when 16 < hcounter < 113
	if hcounter > 16 and hcounter < 113 then
		H <= '0';
	else
		H <= '1';
	end if;
	--setting Vsync signal to '0' when 10 < vcounter < 13
	if vcounter > 10 and vcounter < 13 then
		V <= '0';
	else
		V <= '1';
	end if;
	
-- horizontal counts from 0 to 799
	hcounter <= hcounter+1;
		if hcounter = 800 then
			vcounter <= vcounter+1;
			hcounter <= 0;
		end if;
		
-- vertical counts from 0 to 524
		if vcounter = 525 then 
			vcounter <= 0;
		end if;
---------IF HOR. SCAN AND VER. SCAN WITHIN DISPLAY REGION
	if x < 640 and y < 480 then
			--GREEN BACKGROUND/FIELD
			Rout <= "00000000"; 
			Gout <= "11111111"; 
			Bout <= "00000000";
			
---------****STATIC FRAME****-----------
				-- UPPER LEFT WALLL-- WHITE
		if (x > 10 and x < 30) and (y > 10 and y < 160 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";
		end if;
				-- LOWER LEFT WALL-- WHITE
		if (x > 10 and x < 30) and (y > 310 and y < 470 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";

		end if;
				-- UPPER RIGHT WALL -- WHITE
		if (x > 610 and x < 630) and (y > 10 and y < 160 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";

		end if;
			   -- LOWER RIGHT WALL-- WHITE
		if (x > 610 and x < 630) and (y > 310 and y < 470 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";

		end if;
				-- BOTTOM WALL-- WHITE
		if (x > 10 and x <630) and (y > 450 and y < 470 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";
		end if;
			   -- UPPER WALL -- WHITE
		if (x > 10 and x <630) and (y > 10 and y < 30 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";
		end if;
	        	--MIDDLE LINE -- WHITE
		if (x > 318 and x < 320) and (y > 30 and y < 450 ) then
			Rout <= "11111111"; 
			Gout <= "11111111"; 
			Bout <= "11111111";
		end if;

	else
-- WHEN SCAN NOT WITHIN DISPLAY REGION ASSIGN "black" color
	Rout <= "00000000";
	Gout <= "00000000";
	Bout <= "00000000";
	end if;
----ANIMATED OBJECTS-------------------------------
---MOVING BALL
	if ball_on = '1'  then
		if x < 30 and y>160 and y <310 then
			Rout<= "11111111";
			Bout <="11111111";
		elsif x >610 and y>160 and y <310 then
			Rout<= "11111111";
			Bout <="11111111";
		else
		Rout<="11111111";
		end if;
	end if;

----MOVING RIGHT BAR
	if bar_r_on = '1' then
		Rout<="11111111";
		Bout <= "11111111";
		Gout<= "11100000";
	end if;

----MOVING LEFT BAR
	if bar_l_on = '1' then
		Bout <= "11111111";
		Gout<= "11111111";
	end if;
--------------------------------------------------------
end if;----dac_clk end
end process;

end behavioral;
