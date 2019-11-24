LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY rng_mt19937 IS

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

END ENTITY;
ARCHITECTURE rng_mt19937_arch OF rng_mt19937 IS

    -- Constants.
    CONSTANT const_a : std_logic_vector(31 DOWNTO 0) := x"9908b0df";
    CONSTANT const_b : std_logic_vector(31 DOWNTO 0) := x"9d2c5680";
    CONSTANT const_c : std_logic_vector(31 DOWNTO 0) := x"efc60000";
    CONSTANT const_f : NATURAL := 1812433253;
    CONSTANT addr_offset : NATURAL := 396;

    -- Block RAM for generator state.
    TYPE mem_t IS ARRAY(0 TO 620) OF std_logic_vector(31 DOWNTO 0);
    SIGNAL mem : mem_t;

    -- RAM access registers.
    SIGNAL reg_a_addr : std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL reg_b_addr : std_logic_vector(9 DOWNTO 0) := std_logic_vector(
    to_unsigned(addr_offset, 10));
    SIGNAL reg_a_wdata : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_a_rdata : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_b_rdata : std_logic_vector(31 DOWNTO 0);

    -- Internal registers.
    SIGNAL reg_enable : std_logic := '1';
    SIGNAL reg_reseeding : std_logic := '1';
    SIGNAL reg_reseedstate : std_logic_vector(3 DOWNTO 0) := "0001";
    SIGNAL reg_validwait : std_logic;
    SIGNAL reg_a_rdata_p : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_reseed_cnt : std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL reg_output_buf : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_seed_a : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_seed_b : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_seed_b2 : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_seed_c : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_seed_c2 : std_logic_vector(31 DOWNTO 0);
    SIGNAL reg_seed_d : std_logic_vector(31 DOWNTO 0) := init_seed;

    -- Output register.
    SIGNAL reg_valid : std_logic := '0';
    SIGNAL reg_output : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');

    -- Multiply unsigned number with constant and discard overflowing bits.
    FUNCTION mulconst(x : unsigned)
        RETURN unsigned
        IS
        VARIABLE t : unsigned(2 * x'length - 1 DOWNTO 0);
    BEGIN
        t := x * const_f;
        RETURN t(x'length - 1 DOWNTO 0);
    END FUNCTION;

BEGIN

    --
    -- Drive output signal.
    --
    out_valid <= reg_valid;
    out_data <= reg_output;

    --
    -- Main synchronous process.
    --
    PROCESS (clk) IS
        VARIABLE y : std_logic_vector(31 DOWNTO 0);
    BEGIN
        IF rising_edge(clk) THEN

            -- Update memory pointers.
            IF reg_enable = '1' THEN

                IF unsigned(reg_a_addr) = 620 THEN
                    reg_a_addr <= (OTHERS => '0');
                ELSE
                    reg_a_addr <= std_logic_vector(unsigned(reg_a_addr) + 1);
                END IF;

                IF unsigned(reg_b_addr) = 620 THEN
                    reg_b_addr <= (OTHERS => '0');
                ELSE
                    reg_b_addr <= std_logic_vector(unsigned(reg_b_addr) + 1);
                END IF;

            END IF;

            -- Keep previous value from read port A.
            IF reg_enable = '1' THEN
                reg_a_rdata_p <= reg_a_rdata;
            END IF;

            -- Update reseeding state (4 cycles per address step).
            reg_reseedstate(3 DOWNTO 1) <= reg_reseedstate(2 DOWNTO 0);
            reg_reseedstate(0) <= reg_reseedstate(3) AND reg_reseeding;

            -- Update reseeding counter.
            IF reg_enable = '1' THEN
                reg_reseed_cnt <=
                    std_logic_vector(unsigned(reg_reseed_cnt) + 1);
            END IF;

            -- Determine end of reseeding.
            IF unsigned(reg_reseed_cnt) = 624 THEN
                reg_reseeding <= '0';
            END IF;

            -- Enable state machine on next cycle
            --  a) every 1st out of 4 cycles during reseeding, and
            --  b) on-demand for new output.
            reg_enable <= (reg_reseeding AND reg_reseedstate(3)) OR
                (NOT reg_reseeding AND
                (out_ready OR NOT reg_valid));

            -- Reseed state 1: XOR and shift previous state element.
            y := reg_seed_d;
            y(1 DOWNTO 0) := y(1 DOWNTO 0) XOR y(31 DOWNTO 30);
            reg_seed_a <= y;

            -- Reseed state 2: Multiply by constant.
            IF force_const_mul THEN
                -- Compute 37 * Mprev.
                reg_seed_b <= std_logic_vector(
                    unsigned(reg_seed_a)
                    + shift_left(unsigned(reg_seed_a), 2)
                    + shift_left(unsigned(reg_seed_a), 5));
                -- Compute (2**19 - 2**15) * Mprev.
                reg_seed_b2 <= std_logic_vector(
                    shift_left(unsigned(reg_seed_a), 19)
                    - shift_left(unsigned(reg_seed_a), 15));
            ELSE
                -- Compute 1812433253 * Mprev.
                -- Let synthesizer choose a multiplier implementation.
                reg_seed_b <= std_logic_vector(
                    mulconst(unsigned(reg_seed_a)));
            END IF;

            -- Reseed state 3: Continue multiplication by constant.
            IF force_const_mul THEN
                -- Compute (37 + 2**6 * 37 + 2**19 - 2**15) * Mprev.
                -- Finalize multiplication by 1812433253 =
                -- (37 + 2**6*37 - 2**15 + 2**19 - 2**26*37)
                reg_seed_c <= std_logic_vector(
                    unsigned(reg_seed_b)
                    + shift_left(unsigned(reg_seed_b), 6)
                    + unsigned(reg_seed_b2));
                -- Compute (2**32 - 2**26 * 37) * Mprev + reseed_cnt.
                reg_seed_c2 <= std_logic_vector(
                    unsigned(reg_reseed_cnt)
                    - shift_left(unsigned(reg_seed_b), 26));
            ELSE
                reg_seed_c <= reg_seed_b;
            END IF;

            -- Reseed state 4: Prepare next element of initial state.
            IF reg_reseeding = '1' THEN
                IF force_const_mul THEN
                    -- Compute   (37 + 2**6 * 37 + 2**19 - 2**15) * Mprev
                    --         + (2**32 - 2**26 * 37) * Mprev + reseed_cnt
                    --         = 1812433253 * Mprev + reseed_cnt.
                    reg_seed_d <= std_logic_vector(unsigned(reg_seed_c) +
                        unsigned(reg_seed_c2));
                ELSE
                    -- Compute 1812433253 * Mprev + reseed_cnt.
                    reg_seed_d <= std_logic_vector(unsigned(reg_seed_c) +
                        unsigned(reg_reseed_cnt));
                END IF;
            END IF;

            -- Update internal RNG state.
            IF reg_enable = '1' THEN

                IF reg_reseeding = '1' THEN

                    -- Reseed state 1: Write next state element.
                    reg_a_wdata <= reg_seed_d;

                ELSE

                    -- Normal operation.
                    -- Perform one step of the "twist" function.

                    y := reg_a_rdata_p(31 DOWNTO 31) &
                        reg_a_rdata(30 DOWNTO 0);

                    IF y(0) = '1' THEN
                        y := "0" & y(31 DOWNTO 1);
                        y := y XOR const_a;
                    ELSE
                        y := "0" & y(31 DOWNTO 1);
                    END IF;

                    reg_a_wdata <= reg_b_rdata XOR y;

                END IF;
            END IF;

            -- Prepare output value.
            IF reg_enable = '1' THEN

                y := reg_a_wdata;

                y(20 DOWNTO 0) := y(20 DOWNTO 0) XOR y(31 DOWNTO 11);
                y(31 DOWNTO 7) := y(31 DOWNTO 7) XOR
                (y(24 DOWNTO 0) AND const_b(31 DOWNTO 7));
                y(31 DOWNTO 15) := y(31 DOWNTO 15) XOR
                (y(16 DOWNTO 0) AND const_c(31 DOWNTO 15));
                y(13 DOWNTO 0) := y(13 DOWNTO 0) XOR y(31 DOWNTO 18);

                reg_output_buf <= y;

                -- Conditionally push to final output register.
                IF out_ready = '1' OR reg_valid = '0' THEN
                    reg_output <= y;
                END IF;

            END IF;

            -- Use buffered value when restarting after pause.
            IF out_ready = '1' AND reg_enable = '0' THEN
                reg_output <= reg_output_buf;
            END IF;

            -- Indicate valid data at end of initialization.
            IF reg_enable = '1' THEN
                reg_validwait <= NOT reg_reseeding;
                reg_valid <= reg_validwait AND NOT reg_reseeding;
            END IF;

            -- Start re-seeding.
            IF reseed = '1' THEN
                reg_reseeding <= '1';
                reg_reseedstate <= "0001";
                reg_reseed_cnt <= std_logic_vector(to_unsigned(0, 10));
                reg_enable <= '1';
                reg_seed_d <= newseed;
                reg_valid <= '0';
            END IF;

            -- Synchronous reset.
            IF rst = '1' THEN
                reg_a_addr <= std_logic_vector(to_unsigned(0, 10));
                reg_b_addr <= std_logic_vector(
                    to_unsigned(addr_offset, 10));
                reg_reseeding <= '1';
                reg_reseedstate <= "0001";
                reg_reseed_cnt <= std_logic_vector(to_unsigned(0, 10));
                reg_enable <= '1';
                reg_seed_d <= init_seed;
                reg_valid <= '0';
                reg_output <= (OTHERS => '0');
            END IF;

        END IF;
    END PROCESS;

    --
    -- Synchronous process for block RAM.
    --
    PROCESS (clk) IS
    BEGIN
        IF rising_edge(clk) THEN
            IF reg_enable = '1' THEN

                -- Read from port A.
                reg_a_rdata <= mem(to_integer(unsigned(reg_a_addr)));

                -- Read from port B.
                reg_b_rdata <= mem(to_integer(unsigned(reg_b_addr)));

                -- Write to port A.
                mem(to_integer(unsigned(reg_a_addr))) <= reg_a_wdata;

            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;