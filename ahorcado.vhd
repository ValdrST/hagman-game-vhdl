LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY ahorcado IS
    PORT (
        clk : IN STD_LOGIC;
        palabra_sel : in STD_LOGIC_VECTOR(2 downto 0); -- selector de palabras
        letra_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- esta señal recibe la letra del teclado para ser evaluada y ser escrita en el caso dado
        reset : IN std_logic; -- esta señal resetea el juego
        iniciar : IN std_logic; -- Esta señal sirve para saber cuando el plotter esta listo para empezar a escribir una letra
        letra_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Esta señal sirve para sacar la letra en formato ascii que se va a imprimir
        pos_letra : OUT std_logic_vector(15 DOWNTO 0); -- esta señal dice la posicion de la letra a escribir ex: 000000010000001 escribira la letra out = x en _______x______x
        error : OUT integer := 0; --manda la cantidad de errores obtenidos
        escribir : OUT STD_LOGIC := '0'); -- esta señal de salida avisa al ploter que hay trabajo que escribir
END ahorcado;

ARCHITECTURE logic OF ahorcado IS
    TYPE estados IS (inicio, recibir, evaluar, fin);
    TYPE ascii_word IS ARRAY (15 DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
    SIGNAL estado_siguiente : estados;
    SIGNAL estado : estados := inicio;
    SIGNAL tam_palabra : INTEGER := 0;
    SIGNAL pos_resuelta : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pos_letra_ascii : ascii_word;
    SIGNAL reseed : std_logic := '1';

BEGIN
    juego_p : PROCESS (estado, palabra_sel, iniciar, letra_in, pos_letra_ascii,pos_resuelta, tam_palabra)
    variable contador_val : integer;
    variable error_cont : integer;
    BEGIN
        error <= error_cont;
        estado_siguiente <= estado;
        CASE(estado) IS
            WHEN inicio =>
            pos_resuelta <= (OTHERS => '1');
            pos_letra_ascii <= (OTHERS => x"00");
            error_cont := 0;
            
            CASE(palabra_sel) IS
                WHEN "000" =>
                tam_palabra <= 5;
                pos_letra_ascii(5 - 1 DOWNTO 0) <= (x"61", x"72", x"62", x"6F", x"6C"); --arbol
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "001" =>
                tam_palabra <= 6;
                pos_letra_ascii(6 - 1 DOWNTO 0) <= (x"63", x"61", x"63", x"74", x"75", x"73"); --cactus
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "010" =>
                tam_palabra <= 10;
                pos_letra_ascii(10 - 1 DOWNTO 0) <= (x"69", x"6E", x"67", x"65", x"6E", x"69", x"65", x"72", x"69", x"61"); --ingenieria
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "011" =>
                tam_palabra <= 5;
                pos_letra_ascii(5 - 1 DOWNTO 0) <= (x"6A", x"75", x"65", x"67", x"6F"); --juego
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "100" =>
                tam_palabra <= 4;
                pos_letra_ascii(4 - 1 DOWNTO 0) <= (x"76", x"6C", x"73", x"69"); --vlsi
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN "101" =>
                tam_palabra <= 5;
                pos_letra_ascii(5 - 1 DOWNTO 0) <= (x"67", x"72", x"75", x"70", x"6F"); --grupo
                pos_resuelta(tam_palabra - 1 DOWNTO 0) <= (OTHERS => '0');
                estado_siguiente <= recibir;
                WHEN OTHERS =>
                tam_palabra <= 0;
                estado_siguiente <= inicio;
            END CASE;
            WHEN recibir =>
            IF iniciar = '1' THEN
                     pos_letra <= (OTHERS => '0'); -- inicializa la matriz de posiciones para dar orden de impresion
                     contador_val := 0;
                FOR i IN 0 TO 16 - 1 LOOP
                    IF letra_in = pos_letra_ascii(i) THEN
                        contador_val := contador_val + 1;
                        pos_letra(i) <= '1';
                        letra_out <= letra_in;
                        pos_letra_ascii(i) <= x"00";
                        escribir <= '1';
                        pos_resuelta(i) <= '1';
                    END IF;
                END LOOP;
                
                if contador_val > 0 then
                    error_cont := error_cont + 1;
                end if;
                estado_siguiente <= evaluar;
            ELSE
                estado_siguiente <= recibir;
            END IF;
            WHEN evaluar =>
                if iniciar = '1' then
					letra_out <= x"00";
					IF (pos_resuelta = "1111111111111111") THEN
						 estado_siguiente <= inicio;
					ELSE
						 estado_siguiente <= recibir;
					END IF;
				end if;
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