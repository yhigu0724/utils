CREATE OR REPLACE FUNCTION MY_LENGTHB(p_str IN VARCHAR2) RETURN NUMBER IS
    v_kana_count NUMBER;
BEGIN
    -- 文字列が空の場合は0を返す
    IF p_str IS NULL THEN 
        RETURN 0; 
    END IF;

    -- REGEXP_COUNTを使用して半角カナ（SJISの範囲）の個数をカウント
    -- [｡-ﾟ] はSJISにおける半角句読点から半角カナまでの範囲を指定
    v_kana_count := REGEXP_COUNT(p_str, '[｡-ﾟ]');

    -- 標準のバイト数(5) + 半角カナの数(5) = 合計10バイト という計算になる
    RETURN LENGTHB(p_str) + v_kana_count;
END;
/
-- ラッパー関数の動作確認

SELECT 
    TEXT_DATA, 
    LENGTHB(TEXT_DATA) AS 標準のバイト数, 
    MY_LENGTHB(TEXT_DATA) AS ラッパー関数の結果 
FROM TEST_KANA;

標準のバイト数 ラッパー関数の結果
-------------- ------------------
ｱｲｳｴｵ
             5                 10

-- テスト

$sjis
$ sqlplus NISHI/iku3952

SQL>
-- テスト用のテーブルを作成
CREATE TABLE TEST_KANA (TEXT_DATA VARCHAR2(100));

-- 半角カナ「ｱｲｳｴｵ」をインサート（5文字）
INSERT INTO TEST_KANA VALUES ('ｱｲｳｴｵ');
COMMIT;

-- LENGTHB（バイト数）とLENGTH（文字数）を確認
SELECT TEXT_DATA, LENGTH(TEXT_DATA) AS 文字数, LENGTHB(TEXT_DATA) AS バイト数 FROM TEST_KANA;

TEXT_DATA
--------------------------------------------------------------------------------
    文字数   バイト数
---------- ----------
ｱｲｳｴｵ
         5          5
         

