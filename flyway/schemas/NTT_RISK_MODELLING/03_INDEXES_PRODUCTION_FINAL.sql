-- =============================================================================
-- 03 - INDEXES FINAL
-- RUN LAST
-- Index creation/alter/drop only, including idempotent PL/SQL wrappers.
-- No business/config DML. No table/schema DDL. No GATHER_TABLE_STATS.
-- =============================================================================

-- ============================================================================
-- FINAL PRODUCTION MIGRATION - AUDITED
-- Source: supplied migration script
-- Behavior:
--   * Existing indexes/tables/columns/constraints are skipped where applicable.
--   * Missing objects are created/added.
--   * Data MERGE/UPDATE/backfill/configuration statements are retained.
--   * ALL table statistics collection calls are intentionally excluded.
--   * Run in DBeaver using Execute SQL Script.
-- ============================================================================

BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_PMC_ACT_EST_MODEL
ON NTT_RISK_MODELLING."PyModelCoefficient"
(
    "activity_code",
    "estimate_val",
    "model_seq"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_PLSP_ACT_STATS_MODEL
ON NTT_RISK_MODELLING."PyLinregStatsPen"
(
    "activity_code",
    "stats_value",
    "model_seq"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_PLSP_ACT_PVALUE_MODEL
ON NTT_RISK_MODELLING."PyLinregStatsPen"
(
    "activity_code",
    "p_value",
    "model_seq"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/

-------------------------------------------------------
-- ini belum deploy ke QA1
BEGIN
    EXECUTE IMMEDIATE q'~DROP INDEX NTT_RISK_MODELLING."IDX_PYWSI_ACT_DEL"~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-1418) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING."IDX_PYWSI_ACT_DEL_PKID"
ON NTT_RISK_MODELLING."PyWeightingScenarioInterpolasi"
(
    "activity_code",
    "is_deleted",
    "pkid"
)
ONLINE~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING."IX_TEA_MappingTable"
    ON NTT_RISK_MODELLING."TableElementAliases" ("mapping_tabel")~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_PCPB_ACT_DEL_PKID
ON NTT_RISK_MODELLING."PyCummulativePdBinomial"
(
    "activity_code",
    "is_deleted",
    "pkid"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped

BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_PTSB_ACT_DEL_PKID
ON NTT_RISK_MODELLING."PyTermStructureBinomial"
(
    "activity_code",
    "is_deleted",
    "pkid"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/



-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped

BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_PI_ACT_DEL_PKID
ON NTT_RISK_MODELLING."PyInterpolasi"
(
    "activity_code",
    "is_deleted",
    "pkid"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped

BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING.IDX_POFB_ACT_DEL_PKID
ON NTT_RISK_MODELLING."PyOdrForecastBinomial"
(
    "activity_code",
    "is_deleted",
    "pkid"
)
TABLESPACE USERS~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING."IDX_PYMDFT_ACT_DEL_SORT"
ON NTT_RISK_MODELLING."PyMeDerivedForecastTransform"
(
    "activity_code",
    "is_deleted",

    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    REPLACE(
                                                        "me_code",
                                                        '12', 'al'
                                                    ),
                                                    '11', 'ak'
                                                ),
                                                '10', 'aj'
                                            ),
                                            '9', 'ai'
                                        ),
                                        '8', 'ah'
                                    ),
                                    '7', 'ag'
                                ),
                                '6', 'af'
                            ),
                            '5', 'ae'
                        ),
                        '4', 'ad'
                    ),
                    '3', 'ac'
                ),
                '2', 'ab'
            ),
            '1', 'aa'
        ),
        '0', 'a0'
    ),

    "me_code",
    "me_periode"
)
TABLESPACE USERS
NOLOGGING
PARALLEL 2~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~ALTER INDEX NTT_RISK_MODELLING."IDX_PYMDFT_ACT_DEL_SORT"
NOPARALLEL
LOGGING~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-1418) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/





BEGIN
    EXECUTE IMMEDIATE q'~CREATE INDEX NTT_RISK_MODELLING."IDX_PYMDFT_ACT_DEL"
ON NTT_RISK_MODELLING."PyMeDerivedForecastTransform"
(
    "activity_code",
    "is_deleted"
)
TABLESPACE USERS
NOLOGGING
PARALLEL 2~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


BEGIN
    EXECUTE IMMEDIATE q'~ALTER INDEX NTT_RISK_MODELLING."IDX_PYMDFT_ACT_DEL"
NOPARALLEL
LOGGING~';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-1418) THEN
            NULL;
        ELSE
            RAISE;
        END IF;
END;
/


-- ============================================================================
-- Mendukung query hotspot BackgoundExecuteBestModelUpdateAsync setelah scope
-- selected model dibatasi ke PyMultLinearRegrResultPen,
-- PyWeightingScenarioInterpolasi, PyFlImpact, dan PyPdPit.
--
-- Script ini memastikan index reset tersedia pada seluruh empat tabel dan
-- melengkapi index pemilihan sequence PyPdPit.
-- Semua blok idempotent: index ekuivalen akan digunakan jika sudah tersedia.
-- ============================================================================


-- Reset PyMultLinearRegrResultPen.
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM (
        SELECT index_name
        FROM all_ind_columns
        WHERE index_owner = 'NTT_RISK_MODELLING'
          AND table_name = 'PyMultLinearRegrResultPen'
        GROUP BY index_name
        HAVING LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position)
               = 'is_deleted,activity_code,is_selected,model_seq'
    );

    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX NTT_RISK_MODELLING."IX_PMLRRP_DEL_ACT_SEL_SEQ" ON NTT_RISK_MODELLING."PyMultLinearRegrResultPen" ("is_deleted", "activity_code", "is_selected", "model_seq")';
        DBMS_OUTPUT.PUT_LINE('OK: IX_PMLRRP_DEL_ACT_SEL_SEQ created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP: equivalent PyMultLinearRegrResultPen reset index already exists');
    END IF;
END;
/


-- Reset PyWeightingScenarioInterpolasi.
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM (
        SELECT index_name
        FROM all_ind_columns
        WHERE index_owner = 'NTT_RISK_MODELLING'
          AND table_name = 'PyWeightingScenarioInterpolasi'
        GROUP BY index_name
        HAVING LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position)
               = 'is_deleted,activity_code,is_selected,model_seq'
    );

    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX NTT_RISK_MODELLING."IX_PWSI_DEL_ACT_SEL_SEQ" ON NTT_RISK_MODELLING."PyWeightingScenarioInterpolasi" ("is_deleted", "activity_code", "is_selected", "model_seq")';
        DBMS_OUTPUT.PUT_LINE('OK: IX_PWSI_DEL_ACT_SEL_SEQ created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP: equivalent PyWeightingScenarioInterpolasi reset index already exists');
    END IF;
END;
/


-- Reset PyFlImpact.
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM (
        SELECT index_name
        FROM all_ind_columns
        WHERE index_owner = 'NTT_RISK_MODELLING'
          AND table_name = 'PyFlImpact'
        GROUP BY index_name
        HAVING LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position)
               = 'is_deleted,activity_code,is_selected,model_seq'
    );

    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX NTT_RISK_MODELLING."IX_PFI_DEL_ACT_SEL_SEQ" ON NTT_RISK_MODELLING."PyFlImpact" ("is_deleted", "activity_code", "is_selected", "model_seq")';
        DBMS_OUTPUT.PUT_LINE('OK: IX_PFI_DEL_ACT_SEL_SEQ created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP: equivalent PyFlImpact reset index already exists');
    END IF;
END;
/


-- Reset PyPdPit:
-- WHERE is_deleted = 0 AND activity_code IN (...) AND is_selected = 1
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM (
        SELECT index_name
        FROM all_ind_columns
        WHERE index_owner = 'NTT_RISK_MODELLING'
          AND table_name = 'PyPdPit'
        GROUP BY index_name
        HAVING LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position)
               = 'is_deleted,activity_code,is_selected,model_sequence'
    );

    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX NTT_RISK_MODELLING."IX_PPDP_DEL_ACT_SEL_SEQ" ON NTT_RISK_MODELLING."PyPdPit" ("is_deleted", "activity_code", "is_selected", "model_sequence")';
        DBMS_OUTPUT.PUT_LINE('OK: IX_PPDP_DEL_ACT_SEL_SEQ created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP: equivalent PyPdPit reset index already exists');
    END IF;
END;
/


-- Memilih sequence PyPdPit:
-- WHERE is_deleted = 0 AND activity_code IN (...) AND model_sequence = :seq
DECLARE
    v_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM (
        SELECT index_name
        FROM all_ind_columns
        WHERE index_owner = 'NTT_RISK_MODELLING'
          AND table_name = 'PyPdPit'
        GROUP BY index_name
        HAVING LISTAGG(column_name, ',') WITHIN GROUP (ORDER BY column_position)
               = 'is_deleted,activity_code,model_sequence'
    );

    IF v_cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX NTT_RISK_MODELLING."IX_PPDP_DEL_ACT_SEQ" ON NTT_RISK_MODELLING."PyPdPit" ("is_deleted", "activity_code", "model_sequence")';
        DBMS_OUTPUT.PUT_LINE('OK: IX_PPDP_DEL_ACT_SEQ created');
    ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP: equivalent PyPdPit selection index already exists');
    END IF;
END;
/


-- Supports TableMappings.default_order_by for:
--   PyWeightingScenarioInterpolasi|fl_pd_calculation -> bucket
--   PyWeightingScenarioInterpolasi|CPD / MPD          -> year, month, bucket
--   PyNormInverse                                     -> bucket_from, bucket_to
--
-- activity_code and is_deleted lead each index because the dynamic table queries
-- normally filter by activity and the EF model applies the is_deleted filter.

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ALL_INDEXES
     WHERE owner = 'NTT_RISK_MODELLING'
       AND index_name = 'IDX_PYWSI_ACT_DEL_BUCKET';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX NTT_RISK_MODELLING."IDX_PYWSI_ACT_DEL_BUCKET"
                ON NTT_RISK_MODELLING."PyWeightingScenarioInterpolasi"
                   ("activity_code", "is_deleted", "bucket")';
    END IF;
END;
/



DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ALL_INDEXES
     WHERE owner = 'NTT_RISK_MODELLING'
       AND index_name = 'IDX_PYWSI_ACT_DEL_YMB';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX NTT_RISK_MODELLING."IDX_PYWSI_ACT_DEL_YMB"
                ON NTT_RISK_MODELLING."PyWeightingScenarioInterpolasi"
                   ("activity_code", "is_deleted", "year", "month", "bucket")';
    END IF;
END;
/



DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ALL_INDEXES
     WHERE owner = 'NTT_RISK_MODELLING'
       AND index_name = 'IDX_PYNI_ACT_DEL_BUCKET';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX NTT_RISK_MODELLING."IDX_PYNI_ACT_DEL_BUCKET"
                ON NTT_RISK_MODELLING."PyNormInverse"
                   ("activity_code", "is_deleted", "bucket_from", "bucket_to")';
    END IF;
END;
/



-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped


-- Indexes for the Model Manager list query on Oracle.
-- Run as NTT_RISK_MODELLING or as a user with CREATE INDEX privilege.

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM ALL_INDEXES
     WHERE owner = 'NTT_RISK_MODELLING'
       AND index_name = 'IDX_FLM_MODEL_READY_LIST';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX NTT_RISK_MODELLING."IDX_FLM_MODEL_READY_LIST"
                ON NTT_RISK_MODELLING."ForwardLookingModel"
                   ("is_deleted", "code_app", "is_model", "is_active",
                    "train_status", "workflow_step_draft_pkid", "run_id")';
    END IF;
END;
/



DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM ALL_INDEXES
     WHERE owner = 'NTT_RISK_MODELLING'
       AND index_name = 'IDX_AES_STEP_RUN_DEL_ACT';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX NTT_RISK_MODELLING."IDX_AES_STEP_RUN_DEL_ACT"
                ON NTT_RISK_MODELLING."ApplicationEngineServices"
                   ("workflow_step_draft_pkid", "run_type", "is_deleted", "activity_code")';
    END IF;
END;
/



DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM ALL_INDEXES
     WHERE owner = 'NTT_RISK_MODELLING'
       AND index_name = 'IDX_PMLRRP_DEL_SORT_ACT';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX NTT_RISK_MODELLING."IDX_PMLRRP_DEL_SORT_ACT"
                ON NTT_RISK_MODELLING."PyMultLinearRegrResultPen"
                   ("is_deleted",
                    NVL("updated_date", "created_date") DESC,
                    NVL("adj_r_squared", 0) DESC,
                    "activity_code")';
    END IF;
END;
/
