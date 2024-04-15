-- REDO Log Information

SELECT
    GROUP#,
    TYPE,
    MEMBER,
    -- ROUND(BYTES / 1024 / 1024) AS FILE_SIZE_MB
FROM V$LOGFILE;

--ユーザ(HIGASHI)が所有するすべてのオブジェクトを削除
BEGIN
   FOR obj IN (SELECT object_name, object_type FROM all_objects WHERE owner = 'HIGASHI') LOOP
      BEGIN
         IF obj.object_type = 'TABLE' THEN
            EXECUTE IMMEDIATE 'DROP TABLE HIGASHI.' || obj.object_name || ' CASCADE CONSTRAINTS';
         ELSE
            EXECUTE IMMEDIATE 'DROP ' || obj.object_type || ' HIGASHI.' || obj.object_name;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to drop ' || obj.object_type || ' ' || obj.object_name);
      END;
   END LOOP;
END;
/

--ユーザ(HIGASHI)が所有するすべてのオブジェクトを確認
SET LINESIZE 100
SET PAGESIZE 500
COL object_name FORMAT A36
COL object_type FORMAT A16
SELECT object_name, object_type 
FROM all_objects 
WHERE owner = 'HIGASHI'
ORDER BY object_type 
;


-- ロール(ROLE)にユーザ(HIGASHI)が所有するテーブルの権限を付与
BEGIN
   FOR t IN (SELECT table_name FROM all_tables WHERE owner = 'HIGASHI') LOOP
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON HIGASHI.' || t.table_name || ' TO ROLE';
   END LOOP;
END;
/
-- ロール(ROLE)にユーザ(HIGASHI)が所有するテーブルの権限を付与 確認
SET LINESIZE 100
SET PAGESIZE 500
COL GRANTEE FORMAT A12
COL OWNER FORMAT A12
COL TABLE_NAME FORMAT A16
COL PRIVILEGE FORMAT A10
SELECT GRANTEE, OWNER, TABLE_NAME, PRIVILEGE 
FROM DBA_TAB_PRIVS WHERE GRANTEE = 'ROLE';

-- ロール(ROLE)にユーザ(HIGASHI)が所有するシーケンスの権限を付与
BEGIN
   FOR s IN (SELECT sequence_name FROM all_sequences WHERE sequence_owner = 'HIGASHI') LOOP
      EXECUTE IMMEDIATE 'GRANT SELECT ON HIGASHI.' || s.sequence_name || ' TO ROLE';
   END LOOP;
END;
/
-- ロールにユーザ(HIGASHI)が所有するシーケンスの権限を付与 確認
SET LINESIZE 100
SET PAGESIZE 500
COL TABLE_NAME FORMAT A16
COL PRIVILEGE FORMAT A10
SELECT table_name, privilege 
FROM USER_TAB_PRIVS 
WHERE table_name IN (SELECT sequence_name FROM USER_SEQUENCES);

-- ロールにユーザ(HIGASHI)が所有するテーブルとシーケンスの権限を付与を一度に確認
COL ROLE FORMAT A10
COL TABLE_NAME FORMAT A16
COL PRIVILEGE FORMAT A10
COL OBJECT_TYPE FORMAT A16
SELECT role, table_name, privilege, 'TABLE' as object_type
FROM ROLE_TAB_PRIVS 
WHERE owner = 'HIGASHI' AND table_name IN (SELECT table_name FROM USER_TABLES)
UNION ALL
SELECT role, table_name, privilege, 'SEQUENCE' as object_type
FROM ROLE_TAB_PRIVS 
WHERE owner = 'HIGASHI' AND table_name IN (SELECT sequence_name FROM USER_SEQUENCES)
AND ROLE='ROLE'
;

-- ユーザのロールと権限を同時に表示
SET LINESIZE 100
SET PAGESIZE 500
COL GRANTEE FORMAT A12       
COL PRIVILEGE FORMAT A20
COL TYPE FORMAT A20
SELECT GRANTEE, PRIVILEGE, 'SYSTEM PRIVILEGE' AS TYPE
FROM DBA_SYS_PRIVS
WHERE GRANTEE = 'NISHI'
UNION ALL
SELECT GRANTEE, GRANTED_ROLE AS PRIVILEGE, 'ROLE' AS TYPE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE = 'NISHI';

-- スキーマのディスク使用量をを確認する
SELECT SUM(bytes)/1024/1024 "Size in MB" 
FROM dba_segments 
WHERE owner = '<スキーマ名>'
;
-- default tablespace　を確認する
SELECT property_value 
FROM database_properties 
WHERE property_name = 'DEFAULT_PERMANENT_TABLESPACE'
;

PROPERTY_VALUE
----------------
SYSTEM

-- default tablespace　を変更する
ALTER DATABASE DEFAULT TABLESPACE users;

-- アーカイブログモードを確認する
SELECT log_mode
FROM v$database;

LOG_MODE
----------
ARCHIVELOG

-- アーカイブログモードに変更する
alter database archivelog;

-- データベースのオープンモードを確認する
SQL> SELECT open_mode FROM v$database;

OPEN_MODE
------------------
READ WRITE
-- ユーザーが使用可能な表領域、それに対するQUOTA、およびデフォルト表領域
SET LINESIZE 200
SET PAGESIZE 100
COL USERNAME FORMAT A12
COL TABLESPACE_NAME FORMAT 16
COL default_tablespace FORMAT A14
COL temporary_tablespace FORMAT A14
SELECT u.username, q.tablespace_name, q.bytes, q.max_bytes, 
u.default_tablespace, u.temporary_tablespace
FROM dba_ts_quotas q
JOIN dba_users u ON q.username = u.username
WHERE u.username = 'NISHI';

-- ディレクトリオブジェクトの確認
SET LINESIZE 200
SET PAGESIZE 500
COL DIRECTORY_NAME FORMAT A24
COL DIRECTORY_PATH FORMAT A66
COL OWNER FORMAT A10
SELECT DIRECTORY_NAME, DIRECTORY_PATH, OWNER 
FROM dba_directories 
WHERE DIRECTORY_NAME = 'DPUMP_DIR';

-- ディレクトリオブジェクトに対する権限の確認
SET LINESIZE 200
SET PAGESIZE 500
COL grantee FORMAT A14
COL privilege FORMAT A14
SELECT grantee, privilege 
FROM dba_tab_privs 
WHERE table_name = 'DPUMP_DIR';

-- ロールと権限を同時に表示
SET LINESIZE 100
SET PAGESIZE 500
COL GRANTEE FORMAT A12       
COL PRIVILEGE FORMAT A20
COL TYPE FORMAT A20
SELECT GRANTEE, PRIVILEGE, 'SYSTEM PRIVILEGE' AS TYPE
FROM DBA_SYS_PRIVS
WHERE GRANTEE = 'NISHI'
UNION ALL
SELECT GRANTEE, GRANTED_ROLE AS PRIVILEGE, 'ROLE' AS TYPE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE = 'NISHI';


-- 表領域情報
SET LINESIZE 200
SET PAGESIZE 1000
COL TABLESPACE_NAME FOR A12
COL FILE_NAME FOR A36
COL CONTENTS FOR A10    
COL BLOCK_SIZE FOR 9999
COL EXTENT_MANAGEMENT FOR A18
COL ALLOCATION_TYPE FOR A15
COL SEGMENT_SPACE_MANAGEMENT FOR A23
COL BIGFILE FOR A7
COL AUTOEXTENSIBLE FOR A13
COL M_MAXBYTES FOR 99999999999999
COL INCREMENT_BY FOR 99999999999999 
SELECT TABLESPACE_NAME, FILE_NAME, CONTENTS, BLOCK_SIZE, EXTENT_MANAGEMENT
, ALLOCATION_TYPE, SEGMENT_SPACE_MANAGEMENT, BIGFILE, AUTOEXTENSIBLE
, ROUND(M_MAXBYTES/(1024*1024)) AS M_MAXBYTES_MB
, ROUND((INCREMENT_BY*BLOCK_SIZE)/(1024*1024)) AS INCREMENT_BY_MB
FROM (
  SELECT df.TABLESPACE_NAME                
  ,df.FILE_NAME
  ,ts.CONTENTS
  ,ts.BLOCK_SIZE
  ,ts.EXTENT_MANAGEMENT
  ,ts.ALLOCATION_TYPE
  ,ts.SEGMENT_SPACE_MANAGEMENT
  ,ts.BIGFILE
  ,df.AUTOEXTENSIBLE
  ,df.MAXBYTES AS M_MAXBYTES
  ,df.INCREMENT_BY
  FROM DBA_DATA_FILES df
  JOIN DBA_TABLESPACES ts ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
  UNION
  SELECT tf.TABLESPACE_NAME
  ,tf.FILE_NAME
  ,ts.CONTENTS
  ,ts.BLOCK_SIZE
  ,ts.EXTENT_MANAGEMENT
  ,ts.ALLOCATION_TYPE
  ,ts.SEGMENT_SPACE_MANAGEMENT
  ,ts.BIGFILE
  ,tf.AUTOEXTENSIBLE
  ,tf.MAXBYTES AS M_MAXBYTES
  ,tf.INCREMENT_BY
  FROM DBA_TEMP_FILES tf
  JOIN DBA_TABLESPACES ts ON tf.TABLESPACE_NAME = ts.TABLESPACE_NAME
  UNION
  SELECT ts.TABLESPACE_NAME
  ,NULL AS FILE_NAME
  ,ts.CONTENTS
  ,ts.BLOCK_SIZE
  ,ts.EXTENT_MANAGEMENT
  ,ts.ALLOCATION_TYPE
  ,ts.SEGMENT_SPACE_MANAGEMENT
  ,ts.BIGFILE
  ,NULL AS AUTOEXTENSIBLE
  ,NULL AS M_MAXBYTES
  ,NULL AS INCREMENT_BY
  FROM DBA_TABLESPACES ts
) 
WHERE FILE_NAME IS NOT NULL
AND CONTENTS IS NOT NULL
AND BLOCK_SIZE IS NOT NULL
AND EXTENT_MANAGEMENT IS NOT NULL
AND ALLOCATION_TYPE IS NOT NULL
AND SEGMENT_SPACE_MANAGEMENT IS NOT NULL
AND BIGFILE IS NOT NULL
AND AUTOEXTENSIBLE IS NOT NULL
AND M_MAXBYTES IS NOT NULL
AND INCREMENT_BY IS NOT NULL
ORDER BY TABLESPACE_NAME
;
------------

SET LINESIZE 200
SET PAGESIZE 1000
COL TABLESPACE_NAME FOR A12
COL FILE_NAME FOR A36
COL CONTENTS FOR A10
COL BLOCK_SIZE FOR 9999
COL EXTENT_MANAGEMENT FOR A18
COL ALLOCATION_TYPE FOR A15
COL SEGMENT_SPACE_MANAGEMENT FOR A23
COL BIGFILE FOR A7
COL "自動拡張" FOR A13
COL M_MAXBYTES FOR 99999999999999
COL INCREMENT_BY FOR 99999999999999
--  
SELECT *
FROM (
  SELECT df.TABLESPACE_NAME                
  ,df.FILE_NAME
  ,ts.CONTENTS
  ,ts.BLOCK_SIZE
  ,ts.EXTENT_MANAGEMENT
  ,ts.ALLOCATION_TYPE
  ,ts.SEGMENT_SPACE_MANAGEMENT
  ,ts.BIGFILE
  ,df.AUTOEXTENSIBLE AS "自動拡張"
  ,ROUND(df.MAXBYTES/(1024*1024)) AS M_MAXBYTES_MB
  ,ROUND((df.INCREMENT_BY*ts.BLOCK_SIZE)/(1024*1024)) AS INCREMENT_BY_MB
  FROM DBA_DATA_FILES df
  JOIN DBA_TABLESPACES ts ON df.TABLESPACE_NAME = ts.TABLESPACE_NAME
  UNION
  SELECT tf.TABLESPACE_NAME
  ,tf.FILE_NAME
  ,ts.CONTENTS
  ,ts.BLOCK_SIZE
  ,ts.EXTENT_MANAGEMENT
  ,ts.ALLOCATION_TYPE
  ,ts.SEGMENT_SPACE_MANAGEMENT
  ,ts.BIGFILE
  ,tf.AUTOEXTENSIBLE AS "自動拡張"
  ,ROUND(tf.MAXBYTES/(1024*1024)) AS M_MAXBYTES_MB
  ,ROUND((tf.INCREMENT_BY*ts.BLOCK_SIZE)/(1024*1024)) AS INCREMENT_BY_MB
  FROM DBA_TEMP_FILES tf
  JOIN DBA_TABLESPACES ts ON tf.TABLESPACE_NAME = ts.TABLESPACE_NAME
  UNION
  SELECT ts.TABLESPACE_NAME
  ,NULL AS FILE_NAME
  ,ts.CONTENTS
  ,ts.BLOCK_SIZE
  ,ts.EXTENT_MANAGEMENT
  ,ts.ALLOCATION_TYPE
  ,ts.SEGMENT_SPACE_MANAGEMENT
  ,ts.BIGFILE
  ,NULL AS "自動拡張"
  ,NULL AS M_MAXBYTES_MB
  ,NULL AS INCREMENT_BY_MB
  FROM DBA_TABLESPACES ts
) 
WHERE FILE_NAME IS NOT NULL
AND CONTENTS IS NOT NULL
AND BLOCK_SIZE IS NOT NULL
AND EXTENT_MANAGEMENT IS NOT NULL
AND ALLOCATION_TYPE IS NOT NULL
AND SEGMENT_SPACE_MANAGEMENT IS NOT NULL
AND BIGFILE IS NOT NULL
AND "自動拡張" IS NOT NULL
AND M_MAXBYTES_MB IS NOT NULL
AND INCREMENT_BY_MB IS NOT NULL
ORDER BY TABLESPACE_NAME;

