spool oracle_config.txt
set feedback off
set trimspool on
set pagesize 500
set linesize 200
prompt ******************************************************************************************
COL username format a30
COL default_tablespace format a30
SELECT username, default_tablespace 
FROM dba_users 
WHERE username = 'NISHI';
prompt ******************************************************************************************
COL username format a30
COL tablespace_name  format a30
COL MAX_BYTES  format 9999999999
SELECT username, tablespace_name, MAX_BYTES
FROM dba_ts_quotas 
WHERE username = 'NISHI' order by username;
prompt ******************************************************************************************
COL GRANTEE format a30
COL GRANTED_ROLE  format a30
SELECT GRANTEE, GRANTED_ROLE 
FROM dba_role_privs 
WHERE grantee = 'NISHI';
COL GRANTEE GRANTEE a30
COL TABLE_NAME  format a30
COL PRIVILEGE  format a30
SELECT GRANTEE, OWNER, TABLE_NAME, PRIVILEGE
FROM dba_tab_privs 
WHERE GRANTEE='NISHI';
prompt ******************************************************************************************
prompt --- List Parameters
COL NAME format a30
COL VALUE format a30
PROMPT SELECT NAME, VALUE FROM v$PARAMETER;
SELECT NAME, VALUE FROM v$PARAMETER;
prompt ******************************************************************************************
prompt --- List DBA Users
col USERNAME format a10
col ACCOUNT_STATUS format a20
prompt SELECT USERNAME,ACCOUNT_STATUS FROM DBA_USERS WHERE ACCOUNT_STATUS='OPEN'
SELECT USERNAME,ACCOUNT_STATUS
FROM DBA_USERS WHERE ACCOUNT_STATUS='OPEN';
prompt ******************************************************************************************
prompt --- List All Users
COL USERNAME FORMAT a30
COL CREATED FORMAT a10
prompt SELECT * FROM ALL_USERS ORDER BY USERNAME;
SELECT USERNAME, CREATED FROM ALL_USERS ORDER BY CREATED;
prompt ******************************************************************************************
prompt --- User's Role
COL GRANTEE FORMAT a20
COL GRANTED_ROLE FORMAT a30
prompt SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE='NISHI';
SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE='NISHI';
prompt ******************************************************************************************
prompt --- User's Default Tablespace
COL USERNAME FORMAT a10
COL DEFAULT_TABLESPACE FORMAT a20
PROMPT SELECT username, default_tablespace
PROMPT FROM dba_users
PROMPT WHERE username = 'NISHI';
SELECT username, default_tablespace
FROM dba_users
WHERE username = 'NISHI';
prompt ******************************************************************************************
PROMPT --- User's Schema Quota
col USERNAME format a30
col TABLESPACE_NAME format a30
select USERNAME
     , TABLESPACE_NAME
     , BYTES / 1024 / 1024 as MBytes
     , decode(MAX_BYTES
         , -1 , -1
         , MAX_BYTES / 1024 / 1024) as Max_MBytes
     , ROUND((BYTES/MAX_BYTES)*100, 1) as "TS_Usage(%)"
  from DBA_TS_QUOTAS
 order by USERNAME, TABLESPACE_NAME;
prompt ******************************************************************************************
PROMPT --- User's Table
col OWNER format a10
col TABLE_NAME format a30
PROMPT SELECT OWNER, TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'NISHI' ORDER BY TABLE_NAME;
SELECT OWNER, TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'NISHI' ORDER BY TABLE_NAME;
-- prompt ******************************************************************************************
-- prompt --- DBA User Privileges
-- COL GRANTEE FORMAT A30
-- COL PRIVILEGE FORMAT a40
-- COL ADMIN_OPTION FORMAT a30
-- PROMPT SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION FROM DBA_SYS_PRIVS;
-- SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION FROM DBA_SYS_PRIVS ORDER by GRANTEE;
prompt ******************************************************************************************
prompt --- Default passwod life time
COL PROFILE FORMAT a10
COL RESOURCE_NAME FORMAT a20
COL RESOURCE_TYPE  FORMAT a10
COL LIMIT FORMAT a10
SELECT
    PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT 
FROM
    DBA_PROFILES 
WHERE
    RESOURCE_NAME = 'PASSWORD_LIFE_TIME';
prompt ******************************************************************************************
prompt --- Profile: SYS and SYSTEM
COL USERNAME FORMAT a10
COL PROFILE FORMAT a10
prompt SELECT USERNAME,PROFILE FROM DBA_USERS WHERE USERNAME = 'SYS' or USERNAME = 'SYSTEM';
SELECT USERNAME,PROFILE FROM DBA_USERS WHERE USERNAME = 'SYS' or USERNAME = 'SYSTEM';
prompt ******************************************************************************************
prompt --- Oracle components
col COMP_NAME for a35
col VERSION for a30
col STATUS for a11
col CONTROL for a12
col SCHEMA for a12
prompt SELECT COMP_NAME,VERSION,STATUS,CONTROL,SCHEMA FROM DBA_REGISTRY ORDER BY 1;
SELECT COMP_NAME,VERSION,STATUS,CONTROL,SCHEMA FROM DBA_REGISTRY ORDER BY 1;
prompt ******************************************************************************************
prompt --- Auto maintenance tasks
col client_name for a40
col status for a10
col window_group for a15
prompt select client_name,status,window_group from dba_autotask_client;
select client_name,status,window_group from dba_autotask_client;
prompt ******************************************************************************************
PROMPT --- Server Type
PROMPT select server from v$session where sid = userenv('SID');
select server from v$session where sid = userenv('SID');
prompt ******************************************************************************************
PROMPT --- Tablespace information
col TABLESPACE_NAME for a15
col CONTENTS for a9
col BLOCK_SIZE for a10
col BLOCK_SIZE format 9999
col EXTENT_MANAGEMENT for a17
col ALLOCATION_TYPE for a15
col SEGMENT_SPACE_MANAGEMENT for a24
col BIGFILE for a7
PROMPT SELECT TABLESPACE_NAME, CONTENTS, BLOCK_SIZE, EXTENT_MANAGEMENT, ALLOCATION_TYPE, SEGMENT_SPACE_MANAGEMENT, BIGFILE
PROMPT FROM DBA_TABLESPACES;
SELECT TABLESPACE_NAME, CONTENTS, BLOCK_SIZE, EXTENT_MANAGEMENT, ALLOCATION_TYPE, SEGMENT_SPACE_MANAGEMENT, BIGFILE
FROM DBA_TABLESPACES;
prompt ******************************************************************************************
PROMPT --- Tablespace Data Files
col FILE_NAME for A40
col TABLESPACE_NAME for A10
col ONLINE_STATUS for A14
--  
SELECT TABLESPACE_NAME                -- 表領域名
,FILE_NAME                            -- データファイル名
,BYTES/1024/1024 M_BYTE               -- ファイルサイズ
,ONLINE_STATUS                        -- ステータス
,AUTOEXTENSIBLE                       -- 自動拡張か否か
,round(MAXBYTES/1024/1024) M_MAXBYTES -- ファイルの最大サイズ
,INCREMENT_BY                         -- 自動拡張の増分ブロック数
FROM DBA_DATA_FILES 
union all
select TABLESPACE_NAME
,FILE_NAME
,BYTES/1024/1024 M_BYTE
,STATUS
,AUTOEXTENSIBLE
,round(MAXBYTES/1024/1024) M_MAXBYTES
,INCREMENT_BY
from DBA_TEMP_FILES
ORDER BY TABLESPACE_NAME,FILE_NAME;
prompt ******************************************************************************************
PROMPT --- Tablespace Space Usage
COL TABLESPACE_NAME FORMAT  A18
COL "Size(MB)" FORMAT 99999
COL "Used(MB)" FORMAT 99999
COL "Free(MB)" FORMAT 99999
COL "Usage(%)"  FORMAT 999
SELECT
  A.TABLESPACE_NAME TABLESPACE_NAME
  , ROUND(SUM(BYTES) / 1024 / 1024, 1) "Size(MB)"
  , ROUND(SUM(BYTES - SUM_BYTES) / 1024 / 1024, 1) "Used(MB)"
  , ROUND(SUM(SUM_BYTES) / 1024 / 1024, 1) "Free(MB)"
  , ROUND((SUM(BYTES - SUM_BYTES) / 1024) / (SUM(BYTES) / 1024) * 100, 1) "Usage(%)" 
FROM
  DBA_DATA_FILES A 
  LEFT JOIN 　( 
    SELECT
      TABLESPACE_NAME
      , FILE_ID
      , NVL(SUM(BYTES), 0) SUM_BYTES 　 
    FROM
      DBA_FREE_SPACE 
    GROUP BY
      TABLESPACE_NAME
      , FILE_ID
  ) B 
    ON A.TABLESPACE_NAME = B.TABLESPACE_NAME 
    AND A.FILE_ID = B.FILE_ID 
GROUP BY
  A.TABLESPACE_NAME 
ORDER BY
  1;
prompt ******************************************************************************************
spool off
quit
