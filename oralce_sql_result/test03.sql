SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET LINESIZE 1000
SET TRIMSPOOL ON
SET PAGESIZE 0

SPOOL japanese_tables_list.txt

DECLARE
    v_found_jp      INTEGER;
    v_sql           VARCHAR2(32767);
    v_target_found  BOOLEAN;
BEGIN
    dbms_output.put_line('--- 日本語データを含むテーブル一覧 ---');

    FOR t IN (
        SELECT DISTINCT table_name 
        FROM user_tab_columns 
        WHERE data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ORDER BY table_name
    ) LOOP
        v_target_found := FALSE;

        -- カラムごとにループを回す（文字列連結によるバッファ溢れを防止）
        FOR c IN (
            SELECT column_name, data_type 
            FROM user_tab_columns 
            WHERE table_name = t.table_name 
            AND data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ) LOOP
            
            -- 個別のカラムに対して日本語チェック用のSQLを組み立て
            v_sql := 'SELECT COUNT(*) FROM dual WHERE EXISTS (SELECT 1 FROM ' || t.table_name || ' WHERE ';
            
            IF c.data_type = 'CLOB' THEN
                v_sql := v_sql || 'INSTR(ASCIISTR(DBMS_LOB.SUBSTR(' || c.column_name || ', 1000, 1)), ''\'') > 0';
            ELSE
                v_sql := v_sql || 'INSTR(ASCIISTR(' || c.column_name || '), ''\'') > 0';
            END IF;
            
            v_sql := v_sql || ')';

            BEGIN
                EXECUTE IMMEDIATE v_sql INTO v_found_jp;
                
                -- 日本語が見つかったら、そのテーブルは「確定」として次のテーブルへ
                IF v_found_jp > 0 THEN
                    v_target_found := TRUE;
                    EXIT; -- カラムのループを抜ける
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    -- 特定のカラムでエラーが出た場合はログを出して次へ
                    dbms_output.put_line('COL_ERROR: ' || t.table_name || '.' || c.column_name || ' - ' || SQLERRM);
            END;
        END LOOP;

        -- 結果の出力
        IF v_target_found THEN
            dbms_output.put_line(t.table_name);
        END IF;

    END LOOP;

    dbms_output.put_line('--- 抽出完了 ---');
END;
/

SPOOL OFF
