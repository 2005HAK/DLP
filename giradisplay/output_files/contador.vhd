library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity free_run_bin_counter is
    generic (
		N: integer:=5 --numero de bits
	 );
	 port ( clk, reset : in  STD_LOGIC;
			  max_tick : out  STD_LOGIC;
           q_out : out  STD_LOGIC_VECTOR(N-1 downto 0)
			  );
end free_run_bin_counter;

architecture Behavioral of free_run_bin_counter is
	signal r_reg: STD_LOGIC_VECTOR(N-1 downto 0);
   signal r_next: STD_LOGIC_VECTOR(N-1 downto 0);
begin
	--register
	process (clk, reset)
	begin
		if (reset='1') then
			r_reg <= (others=>'0');
		elsif (clk'event and clk='1') then 
			if(r_next<"01010") then
				r_reg <= r_next;
				max_tick <= '0';
			else
				r_reg <= (others=>'0');
				max_tick <= '1';
			end if;
		end if;
	end process;
	--next-stage logic 
	r_next <= r_reg + '1';
	--output
	q_out <= r_reg;
end Behavioral;