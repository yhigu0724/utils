set linesize 200
set pages 1000
col TYPE for a20
col VALUE for '0000'
SELECT (CASE
WHEN type = 'REDO THREAD' THEN 'MAXINSTANCES'
WHEN type = 'REDO LOG' THEN 'MAXLOGFILES'
WHEN type = 'DATAFILE' THEN 'MAXDATAFILES'
WHEN type = 'LOG HISTORY' THEN 'MAXLOGHISTORY'
END) AS "TYPE"
,Records_total AS "VALUE"
FROM v$controlfile_record_section
WHERE TYPE IN ('REDO LOG','DATAFILE','REDO THREAD','LOG HISTORY')
UNION
SELECT 'MAXLOGMEMBERS',DIMLM
FROM x$kccdi;


col PARAM_NAME for a35 
col PARAM_VALUE for a70
col PARAM_TYPE for a10
col SES_MOD for a15 
col SYS_MOD for a15
col MOD for a15

ttitle left '初期化パラメータ情報'
spool initparam_info.lis

SELECT name PARAM_NAME
, value PARAM_VALUE
, TO_CHAR(
CASE WHEN type=1 THEN 'ブール型'
WHEN type=2 THEN '文字列'
WHEN type=3 THEN '整数'
WHEN type=4 THEN 'ファイル'
ELSE 'etc'
END) PARAM_TYPE
, isses_modifiable SES_MOD
, issys_modifiable SYS_MOD
, ismodified MOD
, isodefault ISODEF
FROM v$parameter2
ORDER BY name
;



