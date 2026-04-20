SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET LINESIZE 1000
SET TRIMSPOOL ON

-- 出力ファイル名
SPOOL japanese_tables_test.txt

DECLARE
    -- ★テスト用のパラメータ：抽出するテーブルの最大件数
    v_limit INTEGER := 10; 
    
    v_current_count INTEGER := 0;
    v_match_count   INTEGER := 0;
    v_found_jp      INTEGER;
    v_sql           VARCHAR2(32767); -- 10gのPL/SQL変数上限まで確保
BEGIN
    dbms_output.put_line('--- 日本語データを含むテーブルの抽出 (最大調査対象: ' || v_limit || '件) ---');
    dbms_output.put_line('開始時刻: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
    dbms_output.put_line('--------------------------------------------------');

    -- 対象テーブルを特定（ORDER BYで順序を固定）
    FOR t IN (
        SELECT DISTINCT table_name 
        FROM user_tab_columns 
        WHERE data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ORDER BY table_name
    ) LOOP
        -- 指定した件数に達したら終了
        v_current_count := v_current_count + 1;
        EXIT WHEN v_current_count > v_limit;

        DECLARE
            v_condition VARCHAR2(4000) := '';
        BEGIN
            -- そのテーブルの対象カラムを抽出してWHERE句を構成
            FOR c IN (
                SELECT column_name, data_type 
                FROM user_tab_columns 
                WHERE table_name = t.table_name 
                AND data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
            ) LOOP
                IF v_condition IS NOT NULL THEN
                    v_condition := v_condition || ' OR ';
                END IF;
                
                -- 日本語(マルチバイト)判定用SQL
                IF c.data_type = 'CLOB' THEN
                    v_condition := v_condition || 'INSTR(ASCIISTR(DBMS_LOB.SUBSTR(' || c.column_name || ', 1000, 1)), ''\'') > 0';
                ELSE
                    v_condition := v_condition || 'INSTR(ASCIISTR(' || c.column_name || '), ''\'') > 0';
                END IF;
            END LOOP;

            -- 1件でも条件に合致するものがあるか確認
            v_sql := 'SELECT COUNT(*) FROM dual WHERE EXISTS (SELECT 1 FROM ' || t.table_name || ' WHERE ' || v_condition || ')';
            
            EXECUTE IMMEDIATE v_sql INTO v_found_jp;
            
            IF v_found_jp > 0 THEN
                dbms_output.put_line('[MATCH] ' || t.table_name);
                v_match_count := v_match_count + 1;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('[ERROR] ' || t.table_name || ': ' || SQLERRM);
        END;
    END LOOP;

    dbms_output.put_line('--------------------------------------------------');
    dbms_output.put_line('調査終了。対象テーブル数: ' || (v_current_count - 1) || ' / 日本語あり: ' || v_match_count);
END;
/

SPOOL OFF