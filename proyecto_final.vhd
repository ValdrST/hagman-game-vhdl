LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY proyecto_final IS
	PORT (
		clk : IN STD_LOGIC := '0';
		ps2_clk : IN STD_LOGIC;
		ps2_data : IN STD_LOGIC;
		reset : in std_logic;
		leds : out std_logic_vector(7 downto 0);
		sw : in std_logic_vector(2 downto 0)
		);
END proyecto_final;

ARCHITECTURE logic OF proyecto_final IS
	SIGNAL ascii_code : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
	SIGNAL ascii_new : std_logic;
	SIGNAL reseed : std_logic;
	signal iniciar : std_logic;
	SIGNAL out_ready_rand : std_logic := '0';
	SIGNAL out_valid_rand : std_logic;
	SIGNAL rand_data : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
	signal letra_out : std_logic_vector(7 downto 0);
	signal letra_in : std_logic_vector(7 downto 0);
	signal pos_letra : std_logic_vector(15 DOWNTO 0);
	signal pal_sel : std_logic_vector(2 downto 0);
	signal escribir : std_logic := '0';
	COMPONENT ps2_keyboard_to_ascii IS
		GENERIC (
			clk_freq : INTEGER;
			ps2_debounce_counter_size : INTEGER);
		PORT (
			clk : IN STD_LOGIC;
			ps2_clk : IN STD_LOGIC;
			ps2_data : IN STD_LOGIC;
			ascii_new : OUT STD_LOGIC;
			ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
	END COMPONENT;
	component ahorcado IS
    PORT (
        clk : IN STD_LOGIC;
		letra_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		palabra_sel : in STD_LOGIC_VECTOR(2 downto 0);
        reset : IN std_logic;
		iniciar : in std_logic;
        letra_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        pos_letra : OUT std_logic_vector(15 DOWNTO 0);
        escribir : OUT STD_LOGIC);
END component;
function to_string ( a: std_logic_vector) return string is
variable b : string (1 to a'length) := (others => NUL);
variable stri : integer := 1; 
begin
    for i in a'range loop
        b(stri) := std_logic'image(a((i)))(2);
    stri := stri+1;
    end loop;
return b;
end function;
BEGIN
	ps2_key : ps2_keyboard_to_ascii GENERIC MAP(clk_freq => 50_000_000, ps2_debounce_counter_size => 8)
	PORT MAP(clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data, ascii_new => ascii_new, ascii_code => ascii_code);
	juego_ahorcado : ahorcado port map(clk=>clk,letra_in=>letra_in, palabra_sel=> pal_sel,reset=>reset,iniciar=>iniciar,letra_out=>letra_out,pos_letra=>pos_letra,escribir=> escribir);
	teclado:process(ascii_new) 
	begin	
		if (ascii_new = '1') then
			letra_in(7) <= '0';
			letra_in(6 downto 0) <= ascii_code;
			leds <= letra_in;
		end if;
	end process;

	escribir_p:process(letra_out,pos_letra,escribir)
	begin
		
		if (escribir = '1') then
			iniciar <= '0';
			-- aqui el plotter esta en proceso de escritura y cuando termine vuelve a estar en estado iniciar
			-- iniciar <= '1';
		end if;
	end process;
END;