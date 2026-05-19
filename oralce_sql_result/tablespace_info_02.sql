
set linesize 1000 
col FILE_NAME for A45
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
ORDER BY TABLESPACE_NAME,FILE_NAME
;
