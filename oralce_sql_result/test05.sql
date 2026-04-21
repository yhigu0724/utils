SET SERVEROUTPUT ON SIZE 1000000
SET FEEDBACK OFF
SET LINESIZE 1000
SET TRIMSPOOL ON
SET PAGESIZE 0

-- ★ 実行ごとにファイル名を変えると管理しやすいです
SPOOL jp_tables_1_1000.txt

DECLARE
    --------------------------------------------------
    -- ★ ここを書き換えて分割実行してください
    --------------------------------------------------
    v_from_row      INTEGER := 1;
    v_to_row        INTEGER := 1000;
    --------------------------------------------------

    v_found_jp      INTEGER;
    v_sql           VARCHAR2(32767);
    v_target_found  BOOLEAN;
BEGIN
    dbms_output.put_line('--- 抽出開始 (Range: ' || v_from_row || ' - ' || v_to_row || ') ---');

    -- 先ほど成功した ROWNUM 階層構造を採用
    FOR t IN (
        SELECT table_name FROM (
            SELECT table_name, ROWNUM as rn
            FROM (
                SELECT DISTINCT table_name
                FROM user_tab_columns 
                WHERE data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
                  AND table_name NOT LIKE 'BIN$%'
                ORDER BY table_name
            )
        )
        WHERE rn BETWEEN v_from_row AND v_to_row
    ) LOOP
        
        v_target_found := FALSE;

        -- 各テーブルのカラムを調査
        FOR c IN (
            SELECT column_name, data_type 
            FROM user_tab_columns 
            WHERE table_name = t.table_name 
            AND data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ) LOOP
            
            -- SQLインジェクションや構文エラー防止のため識別子を " で囲む
            v_sql := 'SELECT COUNT(*) FROM dual WHERE EXISTS (SELECT 1 FROM "' || t.table_name || '" WHERE ';
            
            IF c.data_type = 'CLOB' THEN
                -- CLOBは先頭1000文字のみ判定
                v_sql := v_sql || 'INSTR(ASCIISTR(DBMS_LOB.SUBSTR("' || c.column_name || '", 1000, 1)), ''\'') > 0';
            ELSE
                v_sql := v_sql || 'INSTR(ASCIISTR("' || c.column_name || '"), ''\'') > 0';
            END IF;
            
            v_sql := v_sql || ')';

            BEGIN
                EXECUTE IMMEDIATE v_sql INTO v_found_jp;
                IF v_found_jp > 0 THEN
                    v_target_found := TRUE;
                    EXIT; -- 日本語が見つかれば次のテーブルへ
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    -- 特定のカラムでエラーが出ても止まらず次へ
                    NULL;
            END;
        END LOOP;

        -- 結果を画面（とファイル）に出力
        IF v_target_found THEN
            dbms_output.put_line(t.table_name);
        END IF;

    END LOOP;

    dbms_output.put_line('--- ' || v_from_row || ' から ' || v_to_row || ' までの処理が完了 ---');
END;
/

SPOOL OFF