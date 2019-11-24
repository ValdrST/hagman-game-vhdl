LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY proyecto_final IS
	PORT (
		clk : IN STD_LOGIC;
		ps2_clk : IN STD_LOGIC;
		ps2_data : IN STD_LOGIC);
END proyecto_final;

ARCHITECTURE logic OF proyecto_final IS
	SIGNAL ascii_code : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
	SIGNAL ascii_new : std_logic;
	SIGNAL reset : std_logic;
	SIGNAL reseed : std_logic;
	SIGNAL out_ready_rand : std_logic := '0';
	SIGNAL out_valid_rand : std_logic;
	SIGNAL rand_data : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
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
	COMPONENT rng_mt19937 IS

		GENERIC (
			init_seed : std_logic_vector(31 DOWNTO 0);
			force_const_mul : BOOLEAN);

		PORT (
			clk : IN std_logic;
			rst : IN std_logic;
			reseed : IN std_logic;
			newseed : IN std_logic_vector(31 DOWNTO 0);
			out_ready : IN std_logic;
			out_valid : OUT std_logic;
			out_data : OUT std_logic_vector(31 DOWNTO 0));
	END COMPONENT;
BEGIN
	ps2_key : ps2_keyboard_to_ascii GENERIC MAP(clk_freq => 50_00_000, ps2_debounce_counter_size => 8)
	PORT MAP(clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data, ascii_new => ascii_new, ascii_code => ascii_code);
	random_data : rng_mt19937 GENERIC MAP(init_seed => x"9908ffff", force_const_mul => false)
	PORT MAP(clk => clk, rst => reset, reseed => reseed, newseed => rand_data, out_ready => out_ready_rand, out_valid => out_valid_rand, out_data => rand_data);

END;