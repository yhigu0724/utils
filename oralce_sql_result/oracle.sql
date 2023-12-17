spool oracle_config.txt
set feedback off
set trimspool on
set pagesize 500
set linesize 200
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
prompt --- DBA User Privileges
COL GRANTEE FORMAT A30
COL PRIVILEGE FORMAT a40
COL ADMIN_OPTION FORMAT a30
PROMPT SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION FROM DBA_SYS_PRIVS;
SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION FROM DBA_SYS_PRIVS ORDER by GRANTEE;
prompt ******************************************************************************************
prompt --- Default passwod life time
COL PROFILE FORMAT a10
COL RESOURCE_NAME FORMAT a20
COL RESOURCE_TYPE  FORMAT a10
COL LIMIT FORMAT a10
prompt SELECT
prompt    PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT 
prompt FROM
prompt   DBA_PROFILES 
prompt WHERE
prompt    RESOURCE_NAME = 'PASSWORD_LIFE_TIME';
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
prompt --- Fast recovery area
col NAME for a30
col TYPE for a30
col VALUE for a30
prompt show parameters db_recovery;
show parameters db_recovery;
prompt SHOW PARAMETER DB_RECOVERY_FILE_DEST;
SHOW PARAMETER DB_RECOVERY_FILE_DEST;
prompt ******************************************************************************************
prompt --- Details for log_archive_dest_1 and log_archive_dest_2
col NAME for a30
col VALUE for a30
PROMPT SELECT name,value FROM v$parameter WHERE name = 'log_archive_dest_1' or name = 'log_archive_dest_2';
SELECT name,value FROM v$parameter WHERE name = 'log_archive_dest_1' or name = 'log_archive_dest_2';
prompt ******************************************************************************************
prompt --- log_archive_format
col NAME for a20
col TYPE for a10
col VALUE for a28
PROMPT SHOW PARAMETERS log_archive_format;
SHOW PARAMETERS log_archive_format;
prompt ******************************************************************************************
PROMPT --- Memory allocation
col NAME for a15
col TYPE for a15
col VALUE for a15
PROMPT SHOW PARAMETERS target
SHOW PARAMETERS target;
prompt ******************************************************************************************
PROMPT --- Character set
COL PARAMETER FORMAT a30
COL VALUE FORMAT a20
PROMPT SELECT PARAMETER, VALUE
PROMPT FROM NLS_DATABASE_PARAMETERS
PROMPT WHERE PARAMETER IN ('NLS_CHARACTERSET', 'NLS_NCHAR_CHARACTERSET', 'NLS_TERRITORY')
SELECT PARAMETER, VALUE
FROM NLS_DATABASE_PARAMETERS
WHERE PARAMETER IN ('NLS_CHARACTERSET', 'NLS_NCHAR_CHARACTERSET', 'NLS_TERRITORY');
prompt ******************************************************************************************
PROMPT --- The number of processes and sessions
PROMPT SELECT NAME, VALUE
PROMPT FROM V$SYSTEM_PARAMETER
PROMPT WHERE NAME IN ('processes', 'sessions')
SELECT NAME, VALUE
FROM V$SYSTEM_PARAMETER
WHERE NAME IN ('processes', 'sessions');
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
PROMPT SELECT TABLESPACE_NAME
PROMPT ,FILE_NAME
PROMPT ,BYTES/1024/1024 M_BYTE
PROMPT ,ONLINE_STATUS
PROMPT ,AUTOEXTENSIBLE
PROMPT ,round(MAXBYTES/1024/1024) M_MAXBYTES
PROMPT ,INCREMENT_BY
PROMPT FROM DBA_DATA_FILES 
PROMPT union all
PROMPT select TABLESPACE_NAME
PROMPT ,FILE_NAME
PROMPT ,BYTES/1024/1024 M_BYTE
PROMPT ,STATUS
PROMPT ,AUTOEXTENSIBLE
PROMPT ,round(MAXBYTES/1024/1024) M_MAXBYTES
PROMPT ,INCREMENT_BY
PROMPT from DBA_TEMP_FILES
PROMPT ORDER BY TABLESPACE_NAME,FILE_NAME
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
spool off
quit
