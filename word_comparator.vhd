--------------------------------------------------------------------------------
-- DESCRIPTION : Purely combinational 5-letter word comparator.
--               Given a secret word and a player guess (each 5 ASCII bytes),
--               it classifies every guess letter as:
--                  CORRECT  ("10") – right letter, right position
--                  EXISTS   ("01") – right letter, wrong position
--                  WRONG    ("00") – letter not present in the secret word
--
--               Duplicate Letter Handling (Fully Implemented):
--               Uses a 'consumed' array to track secret word letters.
--               Pass 1 - mark all exact-position matches and consume them.
--               Pass 2 - scan remaining guess letters against unconsumed secret letters.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity word_comparator is
    port (
        secret_in   : in  std_logic_vector(39 downto 0); -- 5 x 8-bit packed
        guess_in    : in  std_logic_vector(39 downto 0); -- 5 x 8-bit packed
        feedback    : out std_logic_vector(9  downto 0); -- 5 x 2-bit result
        all_correct : out std_logic                      -- Win flag
    );
end entity word_comparator;

architecture rtl of word_comparator is

    -- Convenience type for unpacked 5-letter words
    type word5_t is array (0 to 4) of std_logic_vector(7 downto 0);

    -- Unpack flat 40-bit vectors into arrays
    -- Packing convention: letter i occupies bits (8*i+7 downto 8*i)
    signal s : word5_t; -- secret letters
    signal g : word5_t; -- guess  letters

begin

    ---------------------------------------------------------------------------
    -- Unpack inputs using a generate statement (concurrent)
    ---------------------------------------------------------------------------
    gen_unpack : for i in 0 to 4 generate
        s(i) <= secret_in(8*i + 7 downto 8*i);
        g(i) <= guess_in (8*i + 7 downto 8*i);
    end generate gen_unpack;

    ---------------------------------------------------------------------------
    -- Comparison logic : single combinational process
    ---------------------------------------------------------------------------
    p_compare : process(s, g)
        variable corr : std_logic_vector(4 downto 0); -- exact-match flags
        variable exst : std_logic_vector(4 downto 0); -- exists-in-word flags
        variable s_used : std_logic_vector (4 downto 0); -- consumed secret letters tracker
    begin
        -- Initialise all variable to '0'
        corr := (others => '0');
        exst := (others => '0');
        s_used := (others => '0');

        -- Pass 1 : detect correct-position matches
        for i in 0 to 4 loop
            if g(i) = s(i) then
                corr(i) := '1';
                s_used(i) := '1'; -- Consume this exact letter in the secret word
            end if;
        end loop;

        -- Pass 2 : for each non-correct position, check every secret position
        for i in 0 to 4 loop
            if corr(i) = '0' then
                for j in 0 to 4 loop
                    if g(i) = s(j) and s_used(j) = '0' then
                        exst(i) := '1';
                        s_used(j) := '1';
                        exit;
                    end if;
                end loop;
            end if;
        end loop;

        -- Encode 2-bit feedback per letter
        for i in 0 to 4 loop
            if corr(i) = '1' then
                feedback(2*i + 1 downto 2*i) <= "10"; -- CORRECT
            elsif exst(i) = '1' then
                feedback(2*i + 1 downto 2*i) <= "01"; -- EXISTS
            else
                feedback(2*i + 1 downto 2*i) <= "00"; -- WRONG
            end if;
        end loop;

        -- Win condition : all five letters correct
        all_correct <= corr(0) and corr(1) and corr(2) and corr(3) and corr(4);
    end process p_compare;

end architecture rtl;
