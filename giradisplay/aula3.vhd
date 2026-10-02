library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity quadrado_rotativo is
    port (
        clk_50M  : in  std_logic;
        enable   : in  std_logic;
        cw       : in  std_logic;
        speed    : in  std_logic_vector(1 downto 0); -- 2 chaves para velocidade
        disp_sel : in  std_logic;                    -- Nova chave para multiplexar os displays 5 e 4
        
        -- Displays principais (Quadrado rotativo)
        hex3, hex2, hex1, hex0 : out std_logic_vector(6 downto 0);
        
        -- Displays de monitorização (Multiplexados)
        hex5, hex4 : out std_logic_vector(6 downto 0);
        
        -- LEDs de sinalização
        ledr : out std_logic_vector(7 downto 0)
    );
end entity quadrado_rotativo;

architecture rtl of quadrado_rotativo is
    signal count        : integer := 0;
    signal limit        : integer := 50000000;
    signal tick         : std_logic := '0';
    signal estado_atual : integer range 0 to 7 := 0;
    signal prox_estado  : integer range 0 to 7 := 0;
    
    -- Sinais internos para os displays partilhados
    signal h5_modo0, h4_modo0 : std_logic_vector(6 downto 0);
    signal h5_modo1, h4_modo1 : std_logic_vector(6 downto 0);
begin

    -- 1. Divisor de Frequência
    process(speed)
    begin
        case speed is
            when "00" => limit <= 50000000; -- Velocidade 0 (~1 Hz)
            when "01" => limit <= 25000000; -- Velocidade 1 (~2 Hz)
            when "10" => limit <= 12500000; -- Velocidade 2 (~4 Hz)
            when "11" => limit <= 6250000;  -- Velocidade 3 (~8 Hz)
            when others => limit <= 50000000;
        end case;
    end process;

    process(clk_50M)
    begin
        if rising_edge(clk_50M) then
            if count >= limit - 1 then
                count <= 0;
                tick <= '1';
            else
                count <= count + 1;
                tick <= '0';
            end if;
        end if;
    end process;

    -- 2. Lógica Combinacional de Próximo Estado
    process(estado_atual, cw)
    begin
        if cw = '1' then -- Sentido Horário (H)
            if estado_atual = 7 then
                prox_estado <= 0;
            else
                prox_estado <= estado_atual + 1;
            end if;
        else             -- Sentido Anti-horário (A)
            if estado_atual = 0 then
                prox_estado <= 7;
            else
                prox_estado <= estado_atual - 1;
            end if;
        end if;
    end process;

    -- 3. Registo de Atualização de Estado
    process(clk_50M)
    begin
        if rising_edge(clk_50M) then
            if tick = '1' and enable = '1' then
                estado_atual <= prox_estado;
            end if;
        end if;
    end process;

    -- 4. Comando dos LEDs
    ledr <= (others => '1') when enable = '0' else (others => '0');

    -- 5. Displays do Quadrado (HEX3 a HEX0)
    hex3 <= "0011100" when estado_atual = 0 else "0100011" when estado_atual = 7 else "1111111";
    hex2 <= "0011100" when estado_atual = 1 else "0100011" when estado_atual = 6 else "1111111";
    hex1 <= "0011100" when estado_atual = 2 else "0100011" when estado_atual = 5 else "1111111";
    hex0 <= "0011100" when estado_atual = 3 else "0100011" when estado_atual = 4 else "1111111";

    -- 6. Descodificação do MODO 0: Sentido e Velocidade
    -- Sentido (H/A) no HEX5_modo0
    h5_modo0 <= "0001001" when cw = '1' else "0001000";
    
    -- Velocidade (0 a 3) no HEX4_modo0
    with speed select
        h4_modo0 <= "1000000" when "00", 
                    "1111001" when "01", 
                    "0100100" when "10", 
                    "0110000" when "11", 
                    "1111111" when others;

    -- 7. Descodificação do MODO 1: Estado Atual e Próximo
    with estado_atual select
        h5_modo1 <= "1000000" when 0, "1111001" when 1, "0100100" when 2, "0110000" when 3,
                    "0011001" when 4, "0010010" when 5, "0000010" when 6, "1111000" when 7,
                    "1111111" when others;

    with prox_estado select
        h4_modo1 <= "1000000" when 0, "1111001" when 1, "0100100" when 2, "0110000" when 3,
                    "0011001" when 4, "0010010" when 5, "0000010" when 6, "1111000" when 7,
                    "1111111" when others;

    -- 8. Multiplexagem Final dos Displays Restantes
    hex5 <= h5_modo0 when disp_sel = '0' else h5_modo1;
    hex4 <= h4_modo0 when disp_sel = '0' else h4_modo1;

end architecture rtl;