 
--  
-- V8 Replication Migration backup script VERSION 1.51, 
-- generated "May  5 2003" "10:45:31" by CPP for "DB2 UDB V8" server:
--
-- DO NOT DELETE ANY SQL STATEMENTS FROM THIS SCRIPT.
--

-- Users must either create the tablespaces BACKUPTS, UOWTS, and OTHERTS
-- before running this script, or change these tablespace names to
-- existing ones.
--
-- For example, to change all tablespace names to userspace1
-- with vi editor:
--
-- enter: :%s/in [A-Z]*TS/in userspace1/
--
-- At the end of migration, when it is clear that fallback is not
-- required, the BACKUP schema (and its tables) should be dropped to
-- clean up.
--
-- All Replication control tables and the CD tables will be
-- backed up to tablespace BACKUPTS.
--
-- Tablespace UOWTS and OTHERTS are the tablespaces where
-- BACKUP.IBMSNV8 tables need to be created by this script.
-- Migration will create the new (migrated) DPROPR V8 control tables
-- in these tablespaces also.
 
--
-- Backup tablespaces must exist before backup tables can be created.
--
--    See "CREATE TABLESPACE" in your SQL Reference.
--
-- Choose parameters to optimize backup security rather than performance.
 
--
-- To estimate BACKUPTS tablespace size required, run a script
-- similar to this:
--
--
-- db2 connect to $1 user $2 using $3
--
-- db2 'drop table asn.ibmsnap_temp'
--
-- db2 "create table asn.ibmsnap_temp \
--     ( tabschema varchar( 30 ), tabname varchar( 128 ) )"
--
-- db2 "insert into asn.ibmsnap_temp               \
--     select rtrim( tabschema ), rtrim( tabname ) \
--     from syscat.tables where tabschema = 'ASN'"
--
-- db2 "insert into asn.ibmsnap_temp               \
--     select rtrim( tabschema ), rtrim( tabname ) \
--     from syscat.tables                          \
--     where type = 'T'                            \
--       and char( rtrim( tabschema ) || ',' || tabname ) \
--     in (  select rtrim( cd_owner ) || ',' || cd_table  \
--     from asn.ibmsnap_register )"
--
-- db2 'commit'
--
-- db2 "select 'runstats on table ' || tabschema || '.' || tabname || ' ;' \
--     from asn.ibmsnap_temp" | \
--     perl -e "while(<>) { s/ *$// ; print if /^runstats / ; }"  > temp.clp
--
-- db2 -tf temp.clp
--
-- # Round tablespace estimate up to next multiple of 100, times 3:
--
-- db2 "select 'create tablespace TS managed by database using ( file ''FILE'' ' \
--     || rtrim( char( ( sum( abs ( fpages ) ) / 100 + 10 ) * 300 ) )            \
--     || ' ) extentsize 2'                                                      \
--     from syscat.tables where ( tabschema, tabname )                           \
--     in ( select tabschema, tabname from asn.ibmsnap_temp ) "
--
-- db2 'drop table asn.ibmsnap_temp'
--
 
------------------------------------------------------------------------
-- The DB2 V8 Replication tables and indices:
------------------------------------------------------------------------
 
CREATE TABLE BACKUP.IBMSNV8_CAPSCHEMAS ( 
   CAP_SCHEMA_NAME    VARCHAR(030)                        )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_CAPSCHEMAX
ON BACKUP.IBMSNV8_CAPSCHEMAS ( 
   CAP_SCHEMA_NAME    ASC                                 ) ; 
 
CREATE TABLE BACKUP.IBMSNV8_RESTART ( 
   MAX_COMMITSEQ      CHAR(010)     FOR BIT DATA NOT NULL ,
   MAX_COMMIT_TIME    TIMESTAMP                  NOT NULL ,
   MIN_INFLIGHTSEQ    CHAR(010)     FOR BIT DATA NOT NULL , 
   CURR_COMMIT_TIME   TIMESTAMP                  NOT NULL , 
   CAPTURE_FIRST_SEQ  CHAR(010)     FOR BIT DATA NOT NULL )
in OTHERTS  ;
 
CREATE TABLE BACKUP.IBMSNV8_REGISTER (
   SOURCE_OWNER       VARCHAR(030)               NOT NULL , 
   SOURCE_TABLE       VARCHAR(128)               NOT NULL , 
   SOURCE_VIEW_QUAL   SMALLINT                   NOT NULL ,
   GLOBAL_RECORD      CHAR(001)                  NOT NULL ,
   SOURCE_STRUCTURE   SMALLINT                   NOT NULL ,
   SOURCE_CONDENSED   CHAR(001)                  NOT NULL ,
   SOURCE_COMPLETE    CHAR(001)                  NOT NULL ,
   CD_OWNER           VARCHAR(030)                        , 
   CD_TABLE           VARCHAR(128)                        , 
   PHYS_CHANGE_OWNER  VARCHAR(030)                        , 
   PHYS_CHANGE_TABLE  VARCHAR(128)                        , 
   CD_OLD_SYNCHPOINT  CHAR(010)     FOR BIT DATA          ,
   CD_NEW_SYNCHPOINT  CHAR(010)     FOR BIT DATA          ,
   DISABLE_REFRESH    SMALLINT                   NOT NULL ,
   CCD_OWNER          VARCHAR(030)                        , 
   CCD_TABLE          VARCHAR(128)                        , 
   CCD_OLD_SYNCHPOINT CHAR(010)     FOR BIT DATA          ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SYNCHTIME          TIMESTAMP                           ,
   CCD_CONDENSED      CHAR(001)                           ,
   CCD_COMPLETE       CHAR(001)                           ,
   ARCH_LEVEL         CHAR(004)                  NOT NULL ,
   DESCRIPTION        CHAR(254)                           ,
   BEFORE_IMG_PREFIX  VARCHAR(004)                        ,
   CONFLICT_LEVEL     CHAR(001)                           ,
   CHG_UPD_TO_DEL_INS CHAR(001)                           , 
   CHGONLY            CHAR(001)                           ,
   RECAPTURE          CHAR(001)                           , 
   OPTION_FLAGS       CHAR(004)                  NOT NULL ,
   STOP_ON_ERROR      CHAR(001)                           , 
   STATE              CHAR(001)                           , 
   STATE_INFO         CHAR(008)                           )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_REGISTERX
ON BACKUP.IBMSNV8_REGISTER (
   SOURCE_OWNER       ASC                                 ,
   SOURCE_TABLE       ASC                                 ,
   SOURCE_VIEW_QUAL   ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_REGISTERX1 
ON BACKUP.IBMSNV8_REGISTER (
   PHYS_CHANGE_OWNER  ASC                                 , 
   PHYS_CHANGE_TABLE  ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_REGISTERX2 
ON BACKUP.IBMSNV8_REGISTER (
   GLOBAL_RECORD      ASC                                 ) ; 

CREATE TABLE BACKUP.IBMSNV8_PRUNCNTL (
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   SYNCHTIME          TIMESTAMP                           ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SOURCE_OWNER       VARCHAR(030)               NOT NULL , 
   SOURCE_TABLE       VARCHAR(128)               NOT NULL , 
   SOURCE_VIEW_QUAL   SMALLINT                   NOT NULL ,
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   CNTL_SERVER        CHAR(018)                  NOT NULL ,
   TARGET_STRUCTURE   SMALLINT                   NOT NULL ,
   CNTL_ALIAS         CHAR(008)                           ,
   PHYS_CHANGE_OWNER  VARCHAR(030)                        , 
   PHYS_CHANGE_TABLE  VARCHAR(128)                        , 
   MAP_ID             VARCHAR(010)               NOT NULL )
in OTHERTS   ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_PRUNCNTLX
ON BACKUP.IBMSNV8_PRUNCNTL (
   SOURCE_OWNER       ASC                                 ,
   SOURCE_TABLE       ASC                                 ,
   SOURCE_VIEW_QUAL   ASC                                 ,
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   TARGET_SERVER      ASC                                 ,
   TARGET_TABLE       ASC                                 ,
   TARGET_OWNER       ASC                                 ) ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_PRUNCNTLX1
ON BACKUP.IBMSNV8_PRUNCNTL (
   MAP_ID             ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_PRUNCNTLX2 
ON BACKUP.IBMSNV8_PRUNCNTL (
   PHYS_CHANGE_OWNER  ASC                                 , 
   PHYS_CHANGE_TABLE  ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_PRUNCNTLX3 
ON BACKUP.IBMSNV8_PRUNCNTL (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   TARGET_SERVER      ASC                                 
 ) ; 

CREATE TABLE BACKUP.IBMSNV8_PRUNE_SET (
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL , 
   SYNCHTIME          TIMESTAMP                           , 
   SYNCHPOINT         CHAR(010)     FOR BIT DATA NOT NULL )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_PRUNE_SETX
ON BACKUP.IBMSNV8_PRUNE_SET ( 
   TARGET_SERVER      ASC                                 ,
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ) ; 
 
CREATE TABLE BACKUP.IBMSNV8_CAPTRACE ( 
   OPERATION          CHAR(008)                  NOT NULL ,
   TRACE_TIME         TIMESTAMP                  NOT NULL ,
   DESCRIPTION        VARCHAR(1024)              NOT NULL )
in OTHERTS  ; 

CREATE INDEX BACKUP.IBMSNAP_CAPTRACEX 
ON BACKUP.IBMSNV8_CAPTRACE ( 
   TRACE_TIME         ASC                                 
) ;
 
CREATE TABLE BACKUP.IBMSNV8_CAPPARMS ( 
   RETENTION_LIMIT    INT                                 ,
   LAG_LIMIT          INT                                 ,
   COMMIT_INTERVAL    INT                                 ,
   PRUNE_INTERVAL     INT                                 ,
   TRACE_LIMIT        INT                                 ,
   MONITOR_LIMIT      INT                                 ,
   MONITOR_INTERVAL   INT                                 , 
   MEMORY_LIMIT       SMALLINT                            , 
   REMOTE_SRC_SERVER  CHAR(018)                           , 
   AUTOPRUNE          CHAR(001)                           , 
   TERM               CHAR(001)                           , 
   AUTOSTOP           CHAR(001)                           , 
   LOGREUSE           CHAR(001)                           , 
   LOGSTDOUT          CHAR(001)                           , 
   SLEEP_INTERVAL     SMALLINT                            , 
   CAPTURE_PATH       VARCHAR(1040)                       ,
   STARTMODE          VARCHAR(010)                        )
in OTHERTS  ; 
 
CREATE TABLE BACKUP.IBMSNV8_UOW (
   IBMSNAP_UOWID      CHAR(010)     FOR BIT DATA NOT NULL ,
   IBMSNAP_COMMITSEQ  CHAR(010)     FOR BIT DATA NOT NULL ,
   IBMSNAP_LOGMARKER  TIMESTAMP                  NOT NULL ,
   IBMSNAP_AUTHTKN    VARCHAR(030)               NOT NULL , 
   IBMSNAP_AUTHID     VARCHAR(030)               NOT NULL , 
   IBMSNAP_REJ_CODE   CHAR(001)                  NOT NULL WITH DEFAULT ,
   IBMSNAP_APPLY_QUAL CHAR(018)                  NOT NULL WITH DEFAULT )
in UOWTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_UOWX 
ON BACKUP.IBMSNV8_UOW (
   IBMSNAP_COMMITSEQ  ASC                                 ,
   IBMSNAP_LOGMARKER  ASC                                 ) ;
 
CREATE TABLE BACKUP.IBMSNV8_CAPENQ ( 
   LOCKNAME           CHAR(009)                           )
in OTHERTS  ;
 
CREATE TABLE BACKUP.IBMSNV8_SIGNAL (
   SIGNAL_TIME        TIMESTAMP                  NOT NULL WITH DEFAULT ,
   SIGNAL_TYPE        VARCHAR(030)               NOT NULL , 
   SIGNAL_SUBTYPE     VARCHAR(030)                        ,
   SIGNAL_INPUT_IN    VARCHAR(500)                        ,
   SIGNAL_STATE       CHAR(001)                  NOT NULL ,
   SIGNAL_LSN         CHAR(010)     FOR BIT DATA          )
in OTHERTS DATA CAPTURE CHANGES ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SIGNALX
ON BACKUP.IBMSNV8_SIGNAL (
   SIGNAL_TIME        ASC                                 
) ;

CREATE TABLE BACKUP.IBMSNV8_CAPMON ( 
   MONITOR_TIME       TIMESTAMP                  NOT NULL ,
   RESTART_TIME       TIMESTAMP                  NOT NULL ,
   CURRENT_MEMORY     INT                        NOT NULL ,
   CD_ROWS_INSERTED   INT                        NOT NULL ,
   RECAP_ROWS_SKIPPED INT                        NOT NULL , 
   TRIGR_ROWS_SKIPPED INT                        NOT NULL ,
   CHG_ROWS_SKIPPED   INT                        NOT NULL ,
   TRANS_PROCESSED    INT                        NOT NULL ,
   TRANS_SPILLED      INT                        NOT NULL , 
   MAX_TRANS_SIZE     INT                        NOT NULL ,
   LOCKING_RETRIES    INT                        NOT NULL ,
   JRN_LIB            CHAR(010)                           , 
   JRN_NAME           CHAR(010)                           ,
   LOGREADLIMIT       INT                        NOT NULL , 
   CAPTURE_IDLE       INT                        NOT NULL , 
   SYNCHTIME          TIMESTAMP                  NOT NULL )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_CAPMONX 
ON BACKUP.IBMSNV8_CAPMON (
   MONITOR_TIME       ASC                                 
) ;

CREATE TABLE BACKUP.IBMSNV8_PRUNE_LOCK (
   DUMMY              CHAR(001)                           )
in OTHERTS  ;

CREATE TABLE BACKUP.IBMSNV8_APPENQ (
   APPLY_QUAL         CHAR(018)                           )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_APPENQX 
ON BACKUP.IBMSNV8_APPENQ (
   APPLY_QUAL         ASC                                 
) ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_SET (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   SET_TYPE           CHAR(001)                  NOT NULL , 
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   ACTIVATE           SMALLINT                   NOT NULL ,
   SOURCE_SERVER      CHAR(018)                  NOT NULL ,
   SOURCE_ALIAS       CHAR(008)                           ,
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   TARGET_ALIAS       CHAR(008)                           ,
   STATUS             SMALLINT                   NOT NULL ,
   LASTRUN            TIMESTAMP                  NOT NULL ,
   REFRESH_TYPE       CHAR(001)                  NOT NULL , 
   SLEEP_MINUTES      INT                                 ,
   EVENT_NAME         CHAR(018)                           ,
   LASTSUCCESS        TIMESTAMP                           ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SYNCHTIME          TIMESTAMP                           ,
   CAPTURE_SCHEMA     VARCHAR(030)               NOT NULL , 
   TGT_CAPTURE_SCHEMA VARCHAR(030)                        , 
   FEDERATED_SRC_SRVR VARCHAR(018)                        , 
   FEDERATED_TGT_SRVR VARCHAR(018)                        , 
   JRN_LIB            CHAR(010)                           ,
   JRN_NAME           CHAR(010)                           ,
   OPTION_FLAGS       CHAR(004)                  NOT NULL , 
   COMMIT_COUNT       SMALLINT                            , 
   MAX_SYNCH_MINUTES  SMALLINT                            , 
   AUX_STMTS          SMALLINT                   NOT NULL ,
   ARCH_LEVEL         CHAR(004)                  NOT NULL )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_SETX
ON BACKUP.IBMSNV8_SUBS_SET (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ) ;

 CREATE TABLE BACKUP.IBMSNV8_SUBS_MEMBR ( 
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   SOURCE_OWNER       VARCHAR(030)               NOT NULL , 
   SOURCE_TABLE       VARCHAR(128)               NOT NULL , 
   SOURCE_VIEW_QUAL   SMALLINT                   NOT NULL ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   TARGET_CONDENSED   CHAR(001)                  NOT NULL ,
   TARGET_COMPLETE    CHAR(001)                  NOT NULL ,
   TARGET_STRUCTURE   SMALLINT                   NOT NULL ,
   PREDICATES         VARCHAR(1024)                       , 
   MEMBER_STATE       CHAR(001)                           , 
   TARGET_KEY_CHG     CHAR(001)                  NOT NULL , 
   UOW_CD_PREDICATES  VARCHAR(1024)                       , 
   JOIN_UOW_CD        CHAR(001)                           , 
   LOADX_TYPE         SMALLINT                            , 
   LOADX_SRC_N_OWNER  VARCHAR(030)                        , 
   LOADX_SRC_N_TABLE  VARCHAR(128)                        )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_MEMBX
ON BACKUP.IBMSNV8_SUBS_MEMBR (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ,
   SOURCE_OWNER       ASC                                 ,
   SOURCE_TABLE       ASC                                 ,
   SOURCE_VIEW_QUAL   ASC                                 ,
   TARGET_OWNER       ASC                                 ,
   TARGET_TABLE       ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_COLS (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   COL_TYPE           CHAR(001)                  NOT NULL ,
   TARGET_NAME        VARCHAR(030)               NOT NULL ,
   IS_KEY             CHAR(001)                  NOT NULL ,
   COLNO              SMALLINT                   NOT NULL , 
   EXPRESSION         VARCHAR(254)               NOT NULL )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_COLSX
ON BACKUP.IBMSNV8_SUBS_COLS (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ,
   TARGET_OWNER       ASC                                 ,
   TARGET_TABLE       ASC                                 ,
   TARGET_NAME        ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_STMTS (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   BEFORE_OR_AFTER    CHAR(001)                  NOT NULL ,
   STMT_NUMBER        SMALLINT                   NOT NULL ,
   EI_OR_CALL         CHAR(001)                  NOT NULL ,
   SQL_STMT           VARCHAR(1024)                       ,
   ACCEPT_SQLSTATES   VARCHAR(050)                        )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_STMTX
ON BACKUP.IBMSNV8_SUBS_STMTS (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ,
   BEFORE_OR_AFTER    ASC                                 ,
   STMT_NUMBER        ASC                                 )
 ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_EVENT (
   EVENT_NAME         CHAR(018)                  NOT NULL ,
   EVENT_TIME         TIMESTAMP                  NOT NULL ,
   END_SYNCHPOINT     CHAR(010)     FOR BIT DATA          , 
   END_OF_PERIOD      TIMESTAMP                           )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_EVENX
ON BACKUP.IBMSNV8_SUBS_EVENT (
   EVENT_NAME         ASC                                 ,
   EVENT_TIME         ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_APPLYTRAIL (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   SET_TYPE           CHAR(001)                  NOT NULL , 
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   ASNLOAD            CHAR(001)                           ,
   FULL_REFRESH       CHAR(001)                           , 
   EFFECTIVE_MEMBERS  INT                                 ,
   SET_INSERTED       INT                        NOT NULL ,
   SET_DELETED        INT                        NOT NULL ,
   SET_UPDATED        INT                        NOT NULL ,
   SET_REWORKED       INT                        NOT NULL ,
   SET_REJECTED_TRXS  INT                        NOT NULL ,
   STATUS             SMALLINT                   NOT NULL ,
   LASTRUN            TIMESTAMP                  NOT NULL ,
   LASTSUCCESS        TIMESTAMP                           ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SYNCHTIME          TIMESTAMP                           ,
   SOURCE_SERVER      CHAR(018)                  NOT NULL ,
   SOURCE_ALIAS       CHAR(008)                           ,
   SOURCE_OWNER       VARCHAR(030)                        , 
   SOURCE_TABLE       VARCHAR(128)                        , 
   SOURCE_VIEW_QUAL   SMALLINT                            ,
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   TARGET_ALIAS       CHAR(008)                           ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   CAPTURE_SCHEMA     VARCHAR(030)               NOT NULL , 
   TGT_CAPTURE_SCHEMA VARCHAR(030)                        , 
   FEDERATED_SRC_SRVR VARCHAR(018)                        , 
   FEDERATED_TGT_SRVR VARCHAR(018)                        , 
   JRN_LIB            CHAR(010)                           , 
   JRN_NAME           CHAR(010)                           ,
   COMMIT_COUNT       SMALLINT                            , 
   OPTION_FLAGS       CHAR(004)                  NOT NULL , 
   EVENT_NAME         CHAR(018)                           , 
   ENDTIME            TIMESTAMP                  NOT NULL WITH DEFAULT , 
   SOURCE_CONN_TIME   TIMESTAMP                           , 
   SQLSTATE           CHAR(005)                           ,
   SQLCODE            INT                                 ,
   SQLERRP            CHAR(008)                           ,
   SQLERRM            VARCHAR(070)                        ,
   APPERRM            VARCHAR(760)                        )
in OTHERTS  ;

CREATE INDEX BACKUP.IBMSNAP_APPLYTRLX
ON BACKUP.IBMSNV8_APPLYTRAIL (
   LASTRUN            DESC                                ,
   APPLY_QUAL         ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_COMPENSATE (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   MEMBER             SMALLINT                   NOT NULL ,
   INTENTSEQ          CHAR(010)     FOR BIT DATA NOT NULL ,
   OPERATION          CHAR(001)                  NOT NULL )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_COMPENSATX
ON BACKUP.IBMSNV8_COMPENSATE (
   APPLY_QUAL         ASC                                 ,
   MEMBER             ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_APPLYTRACE (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   TRACE_TIME         TIMESTAMP                  NOT NULL ,
   OPERATION          CHAR(008)                  NOT NULL ,
   DESCRIPTION        VARCHAR(1024)              NOT NULL )
in OTHERTS  ; 

CREATE INDEX BACKUP.IBMSNAP_APPLYTRACX
ON BACKUP.IBMSNV8_APPLYTRACE (
   APPLY_QUAL                                             , 
   TRACE_TIME         ASC                                 ) ; 

CREATE TABLE BACKUP.IBMSNV8_APPPARMS (
   APPLY_QUAL         CHAR(018)                  NOT NULL , 
   APPLY_PATH         VARCHAR(1040)                       , 
   COPYONCE           CHAR(001)                           , 
   DELAY              INT                                 , 
   ERRWAIT            INT                                 , 
   INAMSG             CHAR(001)                           , 
   LOADXIT            CHAR(001)                           , 
   LOGREUSE           CHAR(001)                           , 
   LOGSTDOUT          CHAR(001)                           , 
   NOTIFY             CHAR(001)                           , 
   OPT4ONE            CHAR(001)                           , 
   SLEEP              CHAR(001)                           , 
   SQLERRCONTINUE     CHAR(001)                           , 
   SPILLFILE          VARCHAR(010)                        , 
   TERM               CHAR(001)                           , 
   TRLREUSE           CHAR(001)                           )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_APPPARMSX 
ON BACKUP.IBMSNV8_APPPARMS (
   APPLY_QUAL         ASC                                 ) ;
 
------------------------------------------------------------------------
-- System-independent backups of key parts of system catalogs:
------------------------------------------------------------------------
 
CREATE TABLE BACKUP.IBMSNAP_MIGRATION (
   KIND          CHAR(7),           
   STATE         INTEGER,           
   WHAT8         CHAR(5),           
   WHAT4C        CHAR(5),           
   WHAT1         CHAR(5),           
   TIME          TIMESTAMP,         
   TABLE_SPACE   VARCHAR(100)       
)
in BACKUPTS ;
 
-- Insert 'CONTROL' row first to begin step 1.

INSERT INTO BACKUP.IBMSNAP_MIGRATION VALUES (
   'CONTROL', 1, '-', '-', '1.51', CURRENT TIMESTAMP,
   'in BACKUPTS'
) ;

--
-- A subset of the COLUMNS system catalog to restore pre-V8 Replication:
--

CREATE TABLE BACKUP.IBMSNAP_COLUMNS (
   tabschema          VARCHAR(30),    
   tabname            VARCHAR(128),
   colname            VARCHAR(128),
   colno              SMALLINT,
   typename           VARCHAR(018),
   length             INTEGER,
   default            VARCHAR(254),
   nulls              CHARACTER(001)
)
in BACKUPTS ;

INSERT INTO BACKUP.IBMSNAP_COLUMNS SELECT
   tabschema,
   tabname,
   COLNAME,
   COLNO,
   TYPENAME,
   LENGTH,
   DEFAULT,
   NULLS
FROM SYSCAT.COLUMNS
WHERE tabschema = 'ASN' OR tabschema = UCASE( 'BACKUP' )
OR CHAR( RTRIM( tabschema ) CONCAT ',' CONCAT TABNAME ) IN (
   SELECT CHAR( RTRIM( CD_OWNER ) CONCAT ',' CONCAT CD_TABLE )
   FROM ASN.IBMSNAP_REGISTER
) ;

--
-- A subset of the TABLES system catalog to restore pre-V8 Replication:
--

CREATE TABLE BACKUP.IBMSNAP_TABLES (
   tabschema          VARCHAR(30),
   tabname            VARCHAR(128),
   cd_alias           VARCHAR(7),
   type               CHARACTER(001),
   colcount           SMALLINT,
   datacapture        CHARACTER(001),
   tbspace            VARCHAR(100),
   implicit           CHARACTER(1)
)
in BACKUPTS ;

-- insert names of ASN.*, backup.* tables,
-- and CD tables (except Federated):

INSERT INTO BACKUP.IBMSNAP_TABLES
SELECT
   T.TABSCHEMA,
   T.TABNAME,
   '',
   T.TYPE,
   T.COLCOUNT,
     DATACAPTURE D,
     T.tbspace,
     '-' I

FROM SYSCAT.TABLES T
 
WHERE T.TABSCHEMA = 'ASN'
OR    T.TABSCHEMA = UCASE( 'BACKUP' )
;

INSERT INTO BACKUP.IBMSNAP_TABLES
SELECT
   T.TABSCHEMA,
   T.TABNAME,
   'B',
   T.TYPE,
   T.COLCOUNT,
     DATACAPTURE D,
     T.tbspace,
     '-' I

FROM SYSCAT.TABLES T
 
WHERE
   CHAR( RTRIM( T.TABSCHEMA ) CONCAT ',' CONCAT T.TABNAME ) IN (
   SELECT CHAR( RTRIM( CD_OWNER ) CONCAT ',' CONCAT CD_TABLE )
   FROM ASN.IBMSNAP_REGISTER
) ;

--
-- Save those view definitions dependent on Replication tables:
--

CREATE TABLE BACKUP.IBMSNAP_VIEWS (
   viewschema         VARCHAR(30),
   viewname           VARCHAR(128),
   tabschema          VARCHAR(30),
   tabname            VARCHAR(128),
   seqno              INTEGER,
   text               VARCHAR(3600)
)
in BACKUPTS ;

INSERT INTO BACKUP.IBMSNAP_VIEWS
SELECT
   VS.VIEWSCHEMA,
   VS.VIEWNAME,
   DP.BSCHEMA,
   DP.BNAME,
   VS.SEQNO,
   VS.TEXT
FROM  SYSCAT.VIEWS AS VS JOIN SYSCAT.VIEWDEP AS DP
ON VS.VIEWSCHEMA = DP.viewschema AND VS.VIEWNAME = DP.viewname
WHERE DP.BSCHEMA = 'ASN'
OR CHAR( RTRIM( DP.BSCHEMA ) CONCAT ',' CONCAT DP.BNAME ) IN (
      SELECT CHAR( RTRIM( CD_OWNER ) CONCAT ',' CONCAT CD_TABLE )
      FROM   ASN.IBMSNAP_REGISTER
   )
;

INSERT INTO BACKUP.IBMSNAP_COLUMNS SELECT
   tabschema,
   tabname,
   COLNAME,
   COLNO,
   TYPENAME,
   LENGTH,
   DEFAULT,
   NULLS
FROM  SYSCAT.COLUMNS
WHERE CHAR( RTRIM( tabschema ) CONCAT ',' CONCAT TABNAME ) IN (
   SELECT CHAR( RTRIM( viewschema ) CONCAT ',' CONCAT viewname )
   FROM   BACKUP.IBMSNAP_VIEWS
) ;

--
-- indexes dependent upon replication tables
--

CREATE TABLE BACKUP.IBMSNAP_INDEXES (
   ischema            VARCHAR(30),
   iname              VARCHAR(128),
   itschema           VARCHAR(30),
   itname             VARCHAR(128),
   colnames           VARCHAR(640),
   iunique            CHARACTER(001),
   icolcount          SMALLINT
)
in BACKUPTS ;
 
CREATE TABLE BACKUP.UDB_INDEXES LIKE SYSCAT.INDEXES
in BACKUPTS ;

INSERT INTO BACKUP.UDB_INDEXES
SELECT *
FROM   SYSCAT.INDEXES
WHERE  TABSCHEMA = 'ASN' OR TABSCHEMA = UCASE( 'BACKUP' )
   OR  CHAR( RTRIM( TABSCHEMA ) CONCAT ',' CONCAT TABNAME )
       IN ( SELECT CHAR( RTRIM( CD_OWNER  ) CONCAT ',' CONCAT CD_TABLE )
       FROM ASN.IBMSNAP_REGISTER ) ;

CREATE TABLE BACKUP.UDB_TABAUTH LIKE SYSCAT.TABAUTH
in BACKUPTS ;

INSERT INTO  BACKUP.UDB_TABAUTH
SELECT *
FROM   SYSCAT.TABAUTH
WHERE  TABSCHEMA = 'ASN'
   OR  CHAR( RTRIM( TABSCHEMA ) CONCAT ',' CONCAT TABNAME )
       IN ( SELECT CHAR( RTRIM( CD_OWNER  ) CONCAT ',' CONCAT CD_TABLE )
       FROM ASN.IBMSNAP_REGISTER ) ;

CREATE TABLE BACKUP.GRANTS( GRANT VARCHAR( 500 ) ) 
in BACKUPTS ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT ALTER      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where ALTERAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT ALTER      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where ALTERAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT DELETE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where DELETEAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT DELETE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where DELETEAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INDEX      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where INDEXAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INDEX      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where INDEXAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INSERT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where INSERTAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INSERT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where INSERTAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT SELECT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where SELECTAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT SELECT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where SELECTAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT REFERENCES ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where REFAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT REFERENCES ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where REFAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT UPDATE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where UPDATEAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT UPDATE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where UPDATEAUTH = 'G' ;
 
CREATE INDEX BACKUP.IBMSNAP_INDEXES_X ON BACKUP.IBMSNAP_INDEXES (
   itschema,
   itname
) ;

INSERT INTO BACKUP.IBMSNAP_INDEXES SELECT
   indschema,
   indname,
   tabschema,
   tabname,
   colnames,
   uniquerule,
   colcount
FROM SYSCAT.INDEXES
WHERE tabschema = 'ASN' OR tabschema = UCASE( 'BACKUP' )
   OR CHAR( RTRIM( tabschema ) CONCAT ',' CONCAT tabname )
      IN ( SELECT CHAR( RTRIM( CD_OWNER  ) CONCAT ',' CONCAT CD_TABLE )
      FROM ASN.IBMSNAP_REGISTER ) ;

CREATE TABLE BACKUP.IBMSNAP_KEYS (
   kschema            VARCHAR(30),
   kname              VARCHAR(128),
   kcolname           VARCHAR(018),
   kcolseq            SMALLINT NOT NULL,
   kordering          CHAR(1)  NOT NULL
)
in BACKUPTS ;

--
-- For connected AS/400's with JRN_LIB and JRN_NAME data, 
-- create IBMSNAP_AS400.
--
-- Notes:
-- 1.  For each subs_set key, choose any one (1) of the corresp. rows in
--     subs_membr to get source_owner, source_table, source_view_qual.
-- 2.  The jrn_lib and jrn_name cols are the same for all elements
--     sharing apply_qual, set_name, whos_on_first.
--
--  
--

CREATE TABLE BACKUP.IBMSNAP_AS400 (
   apply_qual        CHAR(18) NOT NULL,
   set_name          CHAR(18) NOT NULL,
   whos_on_first     CHAR(01) NOT NULL,
   source_owner      VARCHAR(30),
   source_table      VARCHAR(128),
   source_view_qual  SMALLINT,
   source_alias      CHAR(18),
   jrn_lib           CHAR(10),
   jrn_name          CHAR(10)
)
in BACKUPTS ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_AS400_X
ON BACKUP.IBMSNAP_AS400 (
   apply_qual,
   set_name,
   whos_on_first ) ;

INSERT INTO BACKUP.IBMSNAP_AS400
SELECT DISTINCT
   apply_qual,
   set_name,
   whos_on_first,
   nullif('',''),
   nullif('',''),
   -1,
   coalesce( source_alias, source_server ),
   nullif('',''),
   nullif('','')
FROM ASN.IBMSNAP_SUBS_SET ;

UPDATE BACKUP.IBMSNAP_AS400 A
SET            source_owner =
(  SELECT MIN( source_owner )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first
) ;

UPDATE BACKUP.IBMSNAP_AS400 A
SET            source_table =
(  SELECT MIN( source_table )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        source_owner = a.source_owner
) ;

UPDATE BACKUP.IBMSNAP_AS400 A
SET            source_view_qual =
(  SELECT MIN( source_view_qual ) FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        source_owner = a.source_owner  AND
        source_table = a.source_table
) ;

DELETE FROM BACKUP.IBMSNAP_AS400
  WHERE source_owner     is null
     OR source_table     is null
     OR source_view_qual is null
;

-- end IBMSNAP_AS400

--
-- For heterogeneous IBMSNAP_SUBS_SET migration:
--

CREATE TABLE BACKUP.IBMSNAP_SRVR (
   apply_qual         CHAR(18) NOT NULL,
   set_name           CHAR(18) NOT NULL,
   whos_on_first      CHAR(01) NOT NULL,
   source_alias       CHAR(18),
   source_owner       VARCHAR(030),
   source_table       VARCHAR(128),
   federated_src_srvr VARCHAR(18),
   federated_src_type VARCHAR(30),
   target_alias       CHAR(08),
   target_owner       VARCHAR(030),
   target_table       VARCHAR(128),
   federated_tgt_srvr VARCHAR(18),
   federated_tgt_type VARCHAR(30) 
)
in BACKUPTS ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SRVR_X
ON BACKUP.IBMSNAP_SRVR (
   apply_qual,
   set_name,
   whos_on_first ) ;

INSERT INTO BACKUP.IBMSNAP_SRVR
SELECT DISTINCT
   apply_qual,
   set_name,
   whos_on_first,
   coalesce( source_alias, source_server ),
   nullif('',''),
   nullif('',''),
   nullif('',''),
   nullif('',''),
   coalesce( target_alias, target_server ),
   nullif('',''),
   nullif('',''),
   nullif('',''),
   nullif('','')
FROM ASN.IBMSNAP_SUBS_SET ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            source_owner =
(  SELECT MIN( source_owner )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first
) ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            source_table =
(  SELECT MIN( source_table )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        source_owner = a.source_owner
) ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            target_owner =
(  SELECT MIN( target_owner )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first
) ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            target_table =
(  SELECT MIN( target_table )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        target_owner = a.target_owner
) ;

DELETE FROM BACKUP.IBMSNAP_SRVR
   WHERE source_owner is null
      OR source_table is null
      OR target_owner is null
      OR target_table is null
;

-- end IBMSNAP_SRVR
 
--
-- isolated table for serialization only
--

CREATE TABLE BACKUP.IBMSNAP_MUTEX (
   I INTEGER
)
in BACKUPTS ;

-- arbitrary value for serialization only:
INSERT INTO BACKUP.IBMSNAP_MUTEX VALUES ( 0 ) ;
 
-- Insert 'SOURCE' row -- with VERSION -- last to end step 1.

INSERT INTO BACKUP.IBMSNAP_MIGRATION VALUES (
   'SOURCE ', 1, '-', '-', '1.51', CURRENT TIMESTAMP,
'in BACKUPTS'
) ;
 
-- END OF Replication Migration V8 Step 1 --
