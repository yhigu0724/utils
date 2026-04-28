SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET LINESIZE 2000
SET TRIMSPOOL ON
SET PAGESIZE 0
SET VERIFY OFF

-- 出力ファイル名の指定
SPOOL check_convert_error.csv

DECLARE
    --------------------------------------------------
    -- ★ 設定パラメータ
    --------------------------------------------------
    v_from_row      INTEGER := 1;      -- 調査開始テーブル番号
    v_to_row        INTEGER := 100;    -- 調査終了テーブル番号
    --------------------------------------------------

    v_sql           CLOB;
    v_pk_cols       VARCHAR2(1000);
    v_pk_select     VARCHAR2(1000);
    
    -- 動的カーソル用
    TYPE cur_typ IS REF CURSOR;
    c_data          cur_typ;
    
    -- 出力用変数
    out_table       VARCHAR2(128);
    out_column      VARCHAR2(128);
    out_context     VARCHAR2(4000);
    out_pk_val      VARCHAR2(4000);

BEGIN
    -- CSVヘッダー出力
    dbms_output.put_line('TABLE_NAME,COLUMN_NAME,CONTEXT_3CHAR,PK_VALUES');

    -- 1. 対象テーブルのループ
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

        -- 2. テーブルのPKカラムを特定（カンマ連結）
        v_pk_cols := '';
        v_pk_select := '';
        FOR p IN (
            SELECT column_name 
            FROM user_cons_columns a
            JOIN user_constraints b ON a.constraint_name = b.constraint_name
            WHERE b.constraint_type = 'P' 
              AND b.table_name = t.table_name
            ORDER BY a.position
        ) LOOP
            v_pk_cols := v_pk_cols || p.column_name || ' || '','' || ';
        END LOOP;
        
        -- PKがない場合はROWIDで代用（10gへの逆引き用ではなく19c内の特定用）
        IF v_pk_cols IS NULL THEN
            v_pk_select := 'ROWID';
        ELSE
            v_pk_select := rtrim(v_pk_cols, ' || '','' || ');
        END IF;

        -- 3. 対象カラムのループ
        FOR c IN (
            SELECT column_name, data_type 
            FROM user_tab_columns 
            WHERE table_name = t.table_name 
              AND data_type IN ('CHAR', 'VARCHAR2', 'CLOB')
        ) LOOP
            
            -- 動的SQLの組み立て
            -- 条件：'?'(0x3F)を含み、かつASCIISTRに'\'(日本語等のマルチバイト)が含まれる
            v_sql := 'SELECT ' ||
                     '''' || t.table_name || ''', ' ||
                     '''' || c.column_name || ''', ' ||
                     'REGEXP_SUBSTR(' || c.column_name || ', ''...?.{0,3}''), ' ||
                     v_pk_select || ' ' ||
                     'FROM "' || t.table_name || '" ' ||
                     'WHERE "' || c.column_name || '" LIKE ''%?%'' ' ||
                     'AND INSTR(ASCIISTR("' || c.column_name || '"), ''\'') > 0';

            BEGIN
                OPEN c_data FOR v_sql;
                LOOP
                    FETCH c_data INTO out_table, out_column, out_context, out_pk_val;
                    EXIT WHEN c_data%NOTFOUND;
                    
                    -- CSV形式で出力（ダブルクォーテーションで囲む）
                    dbms_output.put_line('"' || out_table || '","' || out_column || '","' || out_context || '","' || out_pk_val || '"');
                END LOOP;
                CLOSE c_data;
            EXCEPTION
                WHEN OTHERS THEN 
                    IF c_data%ISOPEN THEN CLOSE c_data; END IF;
            END;

        END LOOP;
    END LOOP;
END;
/
SPOOL OFF