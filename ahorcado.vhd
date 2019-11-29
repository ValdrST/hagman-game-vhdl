LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ahorcado IS
    PORT (
        clk : IN STD_LOGIC;
        letra_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        reset : IN std_logic;
		  iniciar : in std_logic;
        letra_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        pos_letra : OUT std_logic_vector(15 DOWNTO 0);
        escribir : OUT STD_LOGIC := '0');
END ahorcado;

ARCHITECTURE logic OF ahorcado IS
    TYPE estados IS (inicio, recibir, evaluar, fin);
    TYPE palabras IS (arbol, cactus, ingenieria, juego, vlsi, grupo, nulo);
    TYPE ascii_word IS ARRAY (15 DOWNTO 0) OF std_logic_vector(6 DOWNTO 0);
    SIGNAL estado_siguiente : estados;
    SIGNAL estado : estados := inicio;
    SIGNAL palabra, palabra_sig : palabras;
    SIGNAL tam_palabra : INTEGER := 0;
    SIGNAL pos_resuelta : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pos_letra_ascii : ascii_word;
    SIGNAL reseed : std_logic;
    SIGNAL out_ready_rand : std_logic := '0';
    SIGNAL out_valid_rand : std_logic;
    SIGNAL rand_data : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
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
    random_data : rng_mt19937 GENERIC MAP(init_seed => x"9908ffff", force_const_mul => true)
    PORT MAP(clk => clk, rst => reset, reseed => reseed, newseed => rand_data, out_ready => out_ready_rand, out_valid => out_valid_rand, out_data => rand_data);

    juego_p : PROCESS (estado, rand_data, iniciar, letra_in, pos_letra_ascii, reseed, out_ready_rand, out_valid_rand, pos_resuelta, tam_palabra)
        VARIABLE rand_pos : std_logic_vector(2 DOWNTO 0) := rand_data(2 DOWNTO 0);
    BEGIN
        reseed <= '1';
        out_ready_rand <= '1';
        estado_siguiente <= estado;
        CASE(estado) IS
            WHEN inicio =>
            pos_resuelta <= (OTHERS => '1');
				if out_valid_rand = '1' then
					rand_pos := rand_data(2 DOWNTO 0);
            CASE(rand_pos) IS
                WHEN "000" =>
                palabra <= arbol;
                tam_palabra <= 5;
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "001" =>
                palabra <= cactus;
                tam_palabra <= 6;
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "010" =>
                palabra <= ingenieria;
                tam_palabra <= 10;
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "011" =>
                palabra <= juego;
                tam_palabra <= 5;
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "100" =>
                palabra <= vlsi;
                tam_palabra <= 4;
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "101" =>
                palabra <= grupo;
                tam_palabra <= 5;
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN OTHERS =>
                palabra <= nulo;
                tam_palabra <= 0;
                estado_siguiente <= inicio;
            END CASE;
				else
					estado_siguiente <= inicio;
				end if;
            WHEN recibir =>
            IF iniciar = '1' THEN
                FOR i IN 0 TO 16 - 1 LOOP
                    IF letra_in = pos_letra_ascii(i) THEN
                        pos_letra(i) <= '1';
                        pos_resuelta(i) <= '1';
                    END IF;
                END LOOP;
                letra_out <= letra_in;
                escribir <= '1';
                estado_siguiente <= evaluar;
            ELSE
                escribir <= '0';
                letra_out <= "0000000";
                estado_siguiente <= recibir;
            END IF;
            WHEN evaluar =>
            IF (pos_resuelta = "1111111111111111") THEN
                estado_siguiente <= inicio;
            ELSE
                estado_siguiente <= recibir;
            END IF;
            WHEN OTHERS =>
            estado_siguiente <= estado;
        END CASE;
    END PROCESS;

    maquina_estados : PROCESS (clk, reset)
    BEGIN
        IF (reset = '0') THEN
            estado <= inicio;
        ELSIF rising_edge(clk) THEN
            estado <= estado_siguiente;
        END IF;
    END PROCESS;

    palabras_p : PROCESS (palabra)
    BEGIN
        pos_letra_ascii <= (OTHERS => "0000000");
        CASE(palabra) IS
            WHEN arbol =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"61", x"72", x"62", x"6F", x"6C");
            WHEN cactus =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73");
            WHEN ingenieria =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73");
            WHEN juego =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73");
            WHEN vlsi =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73");
            WHEN grupo =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73");
            WHEN palabra =>
            pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73");
            WHEN nulo =>
            WHEN OTHERS =>
            tam_palabra <= 0;
        END CASE;
    END PROCESS;
END logic;