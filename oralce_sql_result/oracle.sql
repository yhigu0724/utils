spool oraclelog.txt
set feedback off
set trimspool on
set pagesize 500
set linesize 200
--- available DBA Users
col USERNAME format a10
col ACCOUNT_STATUS format a20
prompt SELECT USERNAME,ACCOUNT_STATUS FROM DBA_USERS WHERE ACCOUNT_STATUS='OPEN'
SELECT USERNAME,ACCOUNT_STATUS
FROM DBA_USERS WHERE ACCOUNT_STATUS='OPEN';
prompt *******************
spool off
quit
