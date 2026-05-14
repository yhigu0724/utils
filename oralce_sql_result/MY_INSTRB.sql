CREATE OR REPLACE FUNCTION MY_INSTRB(
    p_str      IN VARCHAR2,
    p_substr   IN VARCHAR2,
    p_position IN NUMBER DEFAULT 1,
    p_occurrence IN NUMBER DEFAULT 1
) RETURN NUMBER IS
    v_euc_byte_pos NUMBER := 0;
    v_found_count  NUMBER := 0;
    v_char_len     NUMBER;
BEGIN
    IF p_str IS NULL OR p_substr IS NULL THEN RETURN 0; END IF;

    -- 文字単位でループして、EUC換算のバイト位置を特定する
    FOR i IN 1..LENGTH(p_str) LOOP
        -- 現在の文字のEUCバイト数を判定
        IF REGEXP_LIKE(SUBSTR(p_str, i, 1), '[｡-ﾟ]') THEN
            v_char_len := 2;
        ELSE
            v_char_len := LENGTHB(SUBSTR(p_str, i, 1));
        END IF;

        -- 探し始めの文字位置(p_position)以降で、部分一致を確認
        IF i >= p_position THEN
            IF SUBSTR(p_str, i, LENGTH(p_substr)) = p_substr THEN
                v_found_count := v_found_count + 1;
                IF v_found_count = p_occurrence THEN
                    RETURN v_euc_byte_pos + 1;
                END IF;
            END IF;
        END IF;

        v_euc_byte_pos := v_euc_byte_pos + v_char_len;
    END LOOP;

    RETURN 0;
END;
/


-- テスト用テーブル
CREATE TABLE TEST_MIGRATION (
    ID NUMBER PRIMARY KEY,
    KANA_DATA VARCHAR2(100),
    MIXED_DATA VARCHAR2(100)
);

-- テストデータの投入
-- 既存のテーブルに検証用データを追加
INSERT INTO TEST_MIGRATION VALUES (2, 'ｱｲｳ', 'ABｱｲｳ漢字123');
COMMIT;

--  動作確認用PL/SQL
SET SERVEROUTPUT ON
DECLARE
    v_test_str VARCHAR2(100);
    v_pos_std  NUMBER;
    v_pos_my   NUMBER;
BEGIN
    -- 対象： 'ABｱｲｳ漢字123'
    -- EUC想定バイト位置： A(1), B(2), ｱ(3,4), ｲ(5,6), ｳ(7,8), 漢(9,10)...
    SELECT MIXED_DATA INTO v_test_str FROM TEST_MIGRATION WHERE ID = 2;

    -- 「ｱ」の位置を探す
    v_pos_std := INSTRB(v_test_str, 'ｱ');
    v_pos_my  := MY_INSTRB(v_test_str, 'ｱ');

    DBMS_OUTPUT.PUT_LINE('対象文字列: ' || v_test_str);
    DBMS_OUTPUT.PUT_LINE('--- 「ｱ」の位置検索 ---');
    DBMS_OUTPUT.PUT_LINE('標準INSTRB(SJIS): ' || v_pos_std || ' バイト目');
    DBMS_OUTPUT.PUT_LINE('独自MY_INSTRB(EUC): ' || v_pos_my  || ' バイト目');
    
    -- 「漢字」の位置を探す
    v_pos_std := INSTRB(v_test_str, '漢字');
    v_pos_my  := MY_INSTRB(v_test_str, '漢字');

    DBMS_OUTPUT.PUT_LINE('--- 「漢字」の位置検索 ---');
    DBMS_OUTPUT.PUT_LINE('標準INSTRB(SJIS): ' || v_pos_std || ' バイト目');
    DBMS_OUTPUT.PUT_LINE('独自MY_INSTRB(EUC): ' || v_pos_my  || ' バイト目');
END;
/

対象文字列: ABｱｲｳ漢字123
--- 「ｱ」の位置検索 ---
標準INSTRB(SJIS): 3 バイト目
独自MY_INSTRB(EUC): 3 バイト目
--- 「漢字」の位置検索 ---
標準INSTRB(SJIS): 6 バイト目
独自MY_INSTRB(EUC): 9 バイト目

PL/SQLプロシージャが正常に完了しました。