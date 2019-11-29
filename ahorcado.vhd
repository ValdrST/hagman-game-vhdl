LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ahorcado IS
    PORT (
        clk : IN STD_LOGIC;
        letra_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0); -- esta señal recibe la letra del teclado para ser evaluada y ser escrita en el caso dado
        reset : IN std_logic; -- esta señal resetea el juego
        iniciar : IN std_logic; -- Esta señal sirve para saber cuando el plotter esta listo para empezar a escribir una letra
        letra_out : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Esta señal sirve para sacar la letra en formato ascii que se va a imprimir
        pos_letra : OUT std_logic_vector(15 DOWNTO 0); -- esta señal dice la posicion de la letra a escribir ex: 000000010000001 escribira la letra out = x en _______x______x
        escribir : OUT STD_LOGIC := '0'); -- esta señal de salida avisa al ploter que hay trabajo que escribir
END ahorcado;

ARCHITECTURE logic OF ahorcado IS
    TYPE estados IS (inicio, recibir, evaluar, fin);
    TYPE ascii_word IS ARRAY (15 DOWNTO 0) OF std_logic_vector(6 DOWNTO 0);
    SIGNAL estado_siguiente : estados;
    SIGNAL estado : estados := inicio;
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
    PORT MAP(clk => clk, rst => reset, reseed => reseed, newseed => rand_data, out_ready => out_ready_rand, out_valid => out_valid_rand, out_data => rand_data); --este componente genera numeros pseudoaleatorios

    juego_p : PROCESS (estado, rand_data, iniciar, letra_in, pos_letra_ascii, reseed, out_ready_rand, out_valid_rand, pos_resuelta, tam_palabra)
        VARIABLE rand_pos : std_logic_vector(2 DOWNTO 0) := rand_data(2 DOWNTO 0);
    BEGIN
        reseed <= '1';
        out_ready_rand <= '1';
        estado_siguiente <= estado;
        CASE(estado) IS
            WHEN inicio =>
            pos_resuelta <= (OTHERS => '1');
            rand_pos := rand_data(2 DOWNTO 0);
            pos_letra_ascii <= (OTHERS => "0000000");
            CASE(rand_pos) IS
                WHEN "000" =>
                tam_palabra <= 5;
                pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"61", x"72", x"62", x"6F", x"6C"); --arbol
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "001" =>
                tam_palabra <= 6;
                pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73"); --cactus
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "010" =>
                tam_palabra <= 10;
                pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"69", x"6E", x"67", x"65", x"6E", x"69", x"65", x"72", x"69", x"61"); --ingenieria
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "011" =>
                tam_palabra <= 5;
                pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"6A", x"75", x"65", x"67", x"6F"); --juego
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "100" =>
                tam_palabra <= 4;
                pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"76", x"6C", x"73", x"69"); --vlsi
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "101" =>
                tam_palabra <= 5;
                pos_letra_ascii(tam_palabra - 1 DOWNTO 0) <= (x"67", x"72", x"75", x"70", x"6F"); --grupo
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN OTHERS =>
                tam_palabra <= 0;
                estado_siguiente <= inicio;
            END CASE;
            WHEN recibir =>
            IF iniciar = '1' AND escribir = '0' THEN
                FOR i IN 0 TO 16 - 1 LOOP
                    IF letra_in = pos_letra_ascii(i) THEN
                        pos_letra(i) <= '1';
                        pos_resuelta(i) <= '1';
                    END IF;
                END LOOP;
                pos_letra <= (OTHERS => '0'); -- inicializa la matriz de posiciones para dar orden de impresion
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
END logic;