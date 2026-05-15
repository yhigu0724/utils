# RHELのプロンプトで実行
sqlplus -S NISHI/xxxxx@sjisdb << 'EOF'
SET PAGESIZE 0
SET LINESIZE 32767
SET FEEDBACK OFF
SET TRIMSPOOL ON
SET TERMOUT OFF
SET ECHO OFF
SET LONG 2000000

-- 全オブジェクトを個別のファイルに出力するスクリプトを生成
SPOOL run_extract.sql
SELECT 
    -- ファイル名の先頭に TYPE を付けて重複を避ける
    'SPOOL source_sql/' || OBJECT_TYPE || '_' || OBJECT_NAME || '.sql' || CHR(10) ||
    'SELECT TEXT FROM USER_SOURCE WHERE NAME = ''' || OBJECT_NAME || ''' AND TYPE = ''' || OBJECT_TYPE || ''' ORDER BY LINE;' || CHR(10) ||
    'SELECT ''/'' FROM DUAL;' || CHR(10) ||
    'SPOOL OFF'
FROM USER_OBJECTS 
WHERE OBJECT_TYPE IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'TRIGGER');
SPOOL OFF

-- 抽出実行
@run_extract.sql
EXIT
EOF
    
SELECT 
    OWNER,          -- シノニムの所有者（PUBLICならPUBLICと出ます）
    SYNONYM_NAME,   -- 表示されている名前
    TABLE_OWNER,    -- ★本当の所有者（誰が作ったものか）
    TABLE_NAME      -- ★本当のオブジェクト名
FROM 
    ALL_SYNONYMS
WHERE 
    TABLE_OWNER != 'あなたのユーザー名'  -- 自分の所有でないものを抽出
    AND TABLE_NAME IN (
        SELECT OBJECT_NAME FROM ALL_OBJECTS 
        WHERE OBJECT_TYPE IN ('PROCEDURE', 'FUNCTION', 'PACKAGE')
    )
ORDER BY TABLE_OWNER;
