SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

DECLARE
    v_limit INTEGER := 20; -- 少し増やして20件でテスト
    v_current_count INTEGER := 0;
    v_row_exists    INTEGER;
    v_found_jp      INTEGER;
    v_sql           VARCHAR2(32767);
BEGIN
    dbms_output.put_line('--- 実行状況確認モード ---');

    FOR t IN (
        SELECT DISTINCT table_name 
        FROM user_tab_columns 
        WHERE data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ORDER BY table_name
    ) LOOP
        v_current_count := v_current_count + 1;
        EXIT WHEN v_current_count > v_limit;

        -- 1. まずデータが1件でもあるか確認
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM dual WHERE EXISTS (SELECT 1 FROM ' || t.table_name || ')' INTO v_row_exists;

        IF v_row_exists = 0 THEN
            dbms_output.put_line(v_current_count || ': [空テーブル] ' || t.table_name);
        ELSE
            -- 2. データがある場合のみ、日本語チェック
            DECLARE
                v_condition VARCHAR2(4000) := '';
            BEGIN
                FOR c IN (
                    SELECT column_name, data_type 
                    FROM user_tab_columns 
                    WHERE table_name = t.table_name 
                    AND data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
                ) LOOP
                    IF v_condition IS NOT NULL THEN v_condition := v_condition || ' OR '; END IF;
                    IF c.data_type = 'CLOB' THEN
                        v_condition := v_condition || 'INSTR(ASCIISTR(DBMS_LOB.SUBSTR(' || c.column_name || ', 1000, 1)), ''\'') > 0';
                    ELSE
                        v_condition := v_condition || 'INSTR(ASCIISTR(' || c.column_name || '), ''\'') > 0';
                    END IF;
                END LOOP;

                v_sql := 'SELECT COUNT(*) FROM dual WHERE EXISTS (SELECT 1 FROM ' || t.table_name || ' WHERE ' || v_condition || ')';
                EXECUTE IMMEDIATE v_sql INTO v_found_jp;
                
                IF v_found_jp > 0 THEN
                    dbms_output.put_line(v_current_count || ': [★日本語あり] ' || t.table_name);
                ELSE
                    dbms_output.put_line(v_current_count || ': [英数字のみ] ' || t.table_name);
                END IF;
            END;
        END IF;
    END LOOP;
END;
/