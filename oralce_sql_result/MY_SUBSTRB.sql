CREATE OR REPLACE FUNCTION MY_SUBSTRB(
    p_str    IN VARCHAR2,
    p_start  IN NUMBER,
    p_length IN NUMBER DEFAULT NULL
) RETURN VARCHAR2 IS
    v_current_euc_byte NUMBER := 0; -- EUC基準での累積バイト数
    v_start_char       NUMBER := 0; -- 切り出し開始文字位置
    v_end_char         NUMBER := 0; -- 切り出し終了文字位置
    v_char_len         NUMBER;      -- その文字のEUCでのバイト数
    v_total_chars      NUMBER;
BEGIN
    IF p_str IS NULL THEN RETURN NULL; END IF;

    v_total_chars := LENGTH(p_str);

    -- 1文字ずつループして、EUC基準のバイト位置を特定する
    FOR i IN 1..v_total_chars LOOP
        -- その文字が半角カナなら2バイト、それ以外なら標準のバイト数
        IF REGEXP_LIKE(SUBSTR(p_str, i, 1), '[｡-ﾟ]') THEN
            v_char_len := 2;
        ELSE
            v_char_len := LENGTHB(SUBSTR(p_str, i, 1));
        END IF;

        v_current_euc_byte := v_current_euc_byte + v_char_len;

        -- 開始位置の特定
        IF v_start_char = 0 AND v_current_euc_byte >= p_start THEN
            v_start_char := i;
        END IF;

        -- 終了位置の特定（長さが指定されている場合）
        IF p_length IS NOT NULL THEN
            IF v_current_euc_byte <= (p_start + p_length - 1) THEN
                v_end_char := i;
            END IF;
        ELSE
            v_end_char := v_total_chars;
        END IF;
    END LOOP;

    -- 特定した文字位置で切り出す
    IF v_start_char = 0 THEN RETURN NULL; END IF;
    RETURN SUBSTR(p_str, v_start_char, (v_end_char - v_start_char + 1));
END;
/

-- 動作確認
SELECT 
    TEXT_DATA,
    SUBSTRB(TEXT_DATA, 3, 4) AS 標準の結果, -- SJIS基準で3バイト目から4つ
    MY_SUBSTRB(TEXT_DATA, 3, 4) AS ラッパー関数の結果 -- EUC基準(補正あり)
FROM TEST_KANA;

TEXT_DATA
--------------------------------------------------------------------------------
標準
----
ラッパー関数の結果
--------------------------------------------------------------------------------
ｱｲｳｴｵ
ｳｴｵ
ｲｳ
