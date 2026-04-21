SET SERVEROUTPUT ON SIZE 1000000
SET FEEDBACK OFF
SET LINESIZE 1000
SET TRIMSPOOL ON
SET PAGESIZE 0

-- 実行範囲に合わせてファイル名を変えると便利です
SPOOL jp_tables_report.txt

DECLARE
    --------------------------------------------------
    -- ★ 範囲指定パラメータ
    --------------------------------------------------
    v_from_row      INTEGER := 1;
    v_to_row        INTEGER := 1000;
    --------------------------------------------------

    v_found_jp      INTEGER;
    v_sql           VARCHAR2(32767);
    v_target_found  BOOLEAN;
    v_start_time    VARCHAR2(20);
BEGIN
    v_start_time := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
    dbms_output.put_line('==================================================');
    dbms_output.put_line('開始時刻: ' || v_start_time);
    dbms_output.put_line('調査範囲: ' || v_from_row || ' から ' || v_to_row || ' 番目');
    dbms_output.put_line('==================================================');

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

        FOR c IN (
            SELECT column_name, data_type 
            FROM user_tab_columns 
            WHERE table_name = t.table_name 
            AND data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ) LOOP
            
            v_sql := 'SELECT COUNT(*) FROM dual WHERE EXISTS (SELECT 1 FROM "' || t.table_name || '" WHERE ';
            
            IF c.data_type = 'CLOB' THEN
                v_sql := v_sql || 'INSTR(ASCIISTR(DBMS_LOB.SUBSTR("' || c.column_name || '", 1000, 1)), ''\'') > 0';
            ELSE
                v_sql := v_sql || 'INSTR(ASCIISTR("' || c.column_name || '"), ''\'') > 0';
            END IF;
            
            v_sql := v_sql || ')';

            BEGIN
                EXECUTE IMMEDIATE v_sql INTO v_found_jp;
                IF v_found_jp > 0 THEN
                    v_target_found := TRUE;
                    EXIT; 
                END IF;
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
        END LOOP;

        IF v_target_found THEN
            dbms_output.put_line(t.table_name);
        END IF;

    END LOOP;

    dbms_output.put_line('--------------------------------------------------');
    dbms_output.put_line('終了時刻: ' || TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
    dbms_output.put_line('開始時刻: ' || v_start_time);
    dbms_output.put_line('==================================================');
END;
/

SPOOL OFF