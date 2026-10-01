-- =============================================================================
-- 02 - DATA CONFIG BACKFILL FINAL
-- RUN SECOND
-- Business/config/backfill DML: MERGE / INSERT / UPDATE / configuration.
-- Includes FieldMappings, TableMappings, lookup data, best_model/MAPE_TIER, etc.
-- No table/schema DDL. No index DDL. No GATHER_TABLE_STATS.
-- =============================================================================


-- Tuned backfill:
--   1. Materialize active target keys once.
--   2. Read source rows only for keys that exist in the target.
--   3. Update PyMultLinearRegrResultPen once with a single MERGE.
--   4. Preserve an existing column group when its source rows do not exist.

MERGE INTO NTT_RISK_MODELLING."PyMultLinearRegrResultPen" target
USING (
    WITH
    target_keys AS (
        SELECT /*+ MATERIALIZE */
               DISTINCT p."activity_code", p."model_seq"
        FROM NTT_RISK_MODELLING."PyMultLinearRegrResultPen" p
        WHERE p."is_deleted" = 0
    ),
    coefficient_ranked AS (
        SELECT /*+ USE_NL(pmc) */
               pmc."activity_code",
               pmc."model_seq",
               pmc."coeff_name",
               pmc."estimate_val",
               ROW_NUMBER() OVER (
                   PARTITION BY pmc."activity_code", pmc."model_seq"
                   ORDER BY pmc."pkid"
               ) AS coefficient_seq
        FROM target_keys keys
        INNER JOIN NTT_RISK_MODELLING."PyModelCoefficient" pmc
            ON pmc."activity_code" = keys."activity_code"
           AND pmc."model_seq" = keys."model_seq"
           AND pmc."is_deleted" = 0
        WHERE pmc."coeff_name" IS NOT NULL
          AND UPPER(TRIM(pmc."coeff_name")) <> 'CONST'
    ),
    coefficient_pivot AS (
        SELECT
            coefficient."activity_code",
            coefficient."model_seq",
            1 AS has_coefficient,
            MAX(CASE WHEN coefficient.coefficient_seq = 1
                     THEN coefficient."coeff_name" END) AS coefficient_variable_name_1,
            MAX(CASE WHEN coefficient.coefficient_seq = 1
                     THEN coefficient."estimate_val" END) AS coefficient_variable_1,
            MAX(CASE WHEN coefficient.coefficient_seq = 2
                     THEN coefficient."coeff_name" END) AS coefficient_variable_name_2,
            MAX(CASE WHEN coefficient.coefficient_seq = 2
                     THEN coefficient."estimate_val" END) AS coefficient_variable_2,
            MAX(CASE WHEN coefficient.coefficient_seq = 3
                     THEN coefficient."coeff_name" END) AS coefficient_variable_name_3,
            MAX(CASE WHEN coefficient.coefficient_seq = 3
                     THEN coefficient."estimate_val" END) AS coefficient_variable_3
        FROM coefficient_ranked coefficient
        WHERE coefficient.coefficient_seq <= 3
        GROUP BY coefficient."activity_code", coefficient."model_seq"
    ),
    ols_pivot AS (
        SELECT /*+ USE_NL(plsp ora) */
            plsp."activity_code",
            plsp."model_seq",
            1 AS has_ols,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'KOLMOGOROV SMIRNOV'
                    THEN plsp."p_value"
                END) AS kolmogorov_smirnov,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'LAGRANGE MULTIPLIER'
                    THEN plsp."p_value"
                END) AS lagrange_multiplier,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'VARIANCE INFLATION FACTOR'
                    THEN plsp."stats_value"
                END) AS variance_inflation_factor,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'ANDERSON DARLING'
                    THEN plsp."p_value"
                END) AS anderson_darling,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) IN ('BREUSCH-PAGAN', 'BREUSCH PAGAN')
                    THEN plsp."p_value"
                END) AS breusch_pagan,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'DURBIN WATSON'
                    THEN plsp."stats_value"
                END) AS durbin_watson,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'SHAPIRO WILK'
                    THEN plsp."p_value"
                END) AS shapiro_wilk
        FROM target_keys keys
        INNER JOIN NTT_RISK_MODELLING."PyLinregStatsPen" plsp
            ON plsp."activity_code" = keys."activity_code"
           AND plsp."model_seq" = keys."model_seq"
        INNER JOIN NTT_RISK_MODELLING."OlsRegressionAssumptions" ora
            ON ora."activity_code" = plsp."activity_code"
           AND ora."method" = plsp."test_name"
           AND ora."type" = plsp."test_descr"
        WHERE UPPER(TRIM(ora."method")) IN (
            'KOLMOGOROV SMIRNOV',
            'LAGRANGE MULTIPLIER',
            'VARIANCE INFLATION FACTOR',
            'ANDERSON DARLING',
            'BREUSCH-PAGAN',
            'BREUSCH PAGAN',
            'DURBIN WATSON',
            'SHAPIRO WILK'
        )
        GROUP BY plsp."activity_code", plsp."model_seq"
    )
    SELECT
        keys."activity_code",
        keys."model_seq",
        coefficient.has_coefficient,
        coefficient.coefficient_variable_name_1,
        coefficient.coefficient_variable_1,
        coefficient.coefficient_variable_name_2,
        coefficient.coefficient_variable_2,
        coefficient.coefficient_variable_name_3,
        coefficient.coefficient_variable_3,
        ols.has_ols,
        ols.kolmogorov_smirnov,
        ols.lagrange_multiplier,
        ols.variance_inflation_factor,
        ols.anderson_darling,
        ols.breusch_pagan,
        ols.durbin_watson,
        ols.shapiro_wilk
    FROM target_keys keys
    LEFT JOIN coefficient_pivot coefficient
        ON coefficient."activity_code" = keys."activity_code"
       AND coefficient."model_seq" = keys."model_seq"
    LEFT JOIN ols_pivot ols
        ON ols."activity_code" = keys."activity_code"
       AND ols."model_seq" = keys."model_seq"
    WHERE coefficient.has_coefficient = 1
       OR ols.has_ols = 1
) source
ON (
    target."activity_code" = source."activity_code"
    AND target."model_seq" = source."model_seq"
    AND target."is_deleted" = 0
)
WHEN MATCHED THEN UPDATE SET
    target."coefficient_variable_name_1" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_name_1
             ELSE target."coefficient_variable_name_1" END,
    target."coefficient_variable_1" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_1
             ELSE target."coefficient_variable_1" END,
    target."coefficient_variable_name_2" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_name_2
             ELSE target."coefficient_variable_name_2" END,
    target."coefficient_variable_2" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_2
             ELSE target."coefficient_variable_2" END,
    target."coefficient_variable_name_3" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_name_3
             ELSE target."coefficient_variable_name_3" END,
    target."coefficient_variable_3" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_3
             ELSE target."coefficient_variable_3" END,
    target."kolmogorov_smirnov" =
        CASE WHEN source.has_ols = 1
             THEN source.kolmogorov_smirnov
             ELSE target."kolmogorov_smirnov" END,
    target."lagrange_multiplier" =
        CASE WHEN source.has_ols = 1
             THEN source.lagrange_multiplier
             ELSE target."lagrange_multiplier" END,
    target."variance_inflation_factor" =
        CASE WHEN source.has_ols = 1
             THEN source.variance_inflation_factor
             ELSE target."variance_inflation_factor" END,
    target."anderson_darling" =
        CASE WHEN source.has_ols = 1
             THEN source.anderson_darling
             ELSE target."anderson_darling" END,
    target."breusch_pagan" =
        CASE WHEN source.has_ols = 1
             THEN source.breusch_pagan
             ELSE target."breusch_pagan" END,
    target."durbin_watson" =
        CASE WHEN source.has_ols = 1
             THEN source.durbin_watson
             ELSE target."durbin_watson" END,
    target."shapiro_wilk" =
        CASE WHEN source.has_ols = 1
             THEN source.shapiro_wilk
             ELSE target."shapiro_wilk" END;


COMMIT;



-- Synchronize FieldMappings for PyMultLinearRegrResultPen.
-- The final sequence follows the history/export display order:
-- model identity -> coefficients -> model metrics -> OLS tests -> statistics.
--
-- Idempotent:
--   * existing mappings are reactivated and their alias/sequence is updated;
--   * missing mappings are inserted.

LOCK TABLE NTT_RISK_MODELLING."FieldMappings"
    IN SHARE ROW EXCLUSIVE MODE;


MERGE INTO NTT_RISK_MODELLING."FieldMappings" target
USING (
    WITH mapping_values (field_name, field_alias, seq) AS (
        SELECT 'model_seq',                    'Model Seq',                     1 FROM DUAL UNION ALL
        SELECT 'model_formula',                'Model Formula',                 2 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_1',  'Coefficient Variable Name 1',  3 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_1',       'Coefficient Variable 1',       4 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_2',  'Coefficient Variable Name 2',  5 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_2',       'Coefficient Variable 2',       6 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_3',  'Coefficient Variable Name 3',  7 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_3',       'Coefficient Variable 3',       8 FROM DUAL UNION ALL
        SELECT 'adj_r_squared',                'Adj R Squared',                 9 FROM DUAL UNION ALL
        SELECT 'r_squared',                    'R Squared',                    10 FROM DUAL UNION ALL
        SELECT 'p_value',                      'P Value',                      11 FROM DUAL UNION ALL
        SELECT 'pdrate_mape',                  'InSample Mape',                12 FROM DUAL UNION ALL
        SELECT 'avg_pdrate_mape',              'OutSample Mape',               13 FROM DUAL UNION ALL
        SELECT 'best_model',                   'Best Model',                   14 FROM DUAL UNION ALL
        SELECT 'status',                       'OLS Status',                   15 FROM DUAL UNION ALL
        SELECT 'kolmogorov_smirnov',           'Kolmogorov Smirnov',           16 FROM DUAL UNION ALL
        SELECT 'lagrange_multiplier',          'Lagrange Multiplier',          17 FROM DUAL UNION ALL
        SELECT 'variance_inflation_factor',    'Variance Inflation Factor',    18 FROM DUAL UNION ALL
        SELECT 'anderson_darling',             'Anderson Darling',             19 FROM DUAL UNION ALL
        SELECT 'breusch_pagan',                'Breusch-Pagan',                20 FROM DUAL UNION ALL
        SELECT 'durbin_watson',                'Durbin Watson',                21 FROM DUAL UNION ALL
        SELECT 'shapiro_wilk',                 'Shapiro Wilk',                 22 FROM DUAL UNION ALL
        SELECT 'f_statistic',                  'F Statistic',                  23 FROM DUAL UNION ALL
        SELECT 'df_regr',                      'Df Regr',                      24 FROM DUAL UNION ALL
        SELECT 'df_resd',                      'Df Resd',                      25 FROM DUAL UNION ALL
        SELECT 'df_total',                     'Df Total',                     26 FROM DUAL UNION ALL
        SELECT 'ols_pass_count',               'Ols Pass Count',               27 FROM DUAL UNION ALL
        SELECT 'aic',                          'Aic',                          28 FROM DUAL UNION ALL
        SELECT 'bic',                          'Bic',                          29 FROM DUAL UNION ALL
        SELECT 'sic',                          'Sic',                          30 FROM DUAL UNION ALL
        SELECT 'mult_r_squared',               'Mult R Squared',               31 FROM DUAL
    ),
    current_max AS (
        SELECT NVL(MAX("pkid"), 0) AS max_pkid
        FROM NTT_RISK_MODELLING."FieldMappings"
    )
    SELECT current_max.max_pkid
               + ROW_NUMBER() OVER (ORDER BY mapping_values.seq) AS new_pkid,
           mapping_values.field_name,
           mapping_values.field_alias,
           mapping_values.seq
    FROM mapping_values
    CROSS JOIN current_max
) source
ON (
    target."mapping_tabel" = 'PyMultLinearRegrResultPen'
    AND target."field_name" = source.field_name
    AND target."output_group" IS NULL
)
WHEN MATCHED THEN UPDATE SET
    target."field_alias"  = source.field_alias,
    target."seq"          = source.seq,
    target."is_active"    = 1,
    target."is_deleted"   = 0,
    target."updated_by"   = 'svc_app_user',
    target."updated_date" = SYSTIMESTAMP,
    target."updated_host" = 'app-server-1',
    target."deleted_by"   = NULL,
    target."deleted_date" = NULL,
    target."deleted_host" = NULL
WHEN NOT MATCHED THEN INSERT (
    "pkid",
    "field_name",
    "field_alias",
    "is_active",
    "created_by",
    "created_date",
    "created_host",
    "is_deleted",
    "mapping_tabel",
    "seq",
    "output_group"
)
VALUES (
    source.new_pkid,
    source.field_name,
    source.field_alias,
    1,
    'svc_app_user',
    SYSTIMESTAMP,
    'app-server-1',
    0,
    'PyMultLinearRegrResultPen',
    source.seq,
    NULL
);


COMMIT;


MERGE INTO NTT_RISK_MODELLING."PyFlImpact" target
USING (
    SELECT
        source_data.fl_activity_code,
        source_data."model_seq",

        source_data."coefficient_variable_name_1",
        source_data."coefficient_variable_1",
        source_data."coefficient_variable_name_2",
        source_data."coefficient_variable_2",
        source_data."coefficient_variable_name_3",
        source_data."coefficient_variable_3",

        source_data."kolmogorov_smirnov",
        source_data."lagrange_multiplier",
        source_data."variance_inflation_factor",
        source_data."anderson_darling",
        source_data."breusch_pagan",
        source_data."durbin_watson",
        source_data."shapiro_wilk",

        source_data."r_squared",
        source_data."p_value",
        source_data."f_statistic",
        source_data."df_regr",
        source_data."df_resd",
        source_data."df_total",
        source_data."ols_pass_count",
        source_data."aic",
        source_data."bic",
        source_data."sic",
        source_data."mult_r_squared"

    FROM (
        SELECT
            pfi."activity_code" AS fl_activity_code,
            pfi."model_seq",

            regression."coefficient_variable_name_1",
            regression."coefficient_variable_1",
            regression."coefficient_variable_name_2",
            regression."coefficient_variable_2",
            regression."coefficient_variable_name_3",
            regression."coefficient_variable_3",

            regression."kolmogorov_smirnov",
            regression."lagrange_multiplier",
            regression."variance_inflation_factor",
            regression."anderson_darling",
            regression."breusch_pagan",
            regression."durbin_watson",
            regression."shapiro_wilk",

            regression."r_squared",
            regression."p_value",
            regression."f_statistic",
            regression."df_regr",
            regression."df_resd",
            regression."df_total",
            regression."ols_pass_count",
            regression."aic",
            regression."bic",
            regression."sic",
            regression."mult_r_squared",

            ROW_NUMBER() OVER (
                PARTITION BY
                    pfi."activity_code",
                    pfi."model_seq"
                ORDER BY
                    mapping."pkid",
                    regression."pkid" DESC
            ) AS row_seq

        FROM (
            SELECT DISTINCT
                impact."activity_code",
                impact."model_seq"
            FROM NTT_RISK_MODELLING."PyFlImpact" impact
            WHERE impact."is_deleted" = 0
              AND impact."activity_code" IS NOT NULL
              AND impact."model_seq" IS NOT NULL
        ) pfi

        INNER JOIN NTT_RISK_MODELLING."ModellingForwardMapping" mapping
            ON pfi."activity_code" LIKE mapping."fp_run_type" || '%'
           AND mapping."is_active" = 1
           AND mapping."is_deleted" = 0
           AND mapping."fp_run_type" IS NOT NULL
           AND mapping."mp_activity_code" IS NOT NULL

        INNER JOIN NTT_RISK_MODELLING."PyMultLinearRegrResultPen" regression
            ON regression."activity_code" = mapping."mp_activity_code"
           AND regression."model_seq" = pfi."model_seq"
           AND regression."is_deleted" = 0
    ) source_data
    WHERE source_data.row_seq = 1
) source
ON (
    target."activity_code" = source.fl_activity_code
    AND target."model_seq" = source."model_seq"
    AND target."is_deleted" = 0
)
WHEN MATCHED THEN UPDATE SET
    target."coefficient_variable_name_1" =
        source."coefficient_variable_name_1",

    target."coefficient_variable_1" =
        source."coefficient_variable_1",

    target."coefficient_variable_name_2" =
        source."coefficient_variable_name_2",

    target."coefficient_variable_2" =
        source."coefficient_variable_2",

    target."coefficient_variable_name_3" =
        source."coefficient_variable_name_3",

    target."coefficient_variable_3" =
        source."coefficient_variable_3",

    target."kolmogorov_smirnov" =
        source."kolmogorov_smirnov",

    target."lagrange_multiplier" =
        source."lagrange_multiplier",

    target."variance_inflation_factor" =
        source."variance_inflation_factor",

    target."anderson_darling" =
        source."anderson_darling",

    target."breusch_pagan" =
        source."breusch_pagan",

    target."durbin_watson" =
        source."durbin_watson",

    target."shapiro_wilk" =
        source."shapiro_wilk",

    target."r_squared" =
        source."r_squared",

    target."p_value" =
        source."p_value",

    target."f_statistic" =
        source."f_statistic",

    target."df_regr" =
        source."df_regr",

    target."df_resd" =
        source."df_resd",

    target."df_total" =
        source."df_total",

    target."ols_pass_count" =
        source."ols_pass_count",

    target."aic" =
        source."aic",

    target."bic" =
        source."bic",

    target."sic" =
        source."sic",

    target."mult_r_squared" =
        source."mult_r_squared",

    target."updated_date" = SYSDATE;


COMMIT;



-- Synchronize FieldMappings for PyFlImpact.
-- Existing forward-looking fields are preserved and regression fields follow
-- the display order used by PyMultLinearRegrResultPen.
--
-- Idempotent:
--   * existing mappings are reactivated and their alias/sequence is updated;
--   * missing mappings are inserted.

LOCK TABLE NTT_RISK_MODELLING."FieldMappings"
    IN SHARE ROW EXCLUSIVE MODE;


MERGE INTO NTT_RISK_MODELLING."FieldMappings" target
USING (
    WITH mapping_values (field_name, field_alias, seq) AS (
        SELECT 'period',                       'Periode',                       1 FROM DUAL UNION ALL
        SELECT 'model_seq',                    'Model Seq',                     2 FROM DUAL UNION ALL
        SELECT 'fl_impact',                    'Fl Impact',                     3 FROM DUAL UNION ALL
        SELECT 'model_formula',                'Model Formula',                 4 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_1',  'Coefficient Variable Name 1',  5 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_1',       'Coefficient Variable 1',       6 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_2',  'Coefficient Variable Name 2',  7 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_2',       'Coefficient Variable 2',       8 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_3',  'Coefficient Variable Name 3',  9 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_3',       'Coefficient Variable 3',      10 FROM DUAL UNION ALL
        SELECT 'adj_r_squared',                'Adj R Squared',                11 FROM DUAL UNION ALL
        SELECT 'r_squared',                    'R Squared',                    12 FROM DUAL UNION ALL
        SELECT 'p_value',                      'P Value',                      13 FROM DUAL UNION ALL
        SELECT 'insample_mape',                'InSample Mape',                14 FROM DUAL UNION ALL
        SELECT 'outsample_mape',               'OutSample Mape',               15 FROM DUAL UNION ALL
        SELECT 'best_model',                   'Best Model',                   16 FROM DUAL UNION ALL
        SELECT 'is_selected',                  'Selected Model',               17 FROM DUAL UNION ALL
        SELECT 'status',                       'OLS Status',                   18 FROM DUAL UNION ALL
        SELECT 'year',                         'FL Impact Year {0} (%)',       19 FROM DUAL UNION ALL
        SELECT 'transform_odr_type',           'Transform Odr Type',           20 FROM DUAL UNION ALL
        SELECT 'kolmogorov_smirnov',           'Kolmogorov Smirnov',           21 FROM DUAL UNION ALL
        SELECT 'lagrange_multiplier',          'Lagrange Multiplier',          22 FROM DUAL UNION ALL
        SELECT 'variance_inflation_factor',    'Variance Inflation Factor',    23 FROM DUAL UNION ALL
        SELECT 'anderson_darling',             'Anderson Darling',             24 FROM DUAL UNION ALL
        SELECT 'breusch_pagan',                'Breusch-Pagan',                25 FROM DUAL UNION ALL
        SELECT 'durbin_watson',                'Durbin Watson',                26 FROM DUAL UNION ALL
        SELECT 'shapiro_wilk',                 'Shapiro Wilk',                 27 FROM DUAL UNION ALL
        SELECT 'f_statistic',                  'F Statistic',                  28 FROM DUAL UNION ALL
        SELECT 'df_regr',                      'Df Regr',                      29 FROM DUAL UNION ALL
        SELECT 'df_resd',                      'Df Resd',                      30 FROM DUAL UNION ALL
        SELECT 'df_total',                     'Df Total',                     31 FROM DUAL UNION ALL
        SELECT 'ols_pass_count',               'Ols Pass Count',               32 FROM DUAL UNION ALL
        SELECT 'aic',                          'Aic',                          33 FROM DUAL UNION ALL
        SELECT 'bic',                          'Bic',                          34 FROM DUAL UNION ALL
        SELECT 'sic',                          'Sic',                          35 FROM DUAL UNION ALL
        SELECT 'mult_r_squared',               'Mult R Squared',               36 FROM DUAL
    ),
    current_max AS (
        SELECT NVL(MAX("pkid"), 0) AS max_pkid
        FROM NTT_RISK_MODELLING."FieldMappings"
    )
    SELECT current_max.max_pkid
               + ROW_NUMBER() OVER (ORDER BY mapping_values.seq) AS new_pkid,
           mapping_values.field_name,
           mapping_values.field_alias,
           mapping_values.seq
    FROM mapping_values
    CROSS JOIN current_max
) source
ON (
    target."mapping_tabel" = 'PyFlImpact'
    AND target."field_name" = source.field_name
    AND target."output_group" IS NULL
)
WHEN MATCHED THEN UPDATE SET
    target."field_alias"  = source.field_alias,
    target."seq"          = source.seq,
    target."is_active"    = 1,
    target."is_deleted"   = 0,
    target."updated_by"   = 'svc_app_user',
    target."updated_date" = SYSTIMESTAMP,
    target."updated_host" = 'app-server-1',
    target."deleted_by"   = NULL,
    target."deleted_date" = NULL,
    target."deleted_host" = NULL
WHEN NOT MATCHED THEN INSERT (
    "pkid",
    "field_name",
    "field_alias",
    "is_active",
    "created_by",
    "created_date",
    "created_host",
    "is_deleted",
    "mapping_tabel",
    "seq",
    "output_group"
)
VALUES (
    source.new_pkid,
    source.field_name,
    source.field_alias,
    1,
    'svc_app_user',
    SYSTIMESTAMP,
    'app-server-1',
    0,
    'PyFlImpact',
    source.seq,
    NULL
);


-- Keep the pivot metadata aligned with the fields exposed above.
-- year remains the pivot column and fl_impact remains the aggregated value.
UPDATE NTT_RISK_MODELLING."TableMappings"
SET "pivot_row_fields" =
        'model_seq,model_formula,'
        || 'coefficient_variable_name_1,coefficient_variable_1,'
        || 'coefficient_variable_name_2,coefficient_variable_2,'
        || 'coefficient_variable_name_3,coefficient_variable_3,'
        || 'adj_r_squared,r_squared,p_value,'
        || 'insample_mape,outsample_mape,best_model,is_selected,status,'
        || 'transform_odr_type,kolmogorov_smirnov,lagrange_multiplier,'
        || 'variance_inflation_factor,anderson_darling,breusch_pagan,'
        || 'durbin_watson,shapiro_wilk,f_statistic,df_regr,df_resd,df_total,'
        || 'ols_pass_count,aic,bic,sic,mult_r_squared',
    "pivot_column_field" = 'year',
    "pivot_value_field" = 'fl_impact',
    "pivot_agg_function" = 'SUM',
    "is_pivot_enabled" = 1,
    "is_active" = 1,
    "is_deleted" = 0,
    "updated_by" = 'svc_app_user',
    "updated_date" = SYSTIMESTAMP,
    "updated_host" = 'app-server-1',
    "deleted_by" = NULL,
    "deleted_date" = NULL,
    "deleted_host" = NULL
WHERE "schema_name" = 'NTT_RISK_MODELLING'
  AND "table_name" = 'PyFlImpact';


COMMIT;



-- Synchronize FieldMappings for PyMultLinearRegrResultPen.
-- The final sequence follows the history/export display order:
-- model identity -> intercept -> coefficients -> model metrics -> OLS tests -> statistics.
--
-- Idempotent:
--   * existing mappings are reactivated and their alias/sequence is updated;
--   * missing mappings are inserted.

LOCK TABLE NTT_RISK_MODELLING."FieldMappings"
    IN SHARE ROW EXCLUSIVE MODE;


MERGE INTO NTT_RISK_MODELLING."FieldMappings" target
USING (
    WITH mapping_values (field_name, field_alias, seq) AS (
        SELECT 'model_seq',                    'Model Seq',                     1 FROM DUAL UNION ALL
        SELECT 'model_formula',                'Model Formula',                 2 FROM DUAL UNION ALL
        SELECT 'intercept_name',               'Intercept Name',                3 FROM DUAL UNION ALL
        SELECT 'intercept',                    'Intercept',                     4 FROM DUAL UNION ALL
        SELECT 'p_value_intercept',            'P Value Intercept',             5 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_1',  'Coefficient Variable Name 1',  6 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_1',       'Coefficient Variable 1',       7 FROM DUAL UNION ALL
        SELECT 'p_value_variable_1',           'P Value Variable 1',           8 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_2',  'Coefficient Variable Name 2',  9 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_2',       'Coefficient Variable 2',      10 FROM DUAL UNION ALL
        SELECT 'p_value_variable_2',           'P Value Variable 2',          11 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_3',  'Coefficient Variable Name 3', 12 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_3',       'Coefficient Variable 3',      13 FROM DUAL UNION ALL
        SELECT 'p_value_variable_3',           'P Value Variable 3',          14 FROM DUAL UNION ALL
        SELECT 'adj_r_squared',                'Adj R Squared',                15 FROM DUAL UNION ALL
        SELECT 'r_squared',                    'R Squared',                    16 FROM DUAL UNION ALL
        SELECT 'p_value',                      'P Value',                      17 FROM DUAL UNION ALL
        SELECT 'pdrate_mape',                  'InSample Mape',                18 FROM DUAL UNION ALL
        SELECT 'avg_pdrate_mape',              'OutSample Mape',               19 FROM DUAL UNION ALL
        SELECT 'best_model',                   'Best Model',                   20 FROM DUAL UNION ALL
        SELECT 'status',                       'OLS Status',                   21 FROM DUAL UNION ALL
        SELECT 'kolmogorov_smirnov',           'Kolmogorov Smirnov',           22 FROM DUAL UNION ALL
        SELECT 'lagrange_multiplier',          'Lagrange Multiplier',          23 FROM DUAL UNION ALL
        SELECT 'variance_inflation_factor',    'Variance Inflation Factor',    24 FROM DUAL UNION ALL
        SELECT 'anderson_darling',             'Anderson Darling',             25 FROM DUAL UNION ALL
        SELECT 'breusch_pagan',                'Breusch-Pagan',                26 FROM DUAL UNION ALL
        SELECT 'durbin_watson',                'Durbin Watson',                27 FROM DUAL UNION ALL
        SELECT 'shapiro_wilk',                 'Shapiro Wilk',                 28 FROM DUAL UNION ALL
        SELECT 'f_statistic',                  'F Statistic',                  29 FROM DUAL UNION ALL
        SELECT 'df_regr',                      'Df Regr',                      30 FROM DUAL UNION ALL
        SELECT 'df_resd',                      'Df Resd',                      31 FROM DUAL UNION ALL
        SELECT 'df_total',                     'Df Total',                     32 FROM DUAL UNION ALL
        SELECT 'ols_pass_count',               'Ols Pass Count',               33 FROM DUAL UNION ALL
        SELECT 'aic',                          'Aic',                          34 FROM DUAL UNION ALL
        SELECT 'bic',                          'Bic',                          35 FROM DUAL UNION ALL
        SELECT 'sic',                          'Sic',                          36 FROM DUAL UNION ALL
        SELECT 'mult_r_squared',               'Mult R Squared',               37 FROM DUAL
    ),
    current_max AS (
        SELECT NVL(MAX("pkid"), 0) AS max_pkid
        FROM NTT_RISK_MODELLING."FieldMappings"
    )
    SELECT current_max.max_pkid
               + ROW_NUMBER() OVER (ORDER BY mapping_values.seq) AS new_pkid,
           mapping_values.field_name,
           mapping_values.field_alias,
           mapping_values.seq
    FROM mapping_values
    CROSS JOIN current_max
) source
ON (
    target."mapping_tabel" = 'PyMultLinearRegrResultPen'
    AND target."field_name" = source.field_name
    AND target."output_group" IS NULL
)
WHEN MATCHED THEN UPDATE SET
    target."field_alias"  = source.field_alias,
    target."seq"          = source.seq,
    target."is_active"    = 1,
    target."is_deleted"   = 0,
    target."updated_by"   = 'svc_app_user',
    target."updated_date" = SYSTIMESTAMP,
    target."updated_host" = 'app-server-1',
    target."deleted_by"   = NULL,
    target."deleted_date" = NULL,
    target."deleted_host" = NULL
WHEN NOT MATCHED THEN INSERT (
    "pkid",
    "field_name",
    "field_alias",
    "is_active",
    "created_by",
    "created_date",
    "created_host",
    "is_deleted",
    "mapping_tabel",
    "seq",
    "output_group"
)
VALUES (
    source.new_pkid,
    source.field_name,
    source.field_alias,
    1,
    'svc_app_user',
    SYSTIMESTAMP,
    'app-server-1',
    0,
    'PyMultLinearRegrResultPen',
    source.seq,
    NULL
);


COMMIT;


-- Synchronize FieldMappings for PyFlImpact.
-- Existing forward-looking fields are preserved and regression fields follow
-- the display order used by PyMultLinearRegrResultPen.
--
-- Idempotent:
--   * existing mappings are reactivated and their alias/sequence is updated;
--   * missing mappings are inserted.

LOCK TABLE NTT_RISK_MODELLING."FieldMappings"
    IN SHARE ROW EXCLUSIVE MODE;


MERGE INTO NTT_RISK_MODELLING."FieldMappings" target
USING (
    WITH mapping_values (field_name, field_alias, seq) AS (
        SELECT 'period',                       'Periode',                       1 FROM DUAL UNION ALL
        SELECT 'model_seq',                    'Model Seq',                     2 FROM DUAL UNION ALL
        SELECT 'fl_impact',                    'Fl Impact',                     3 FROM DUAL UNION ALL
        SELECT 'model_formula',                'Model Formula',                 4 FROM DUAL UNION ALL
        SELECT 'intercept_name',               'Intercept Name',                5 FROM DUAL UNION ALL
        SELECT 'intercept',                    'Intercept',                     6 FROM DUAL UNION ALL
        SELECT 'p_value_intercept',            'P Value Intercept',             7 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_1',  'Coefficient Variable Name 1',  8 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_1',       'Coefficient Variable 1',       9 FROM DUAL UNION ALL
        SELECT 'p_value_variable_1',           'P Value Variable 1',          10 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_2',  'Coefficient Variable Name 2', 11 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_2',       'Coefficient Variable 2',      12 FROM DUAL UNION ALL
        SELECT 'p_value_variable_2',           'P Value Variable 2',          13 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_name_3',  'Coefficient Variable Name 3', 14 FROM DUAL UNION ALL
        SELECT 'coefficient_variable_3',       'Coefficient Variable 3',      15 FROM DUAL UNION ALL
        SELECT 'p_value_variable_3',           'P Value Variable 3',          16 FROM DUAL UNION ALL
        SELECT 'adj_r_squared',                'Adj R Squared',                17 FROM DUAL UNION ALL
        SELECT 'r_squared',                    'R Squared',                    18 FROM DUAL UNION ALL
        SELECT 'p_value',                      'P Value',                      19 FROM DUAL UNION ALL
        SELECT 'insample_mape',                'InSample Mape',                20 FROM DUAL UNION ALL
        SELECT 'outsample_mape',               'OutSample Mape',               21 FROM DUAL UNION ALL
        SELECT 'best_model',                   'Best Model',                   22 FROM DUAL UNION ALL
        SELECT 'is_selected',                  'Selected Model',               23 FROM DUAL UNION ALL
        SELECT 'status',                       'OLS Status',                   24 FROM DUAL UNION ALL
        SELECT 'year',                         'FL Impact Year {0} (%)',       25 FROM DUAL UNION ALL
        SELECT 'transform_odr_type',           'Transform Odr Type',           26 FROM DUAL UNION ALL
        SELECT 'kolmogorov_smirnov',           'Kolmogorov Smirnov',           27 FROM DUAL UNION ALL
        SELECT 'lagrange_multiplier',          'Lagrange Multiplier',          28 FROM DUAL UNION ALL
        SELECT 'variance_inflation_factor',    'Variance Inflation Factor',    29 FROM DUAL UNION ALL
        SELECT 'anderson_darling',             'Anderson Darling',             30 FROM DUAL UNION ALL
        SELECT 'breusch_pagan',                'Breusch-Pagan',                31 FROM DUAL UNION ALL
        SELECT 'durbin_watson',                'Durbin Watson',                32 FROM DUAL UNION ALL
        SELECT 'shapiro_wilk',                 'Shapiro Wilk',                 33 FROM DUAL UNION ALL
        SELECT 'f_statistic',                  'F Statistic',                  34 FROM DUAL UNION ALL
        SELECT 'df_regr',                      'Df Regr',                      35 FROM DUAL UNION ALL
        SELECT 'df_resd',                      'Df Resd',                      36 FROM DUAL UNION ALL
        SELECT 'df_total',                     'Df Total',                     37 FROM DUAL UNION ALL
        SELECT 'ols_pass_count',               'Ols Pass Count',               38 FROM DUAL UNION ALL
        SELECT 'aic',                          'Aic',                          39 FROM DUAL UNION ALL
        SELECT 'bic',                          'Bic',                          40 FROM DUAL UNION ALL
        SELECT 'sic',                          'Sic',                          41 FROM DUAL UNION ALL
        SELECT 'mult_r_squared',               'Mult R Squared',               42 FROM DUAL
    ),
    current_max AS (
        SELECT NVL(MAX("pkid"), 0) AS max_pkid
        FROM NTT_RISK_MODELLING."FieldMappings"
    )
    SELECT current_max.max_pkid
               + ROW_NUMBER() OVER (ORDER BY mapping_values.seq) AS new_pkid,
           mapping_values.field_name,
           mapping_values.field_alias,
           mapping_values.seq
    FROM mapping_values
    CROSS JOIN current_max
) source
ON (
    target."mapping_tabel" = 'PyFlImpact'
    AND target."field_name" = source.field_name
    AND target."output_group" IS NULL
)
WHEN MATCHED THEN UPDATE SET
    target."field_alias"  = source.field_alias,
    target."seq"          = source.seq,
    target."is_active"    = 1,
    target."is_deleted"   = 0,
    target."updated_by"   = 'svc_app_user',
    target."updated_date" = SYSTIMESTAMP,
    target."updated_host" = 'app-server-1',
    target."deleted_by"   = NULL,
    target."deleted_date" = NULL,
    target."deleted_host" = NULL
WHEN NOT MATCHED THEN INSERT (
    "pkid",
    "field_name",
    "field_alias",
    "is_active",
    "created_by",
    "created_date",
    "created_host",
    "is_deleted",
    "mapping_tabel",
    "seq",
    "output_group"
)
VALUES (
    source.new_pkid,
    source.field_name,
    source.field_alias,
    1,
    'svc_app_user',
    SYSTIMESTAMP,
    'app-server-1',
    0,
    'PyFlImpact',
    source.seq,
    NULL
);


-- Keep the pivot metadata aligned with the fields exposed above.
-- year remains the pivot column and fl_impact remains the aggregated value.
UPDATE NTT_RISK_MODELLING."TableMappings"
SET "pivot_row_fields" =
        'model_seq,model_formula,'
        || 'intercept_name,intercept,p_value_intercept,'
        || 'coefficient_variable_name_1,coefficient_variable_1,p_value_variable_1,'
        || 'coefficient_variable_name_2,coefficient_variable_2,p_value_variable_2,'
        || 'coefficient_variable_name_3,coefficient_variable_3,p_value_variable_3,'
        || 'adj_r_squared,r_squared,p_value,'
        || 'insample_mape,outsample_mape,best_model,is_selected,status,'
        || 'transform_odr_type,kolmogorov_smirnov,lagrange_multiplier,'
        || 'variance_inflation_factor,anderson_darling,breusch_pagan,'
        || 'durbin_watson,shapiro_wilk,f_statistic,df_regr,df_resd,df_total,'
        || 'ols_pass_count,aic,bic,sic,mult_r_squared',
    "pivot_column_field" = 'year',
    "pivot_value_field" = 'fl_impact',
    "pivot_agg_function" = 'SUM',
    "is_pivot_enabled" = 1,
    "is_active" = 1,
    "is_deleted" = 0,
    "updated_by" = 'svc_app_user',
    "updated_date" = SYSTIMESTAMP,
    "updated_host" = 'app-server-1',
    "deleted_by" = NULL,
    "deleted_date" = NULL,
    "deleted_host" = NULL
WHERE "schema_name" = 'NTT_RISK_MODELLING'
  AND "table_name" = 'PyFlImpact';


COMMIT;


MERGE INTO NTT_RISK_MODELLING."FieldMappings" target
USING (
    SELECT 'aic' AS field_name, 'AIC' AS field_alias, 1 AS is_active,
           'svc_app_user' AS created_by, TO_DATE('28-07-2026','DD-MM-RRRR') AS created_date,
           'app-server-1' AS created_host, 0 AS is_deleted,
           'PyArima' AS mapping_tabel, 5 AS seq
    FROM DUAL
) source
ON (
    target."mapping_tabel" = source.mapping_tabel
    AND target."field_name" = source.field_name
    AND target."output_group" IS NULL
)
WHEN NOT MATCHED THEN INSERT
(
    "field_name","field_alias","is_active","created_by","created_date","created_host",
    "is_deleted","mapping_tabel","seq","output_group"
)
VALUES
(
    source.field_name,source.field_alias,source.is_active,source.created_by,source.created_date,
    source.created_host,source.is_deleted,source.mapping_tabel,source.seq,NULL
);

commit;



-- Tuned backfill:
--   1. Materialize active target keys once.
--   2. Read source rows only for keys that exist in the target.
--   3. Update PyMultLinearRegrResultPen once with a single MERGE.
--   4. Preserve an existing column group when its source rows do not exist.

MERGE INTO NTT_RISK_MODELLING."PyMultLinearRegrResultPen" target
USING (
    WITH
    target_keys AS (
        SELECT /*+ MATERIALIZE */
               DISTINCT p."activity_code", p."model_seq"
        FROM NTT_RISK_MODELLING."PyMultLinearRegrResultPen" p
        WHERE p."is_deleted" = 0
    ),
    coefficient_ranked AS (
        SELECT /*+ USE_NL(pmc) */
               pmc."activity_code",
               pmc."model_seq",
               pmc."coeff_name",
               pmc."estimate_val",
               pmc."p_value",
               ROW_NUMBER() OVER (
                   PARTITION BY pmc."activity_code", pmc."model_seq"
                   ORDER BY pmc."pkid"
               ) AS coefficient_seq
        FROM target_keys keys
        INNER JOIN NTT_RISK_MODELLING."PyModelCoefficient" pmc
            ON pmc."activity_code" = keys."activity_code"
           AND pmc."model_seq" = keys."model_seq"
           AND pmc."is_deleted" = 0
        WHERE pmc."coeff_name" IS NOT NULL
          AND UPPER(TRIM(pmc."coeff_name")) <> 'CONST'
    ),
    coefficient_pivot AS (
        SELECT
            coefficient."activity_code",
            coefficient."model_seq",
            1 AS has_coefficient,
            MAX(CASE WHEN coefficient.coefficient_seq = 1
                     THEN coefficient."coeff_name" END) AS coefficient_variable_name_1,
            MAX(CASE WHEN coefficient.coefficient_seq = 1
                     THEN coefficient."estimate_val" END) AS coefficient_variable_1,
            MAX(CASE WHEN coefficient.coefficient_seq = 1
                     THEN coefficient."p_value" END) AS p_value_variable_1,
            MAX(CASE WHEN coefficient.coefficient_seq = 2
                     THEN coefficient."coeff_name" END) AS coefficient_variable_name_2,
            MAX(CASE WHEN coefficient.coefficient_seq = 2
                     THEN coefficient."estimate_val" END) AS coefficient_variable_2,
            MAX(CASE WHEN coefficient.coefficient_seq = 2
                     THEN coefficient."p_value" END) AS p_value_variable_2,
            MAX(CASE WHEN coefficient.coefficient_seq = 3
                     THEN coefficient."coeff_name" END) AS coefficient_variable_name_3,
            MAX(CASE WHEN coefficient.coefficient_seq = 3
                     THEN coefficient."estimate_val" END) AS coefficient_variable_3,
            MAX(CASE WHEN coefficient.coefficient_seq = 3
                     THEN coefficient."p_value" END) AS p_value_variable_3
        FROM coefficient_ranked coefficient
        WHERE coefficient.coefficient_seq <= 3
        GROUP BY coefficient."activity_code", coefficient."model_seq"
    ),
    intercept_pivot AS (
        SELECT /*+ USE_NL(pmc) */
            pmc."activity_code",
            pmc."model_seq",
            1 AS has_intercept,
            MAX(pmc."coeff_name") AS intercept_name,
            MAX(pmc."estimate_val") AS intercept,
            MAX(pmc."p_value") AS p_value_intercept
        FROM target_keys keys
        INNER JOIN NTT_RISK_MODELLING."PyModelCoefficient" pmc
            ON pmc."activity_code" = keys."activity_code"
           AND pmc."model_seq" = keys."model_seq"
           AND pmc."is_deleted" = 0
        WHERE UPPER(TRIM(pmc."coeff_name")) = 'CONST'
        GROUP BY pmc."activity_code", pmc."model_seq"
    ),
    ols_pivot AS (
        SELECT /*+ USE_NL(plsp ora) */
            plsp."activity_code",
            plsp."model_seq",
            1 AS has_ols,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'KOLMOGOROV SMIRNOV'
                    THEN plsp."p_value"
                END) AS kolmogorov_smirnov,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'LAGRANGE MULTIPLIER'
                    THEN plsp."p_value"
                END) AS lagrange_multiplier,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'VARIANCE INFLATION FACTOR'
                    THEN plsp."stats_value"
                END) AS variance_inflation_factor,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'ANDERSON DARLING'
                    THEN plsp."p_value"
                END) AS anderson_darling,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) IN ('BREUSCH-PAGAN', 'BREUSCH PAGAN')
                    THEN plsp."p_value"
                END) AS breusch_pagan,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'DURBIN WATSON'
                    THEN plsp."stats_value"
                END) AS durbin_watson,
            MAX(CASE
                    WHEN UPPER(TRIM(ora."method")) = 'SHAPIRO WILK'
                    THEN plsp."p_value"
                END) AS shapiro_wilk
        FROM target_keys keys
        INNER JOIN NTT_RISK_MODELLING."PyLinregStatsPen" plsp
            ON plsp."activity_code" = keys."activity_code"
           AND plsp."model_seq" = keys."model_seq"
        INNER JOIN NTT_RISK_MODELLING."OlsRegressionAssumptions" ora
            ON ora."activity_code" = plsp."activity_code"
           AND ora."method" = plsp."test_name"
           AND ora."type" = plsp."test_descr"
        WHERE UPPER(TRIM(ora."method")) IN (
            'KOLMOGOROV SMIRNOV',
            'LAGRANGE MULTIPLIER',
            'VARIANCE INFLATION FACTOR',
            'ANDERSON DARLING',
            'BREUSCH-PAGAN',
            'BREUSCH PAGAN',
            'DURBIN WATSON',
            'SHAPIRO WILK'
        )
        GROUP BY plsp."activity_code", plsp."model_seq"
    )
    SELECT
        keys."activity_code",
        keys."model_seq",
        coefficient.has_coefficient,
        coefficient.coefficient_variable_name_1,
        coefficient.coefficient_variable_1,
        coefficient.p_value_variable_1,
        coefficient.coefficient_variable_name_2,
        coefficient.coefficient_variable_2,
        coefficient.p_value_variable_2,
        coefficient.coefficient_variable_name_3,
        coefficient.coefficient_variable_3,
        coefficient.p_value_variable_3,
        intercept.has_intercept,
        intercept.intercept_name,
        intercept.intercept,
        intercept.p_value_intercept,
        ols.has_ols,
        ols.kolmogorov_smirnov,
        ols.lagrange_multiplier,
        ols.variance_inflation_factor,
        ols.anderson_darling,
        ols.breusch_pagan,
        ols.durbin_watson,
        ols.shapiro_wilk
    FROM target_keys keys
    LEFT JOIN coefficient_pivot coefficient
        ON coefficient."activity_code" = keys."activity_code"
       AND coefficient."model_seq" = keys."model_seq"
    LEFT JOIN intercept_pivot intercept
        ON intercept."activity_code" = keys."activity_code"
       AND intercept."model_seq" = keys."model_seq"
    LEFT JOIN ols_pivot ols
        ON ols."activity_code" = keys."activity_code"
       AND ols."model_seq" = keys."model_seq"
    WHERE coefficient.has_coefficient = 1
       OR intercept.has_intercept = 1
       OR ols.has_ols = 1
) source
ON (
    target."activity_code" = source."activity_code"
    AND target."model_seq" = source."model_seq"
    AND target."is_deleted" = 0
)
WHEN MATCHED THEN UPDATE SET
    target."coefficient_variable_name_1" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_name_1
             ELSE target."coefficient_variable_name_1" END,
    target."coefficient_variable_1" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_1
             ELSE target."coefficient_variable_1" END,
    target."p_value_variable_1" =
        CASE WHEN source.has_coefficient = 1
             THEN source.p_value_variable_1
             ELSE target."p_value_variable_1" END,
    target."coefficient_variable_name_2" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_name_2
             ELSE target."coefficient_variable_name_2" END,
    target."coefficient_variable_2" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_2
             ELSE target."coefficient_variable_2" END,
    target."p_value_variable_2" =
        CASE WHEN source.has_coefficient = 1
             THEN source.p_value_variable_2
             ELSE target."p_value_variable_2" END,
    target."coefficient_variable_name_3" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_name_3
             ELSE target."coefficient_variable_name_3" END,
    target."coefficient_variable_3" =
        CASE WHEN source.has_coefficient = 1
             THEN source.coefficient_variable_3
             ELSE target."coefficient_variable_3" END,
    target."p_value_variable_3" =
        CASE WHEN source.has_coefficient = 1
             THEN source.p_value_variable_3
             ELSE target."p_value_variable_3" END,
    target."intercept_name" =
        CASE WHEN source.has_intercept = 1
             THEN source.intercept_name
             ELSE target."intercept_name" END,
    target."intercept" =
        CASE WHEN source.has_intercept = 1
             THEN source.intercept
             ELSE target."intercept" END,
    target."p_value_intercept" =
        CASE WHEN source.has_intercept = 1
             THEN source.p_value_intercept
             ELSE target."p_value_intercept" END,
    target."kolmogorov_smirnov" =
        CASE WHEN source.has_ols = 1
             THEN source.kolmogorov_smirnov
             ELSE target."kolmogorov_smirnov" END,
    target."lagrange_multiplier" =
        CASE WHEN source.has_ols = 1
             THEN source.lagrange_multiplier
             ELSE target."lagrange_multiplier" END,
    target."variance_inflation_factor" =
        CASE WHEN source.has_ols = 1
             THEN source.variance_inflation_factor
             ELSE target."variance_inflation_factor" END,
    target."anderson_darling" =
        CASE WHEN source.has_ols = 1
             THEN source.anderson_darling
             ELSE target."anderson_darling" END,
    target."breusch_pagan" =
        CASE WHEN source.has_ols = 1
             THEN source.breusch_pagan
             ELSE target."breusch_pagan" END,
    target."durbin_watson" =
        CASE WHEN source.has_ols = 1
             THEN source.durbin_watson
             ELSE target."durbin_watson" END,
    target."shapiro_wilk" =
        CASE WHEN source.has_ols = 1
             THEN source.shapiro_wilk
             ELSE target."shapiro_wilk" END;


COMMIT;





MERGE INTO NTT_RISK_MODELLING."PyFlImpact" target
USING (
    SELECT
        source_data.fl_activity_code,
        source_data."model_seq",

        source_data."coefficient_variable_name_1",
        source_data."coefficient_variable_1",
        source_data."coefficient_variable_name_2",
        source_data."coefficient_variable_2",
        source_data."coefficient_variable_name_3",
        source_data."coefficient_variable_3",
        source_data."intercept_name",
        source_data."intercept",
        source_data."p_value_variable_1",
        source_data."p_value_variable_2",
        source_data."p_value_variable_3",
        source_data."p_value_intercept",

        source_data."kolmogorov_smirnov",
        source_data."lagrange_multiplier",
        source_data."variance_inflation_factor",
        source_data."anderson_darling",
        source_data."breusch_pagan",
        source_data."durbin_watson",
        source_data."shapiro_wilk",

        source_data."r_squared",
        source_data."p_value",
        source_data."f_statistic",
        source_data."df_regr",
        source_data."df_resd",
        source_data."df_total",
        source_data."ols_pass_count",
        source_data."aic",
        source_data."bic",
        source_data."sic",
        source_data."mult_r_squared"

    FROM (
        SELECT
            pfi."activity_code" AS fl_activity_code,
            pfi."model_seq",

            regression."coefficient_variable_name_1",
            regression."coefficient_variable_1",
            regression."coefficient_variable_name_2",
            regression."coefficient_variable_2",
            regression."coefficient_variable_name_3",
            regression."coefficient_variable_3",
            regression."intercept_name",
            regression."intercept",
            regression."p_value_variable_1",
            regression."p_value_variable_2",
            regression."p_value_variable_3",
            regression."p_value_intercept",

            regression."kolmogorov_smirnov",
            regression."lagrange_multiplier",
            regression."variance_inflation_factor",
            regression."anderson_darling",
            regression."breusch_pagan",
            regression."durbin_watson",
            regression."shapiro_wilk",

            regression."r_squared",
            regression."p_value",
            regression."f_statistic",
            regression."df_regr",
            regression."df_resd",
            regression."df_total",
            regression."ols_pass_count",
            regression."aic",
            regression."bic",
            regression."sic",
            regression."mult_r_squared",

            ROW_NUMBER() OVER (
                PARTITION BY
                    pfi."activity_code",
                    pfi."model_seq"
                ORDER BY
                    mapping."pkid",
                    regression."pkid" DESC
            ) AS row_seq

        FROM (
            SELECT DISTINCT
                impact."activity_code",
                impact."model_seq"
            FROM NTT_RISK_MODELLING."PyFlImpact" impact
            WHERE impact."is_deleted" = 0
              AND impact."activity_code" IS NOT NULL
              AND impact."model_seq" IS NOT NULL
        ) pfi

        INNER JOIN NTT_RISK_MODELLING."ModellingForwardMapping" mapping
            ON pfi."activity_code" LIKE mapping."fp_run_type" || '%'
           AND mapping."is_active" = 1
           AND mapping."is_deleted" = 0
           AND mapping."fp_run_type" IS NOT NULL
           AND mapping."mp_activity_code" IS NOT NULL

        INNER JOIN NTT_RISK_MODELLING."PyMultLinearRegrResultPen" regression
            ON regression."activity_code" = mapping."mp_activity_code"
           AND regression."model_seq" = pfi."model_seq"
           AND regression."is_deleted" = 0
    ) source_data
    WHERE source_data.row_seq = 1
) source
ON (
    target."activity_code" = source.fl_activity_code
    AND target."model_seq" = source."model_seq"
    AND target."is_deleted" = 0
)
WHEN MATCHED THEN UPDATE SET
    target."coefficient_variable_name_1" =
        source."coefficient_variable_name_1",

    target."coefficient_variable_1" =
        source."coefficient_variable_1",

    target."coefficient_variable_name_2" =
        source."coefficient_variable_name_2",

    target."coefficient_variable_2" =
        source."coefficient_variable_2",

    target."coefficient_variable_name_3" =
        source."coefficient_variable_name_3",

    target."coefficient_variable_3" =
        source."coefficient_variable_3",

    target."intercept_name" =
        source."intercept_name",

    target."intercept" =
        source."intercept",

    target."p_value_variable_1" =
        source."p_value_variable_1",

    target."p_value_variable_2" =
        source."p_value_variable_2",

    target."p_value_variable_3" =
        source."p_value_variable_3",

    target."p_value_intercept" =
        source."p_value_intercept",

    target."kolmogorov_smirnov" =
        source."kolmogorov_smirnov",

    target."lagrange_multiplier" =
        source."lagrange_multiplier",

    target."variance_inflation_factor" =
        source."variance_inflation_factor",

    target."anderson_darling" =
        source."anderson_darling",

    target."breusch_pagan" =
        source."breusch_pagan",

    target."durbin_watson" =
        source."durbin_watson",

    target."shapiro_wilk" =
        source."shapiro_wilk",

    target."r_squared" =
        source."r_squared",

    target."p_value" =
        source."p_value",

    target."f_statistic" =
        source."f_statistic",

    target."df_regr" =
        source."df_regr",

    target."df_resd" =
        source."df_resd",

    target."df_total" =
        source."df_total",

    target."ols_pass_count" =
        source."ols_pass_count",

    target."aic" =
        source."aic",

    target."bic" =
        source."bic",

    target."sic" =
        source."sic",

    target."mult_r_squared" =
        source."mult_r_squared",

    target."updated_date" = SYSDATE;


COMMIT;


-----------------------------------------------------
-- ini belum deploy ke prod
MERGE INTO NTT_PARAMETER."MstConfigApi" target
USING (
    SELECT
        'GetCleansingMevOutput' AS name,
        'Get Cleansing Mev Output' AS description,
        'https://portal.bsi.qa.regla.cloud/api/risk-modelling/LookingFlowManager/GetCleansingMevOutput' AS value,
        'system' AS created_by,
        TO_DATE('17-09-2024','DD-MM-RRRR') AS created_date,
        'localhost' AS created_host,
        'http://risk-modelling:8080/LookingFlowManager/GetCleansingMevOutput' AS private_url
    FROM DUAL
) source
ON (target."name" = source.name AND target."is_deleted" = 0)
WHEN NOT MATCHED THEN INSERT
(
    "name",
    "description",
    "value",
    "created_by",
    "created_date",
    "updated_by",
    "updated_date",
    "created_host",
    "updated_host",
    "private_url",
    "is_deleted",
    "deleted_by",
    "deleted_date",
    "deleted_host"
)
VALUES
(
    source.name,
    source.description,
    source.value,
    source.created_by,
    source.created_date,
    NULL,
    NULL,
    source.created_host,
    NULL,
    source.private_url,
    0,
    NULL,
    NULL,
    NULL
);

COMMIT;


-- Contoh konfigurasi (sesuaikan alias sesuai kebutuhan UI):
-- INSERT INTO NTT_RISK_MODELLING."TableElementAliases"
--     ("mapping_tabel", "type_element", "table_alias", "created_by", "created_host")
-- VALUES
--     ('PyWeightingScenarioInterpolasi', 'WeightingScenario', 'Weighting Scenario', 'system', 'migration');

MERGE INTO NTT_RISK_MODELLING."TableElementAliases" target
USING (
    SELECT 'PyWeightingScenarioInterpolasi' AS mapping_tabel,
           'WeightingScenario' AS type_element,
           'Weighting Scenario' AS table_alias
    FROM DUAL
) source
ON (
    target."mapping_tabel" = source.mapping_tabel
    AND target."type_element" = source.type_element
)
WHEN NOT MATCHED THEN INSERT
(
    "mapping_tabel","type_element","table_alias","created_by","created_host"
)
VALUES
(
    source.mapping_tabel,source.type_element,source.table_alias,'system','migration'
);


MERGE INTO NTT_RISK_MODELLING."TableElementAliases" target
USING (
    SELECT 'PyWeightingScenarioInterpolasi' AS mapping_tabel,
           'Interpolation-PSAK413' AS type_element,
           'Interpolation PSAK 413' AS table_alias
    FROM DUAL
) source
ON (
    target."mapping_tabel" = source.mapping_tabel
    AND target."type_element" = source.type_element
)
WHEN NOT MATCHED THEN INSERT
(
    "mapping_tabel","type_element","table_alias","created_by","created_host"
)
VALUES
(
    source.mapping_tabel,source.type_element,source.table_alias,'system','migration'
);


UPDATE NTT_RISK_MODELLING."TableSplitConfig"
SET "split_filter" = 'FlType != ''fl_pd_calculation'''
WHERE "table_mapping_pkid" = 274;


-- Configurable metadata variant for FlType=fl_pd_calculation.
-- This row controls the displayed table alias. It does not add a row filter.
MERGE INTO NTT_RISK_MODELLING."TableMappings" target_mapping
USING
(
    SELECT 'PyWeightingScenarioInterpolasi|fl_pd_calculation' AS "table_name"
    FROM DUAL
) source_mapping
ON
(
    target_mapping."table_name" = source_mapping."table_name"
    AND target_mapping."is_deleted" = 0
)
WHEN NOT MATCHED THEN
    INSERT
    (
        "schema_name", "table_name", "is_active", "created_by", "created_date",
        "created_host", "is_deleted", "tabel_alias", "is_split_enabled",
        "is_pivot_enabled"
    )
    VALUES
    (
        'NTT_RISK_MODELLING',
        source_mapping."table_name",
        1,
        'svc_app_user',
        SYSDATE,
        'app-server-1',
        0,
        'Weighting MPD',
        0,
        0
    );


-- Initially copy the MPD field configuration. After this, aliases, sequence,
-- active status, and selected fields can be customized independently.
INSERT INTO NTT_RISK_MODELLING."FieldMappings"
(
    "field_name", "field_alias", "is_active", "created_by", "created_date",
    "created_host", "is_deleted", "mapping_tabel", "seq", "output_group"
)
SELECT
    source_mapping."field_name",
    source_mapping."field_alias",
    source_mapping."is_active",
    'svc_app_user',
    SYSDATE,
    'app-server-1',
    0,
    'PyWeightingScenarioInterpolasi|fl_pd_calculation',
    source_mapping."seq",
    source_mapping."output_group"
FROM NTT_RISK_MODELLING."FieldMappings" source_mapping
WHERE source_mapping."mapping_tabel" = 'PyWeightingScenarioInterpolasi|MPD'
  AND source_mapping."is_deleted" = 0
  AND NOT EXISTS
  (
      SELECT 1
      FROM NTT_RISK_MODELLING."FieldMappings" target_mapping
      WHERE target_mapping."mapping_tabel" = 'PyWeightingScenarioInterpolasi|fl_pd_calculation'
        AND target_mapping."field_name" = source_mapping."field_name"
        AND target_mapping."is_deleted" = 0
  );


COMMIT;


MERGE INTO NTT_PARAMETER."MstLookUpData" target
USING (
    SELECT
        'Workflow' AS api_project_name,
        'FlElementType' AS unique_key,
        3 AS sequence,
        'fl_pd_calculation' AS value,
        'FL PD Calculation' AS text
    FROM DUAL
) source
ON (
    target."unique_key" = source.unique_key
    AND target."value" = source.value
    AND target."is_deleted" = 0
)
WHEN NOT MATCHED THEN INSERT
(
    "api_project_name",
    "unique_key",
    "sequence",
    "value",
    "text",
    "description",
    "is_active",
    "created_by",
    "created_date",
    "created_host",
    "updated_by",
    "updated_date",
    "updated_host",
    "reference_value",
    "is_deleted",
    "deleted_by",
    "deleted_date",
    "deleted_host",
    "code_app"
)
VALUES
(
    source.api_project_name,
    source.unique_key,
    source.sequence,
    source.value,
    source.text,
    EMPTY_CLOB(),
    1,
    'system',
    TO_DATE('30-08-2024','DD-MM-RRRR'),
    'localhost',
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    NULL,
    NULL,
    NULL,
    NULL
);

commit;


-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped

---------------------------------------------------------
-- migrasi tanggal 19-08-2026

INSERT INTO NTT_PARAMETER."MstConfigApi"
(
    "pkid",
    "name",
    "description",
    "value",
    "created_by",
    "created_date",
    "created_host",
    "private_url",
    "is_deleted"
)
SELECT
    NVL(MAX("pkid"), 0) + 1,
    'GetRunningStdWorkflows',
    'Get Running STD Workflows',
    'https://portal.bsi.qa.regla.cloud/api/workflow/RunningHistory/GetRunningStdWorkflows',
    'system',
    SYSDATE,
    'localhost',
    'http://workflow:8080/RunningHistory/GetRunningStdWorkflows',
    0
FROM NTT_PARAMETER."MstConfigApi"
WHERE NOT EXISTS
(
    SELECT 1
    FROM NTT_PARAMETER."MstConfigApi"
    WHERE "name" = 'GetRunningStdWorkflows'
);


COMMIT;


-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped

SELECT * FROM NTT_RISK_MODELLING."TableMappings" tm WHERE tm."table_name" IN (
SELECT fm."mapping_tabel"  FROM NTT_RISK_MODELLING."FieldMappings" fm WHERE fm."field_name" ='me_code');


INSERT INTO NTT_PARAMETER."MstConfigApi"
(
    "pkid",
    "name",
    "description",
    "value",
    "private_url",
    "created_by",
    "created_date",
    "created_host",
    "is_deleted"
)
SELECT
    (
        SELECT NVL(MAX(m."pkid"), 0) + 1
        FROM NTT_PARAMETER."MstConfigApi" m
    ),
    'GatApprovalStatusByHeader',
    'Get forward looking model approval status by workflow header draft pkid',
    REPLACE(
        old_config."value",
        '/GatApprovalStatus',
        '/GatApprovalStatusByHeader'
    ),
    REPLACE(
        old_config."private_url",
        '/GatApprovalStatus',
        '/GatApprovalStatusByHeader'
    ),
    'SYSTEM',
    SYSDATE,
    'MIGRATION',
    0
FROM NTT_PARAMETER."MstConfigApi" old_config
WHERE old_config."name" = 'GatApprovalStatus'
  AND old_config."is_deleted" = 0
  AND NOT EXISTS
  (
      SELECT 1
      FROM NTT_PARAMETER."MstConfigApi" existing_config
      WHERE existing_config."name" = 'GatApprovalStatusByHeader'
  );


COMMIT;


MERGE INTO NTT_PARAMETER."GlobalMessage" target
USING
(
    SELECT
        messages.*,
        (SELECT NVL(MAX("pkid"), 0) FROM NTT_PARAMETER."GlobalMessage")
            + ROW_NUMBER() OVER (ORDER BY messages.accept_language) AS new_pkid
    FROM
    (
        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'en-US' AS accept_language,
            'UNABLE_ACTIVATE_UNAPPROVED_FORWARD_LOOKING_MODEL' AS message_name,
            'Unable to activate this record because the associated model has not been approved and locked. Please approve and lock the model in Risk Modelling before activating this record.' AS message_value
        FROM DUAL

        UNION ALL

        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'id-ID' AS accept_language,
            'UNABLE_ACTIVATE_UNAPPROVED_FORWARD_LOOKING_MODEL' AS message_name,
            'Unable to activate this record because the associated model has not been approved and locked. Please approve and lock the model in Risk Modelling before activating this record.' AS message_value
        FROM DUAL
    ) messages
) source
ON
(
    target."accept_language" = source.accept_language
    AND target."name" = source.message_name
)
WHEN MATCHED THEN
    UPDATE SET
        target."api_project_name" = source.api_project_name,
        target."value" = source.message_value,
        target."description" = NULL,
        target."updated_by" = 'system',
        target."updated_date" = CURRENT_TIMESTAMP,
        target."updated_host" = 'localhost',
        target."is_deleted" = 0
WHEN NOT MATCHED THEN
    INSERT
    (
        "pkid",
        "api_project_name",
        "accept_language",
        "name",
        "value",
        "description",
        "created_by",
        "created_date",
        "created_host",
        "is_deleted"
    )
    VALUES
    (
        source.new_pkid,
        source.api_project_name,
        source.accept_language,
        source.message_name,
        source.message_value,
        NULL,
        'system',
        CURRENT_TIMESTAMP,
        'localhost',
        0
    );


COMMIT;



MERGE INTO NTT_PARAMETER."MstLookUpData" target
USING (
    SELECT
        (SELECT NVL(MAX(existing."pkid"), 0)
         FROM NTT_PARAMETER."MstLookUpData" existing) + frequency_sequence AS "pkid",
        'Workflow' AS "api_project_name",
        'ZScoreFrequency' AS "unique_key",
        frequency_sequence AS "sequence",
        frequency_value AS "value",
        frequency_value AS "text",
        frequency_description AS "description"
    FROM (
        SELECT 1 AS frequency_sequence,
               'Monthly' AS frequency_value,
               'Monthly Z-Score frequency' AS frequency_description
        FROM DUAL
        UNION ALL
        SELECT 2, 'Quarterly', 'Quarterly Z-Score frequency' FROM DUAL
        UNION ALL
        SELECT 3, 'Yearly', 'Yearly Z-Score frequency' FROM DUAL
    )
) source
ON (
    LOWER(target."unique_key") = LOWER(source."unique_key")
    AND LOWER(target."value") = LOWER(source."value")
    AND target."is_deleted" = 0
)
WHEN NOT MATCHED THEN
    INSERT (
        "pkid", "api_project_name", "unique_key", "sequence", "value", "text",
        "description", "is_active", "created_by", "created_date", "created_host",
        "is_deleted", "code_app"
    )
    VALUES (
        source."pkid", source."api_project_name", source."unique_key", source."sequence",
        source."value", source."text", source."description", 1, 'system', SYSDATE,
        'localhost', 0, NULL
    );


COMMIT;


MERGE INTO NTT_PARAMETER."MstLookUpData" target
USING (
    SELECT
        (SELECT NVL(MAX(existing."pkid"), 0)
         FROM NTT_PARAMETER."MstLookUpData" existing) + month_sequence AS "pkid",
        'Workflow' AS "api_project_name",
        'ZScoreMonth' AS "unique_key",
        month_sequence AS "sequence",
        month_code AS "value",
        month_name AS "text",
        month_name || ' reference month for Yearly Z-Score frequency' AS "description"
    FROM (
        SELECT 1 AS month_sequence, '01' AS month_code, 'January' AS month_name FROM DUAL
        UNION ALL SELECT 2, '02', 'February' FROM DUAL
        UNION ALL SELECT 3, '03', 'March' FROM DUAL
        UNION ALL SELECT 4, '04', 'April' FROM DUAL
        UNION ALL SELECT 5, '05', 'May' FROM DUAL
        UNION ALL SELECT 6, '06', 'June' FROM DUAL
        UNION ALL SELECT 7, '07', 'July' FROM DUAL
        UNION ALL SELECT 8, '08', 'August' FROM DUAL
        UNION ALL SELECT 9, '09', 'September' FROM DUAL
        UNION ALL SELECT 10, '10', 'October' FROM DUAL
        UNION ALL SELECT 11, '11', 'November' FROM DUAL
        UNION ALL SELECT 12, '12', 'December' FROM DUAL
    )
) source
ON (
    LOWER(target."unique_key") = LOWER(source."unique_key")
    AND target."sequence" = source."sequence"
    AND target."is_deleted" = 0
)
WHEN MATCHED THEN
    UPDATE SET
        target."value" = source."value",
        target."text" = source."text",
        target."description" = source."description",
        target."is_active" = 1,
        target."updated_by" = 'system',
        target."updated_date" = SYSDATE,
        target."updated_host" = 'localhost'
WHEN NOT MATCHED THEN
    INSERT (
        "pkid", "api_project_name", "unique_key", "sequence", "value", "text",
        "description", "is_active", "created_by", "created_date", "created_host",
        "is_deleted", "code_app"
    )
    VALUES (
        source."pkid", source."api_project_name", source."unique_key", source."sequence",
        source."value", source."text", source."description", 1, 'system', SYSDATE,
        'localhost', 0, NULL
    );


COMMIT;


-- Oracle metadata for the two regression diagnostics.
-- Apply after add-jarque-bera-breusch-godfrey.oracle.sql.
DECLARE
    v_next_pkid NUMBER;
BEGIN
    SELECT NVL(MAX("pkid"), 0)
      INTO v_next_pkid
      FROM NTT_RISK_MODELLING."FieldMappings";

    FOR item IN (
        SELECT 'PyMultLinearRegrResultPen' AS table_name,
               'jarque_bera' AS field_name,
               'Jarque Bera' AS field_alias, 38 AS field_seq FROM dual
        UNION ALL SELECT 'PyMultLinearRegrResultPen', 'breusch_godfrey',
                         'Breusch Godfrey', 39 FROM dual
        UNION ALL SELECT 'PyFlImpact', 'jarque_bera', 'Jarque Bera', 14 FROM dual
        UNION ALL SELECT 'PyFlImpact', 'breusch_godfrey',
                         'Breusch Godfrey', 15 FROM dual
    ) LOOP
        UPDATE NTT_RISK_MODELLING."FieldMappings"
           SET "field_alias" = item.field_alias,
               "is_active" = 1,
               "is_deleted" = 0,
               "seq" = item.field_seq,
               "updated_by" = 'svc_app_user',
               "updated_date" = SYSDATE,
               "updated_host" = 'app-server-1'
         WHERE "mapping_tabel" = item.table_name
           AND "field_name" = item.field_name;

        IF SQL%ROWCOUNT = 0 THEN
            v_next_pkid := v_next_pkid + 1;
            INSERT INTO NTT_RISK_MODELLING."FieldMappings"
                ("pkid", "field_name", "field_alias", "is_active",
                 "created_by", "created_date", "created_host", "is_deleted",
                 "mapping_tabel", "seq")
            VALUES
                (v_next_pkid, item.field_name, item.field_alias, 1,
                 'svc_app_user', SYSDATE, 'app-server-1', 0,
                 item.table_name, item.field_seq);
        END IF;
    END LOOP;

    FOR mapping IN (
        SELECT "pkid", "pivot_row_fields"
          FROM NTT_RISK_MODELLING."TableMappings"
         WHERE "schema_name" = 'NTT_RISK_MODELLING'
           AND "table_name" IN ('PyMultLinearRegrResultPen', 'PyFlImpact')
           AND "is_deleted" = 0
         FOR UPDATE
    ) LOOP
        UPDATE NTT_RISK_MODELLING."TableMappings"
           SET "pivot_row_fields" =
                   CASE WHEN INSTR(',' || REPLACE(NVL(mapping."pivot_row_fields", ''), ' ', '') || ',', ',jarque_bera,') = 0
                        THEN NVL2("pivot_row_fields", "pivot_row_fields" || ',', '') || 'jarque_bera'
                        ELSE "pivot_row_fields" END,
               "updated_by" = 'svc_app_user',
               "updated_date" = SYSDATE,
               "updated_host" = 'app-server-1'
         WHERE "pkid" = mapping."pkid"
           AND INSTR(',' || REPLACE(NVL(mapping."pivot_row_fields", ''), ' ', '') || ',', ',jarque_bera,') = 0;

        UPDATE NTT_RISK_MODELLING."TableMappings"
           SET "pivot_row_fields" = NVL2("pivot_row_fields", "pivot_row_fields" || ',', '') || 'breusch_godfrey',
               "updated_by" = 'svc_app_user',
               "updated_date" = SYSDATE,
               "updated_host" = 'app-server-1'
         WHERE "pkid" = mapping."pkid"
           AND INSTR(',' || REPLACE(NVL("pivot_row_fields", ''), ' ', '') || ',', ',breusch_godfrey,') = 0;
    END LOOP;
END;
/


-- Oracle metadata for the two regression diagnostics.
-- Apply after add-jarque-bera-breusch-godfrey.oracle.sql.
DECLARE
    v_next_pkid NUMBER;
BEGIN
    SELECT NVL(MAX("pkid"), 0)
      INTO v_next_pkid
      FROM NTT_RISK_MODELLING."FieldMappings";

    -- Reserve two positions immediately after Shapiro Wilk in each mapping.
    FOR target_table IN (
        SELECT 'PyMultLinearRegrResultPen' AS table_name FROM dual
        UNION ALL SELECT 'PyFlImpact' FROM dual
    ) LOOP
        DECLARE
            v_shapiro_seq NUMBER;
        BEGIN
            SELECT "seq"
              INTO v_shapiro_seq
              FROM NTT_RISK_MODELLING."FieldMappings"
             WHERE "mapping_tabel" = target_table.table_name
               AND "field_name" = 'shapiro_wilk'
               AND "is_deleted" = 0;

            -- Shift existing fields only when the new positions are not yet reserved.
            UPDATE NTT_RISK_MODELLING."FieldMappings"
               SET "seq" = "seq" + 2,
                   "updated_by" = 'svc_app_user',
                   "updated_date" = SYSDATE,
                   "updated_host" = 'app-server-1'
             WHERE "mapping_tabel" = target_table.table_name
               AND "seq" > v_shapiro_seq
               AND "field_name" NOT IN ('jarque_bera', 'breusch_godfrey')
               AND NOT EXISTS (
                   SELECT 1
                     FROM NTT_RISK_MODELLING."FieldMappings" existing_mapping
                    WHERE existing_mapping."mapping_tabel" = target_table.table_name
                      AND existing_mapping."field_name" = 'jarque_bera'
                      AND existing_mapping."seq" = v_shapiro_seq + 1
               );

            FOR item IN (
                SELECT 'jarque_bera' AS field_name,
                       'Jarque Bera' AS field_alias,
                       v_shapiro_seq + 1 AS field_seq FROM dual
                UNION ALL
                SELECT 'breusch_godfrey', 'Breusch Godfrey',
                       v_shapiro_seq + 2 FROM dual
            ) LOOP
                UPDATE NTT_RISK_MODELLING."FieldMappings"
                   SET "field_alias" = item.field_alias,
                       "is_active" = 1,
                       "is_deleted" = 0,
                       "seq" = item.field_seq,
                       "updated_by" = 'svc_app_user',
                       "updated_date" = SYSDATE,
                       "updated_host" = 'app-server-1'
                 WHERE "mapping_tabel" = target_table.table_name
                   AND "field_name" = item.field_name;

                IF SQL%ROWCOUNT = 0 THEN
                    v_next_pkid := v_next_pkid + 1;
                    INSERT INTO NTT_RISK_MODELLING."FieldMappings"
                        ("pkid", "field_name", "field_alias", "is_active",
                         "created_by", "created_date", "created_host", "is_deleted",
                         "mapping_tabel", "seq")
                    VALUES
                        (v_next_pkid, item.field_name, item.field_alias, 1,
                         'svc_app_user', SYSDATE, 'app-server-1', 0,
                         target_table.table_name, item.field_seq);
                END IF;
            END LOOP;
        END;
    END LOOP;
    FOR mapping IN (
        SELECT "pkid", "pivot_row_fields"
          FROM NTT_RISK_MODELLING."TableMappings"
         WHERE "schema_name" = 'NTT_RISK_MODELLING'
           AND "table_name" IN ('PyMultLinearRegrResultPen', 'PyFlImpact')
           AND "is_deleted" = 0
         FOR UPDATE
    ) LOOP
        UPDATE NTT_RISK_MODELLING."TableMappings"
           SET "pivot_row_fields" =
                   CASE WHEN INSTR(',' || REPLACE(NVL(mapping."pivot_row_fields", ''), ' ', '') || ',', ',jarque_bera,') = 0
                        THEN NVL2("pivot_row_fields", "pivot_row_fields" || ',', '') || 'jarque_bera'
                        ELSE "pivot_row_fields" END,
               "updated_by" = 'svc_app_user',
               "updated_date" = SYSDATE,
               "updated_host" = 'app-server-1'
         WHERE "pkid" = mapping."pkid"
           AND INSTR(',' || REPLACE(NVL(mapping."pivot_row_fields", ''), ' ', '') || ',', ',jarque_bera,') = 0;

        UPDATE NTT_RISK_MODELLING."TableMappings"
           SET "pivot_row_fields" = NVL2("pivot_row_fields", "pivot_row_fields" || ',', '') || 'breusch_godfrey',
               "updated_by" = 'svc_app_user',
               "updated_date" = SYSDATE,
               "updated_host" = 'app-server-1'
         WHERE "pkid" = mapping."pkid"
           AND INSTR(',' || REPLACE(NVL("pivot_row_fields", ''), ' ', '') || ',', ',breusch_godfrey,') = 0;
    END LOOP;
END;
/


-- Display metadata for PyMertonZscore. Run in the Oracle risk modelling schema.
LOCK TABLE NTT_RISK_MODELLING."TableMappings" IN SHARE ROW EXCLUSIVE MODE;

LOCK TABLE NTT_RISK_MODELLING."FieldMappings" IN SHARE ROW EXCLUSIVE MODE;


MERGE INTO NTT_RISK_MODELLING."TableMappings" target
USING (
    SELECT NVL(MAX("pkid"), 0) + 1 AS new_pkid
      FROM NTT_RISK_MODELLING."TableMappings"
) source
ON (target."schema_name" = 'NTT_RISK_MODELLING'
    AND target."table_name" = 'PyMertonZscore'
    AND target."is_deleted" = 0)
WHEN MATCHED THEN UPDATE SET
    target."tabel_alias" = 'Parameter Z-Score Summary',
    target."is_active" = 1,
    target."updated_by" = 'svc_app_user',
    target."updated_date" = SYSDATE,
    target."updated_host" = 'app-server-1'
WHEN NOT MATCHED THEN INSERT
    ("pkid", "schema_name", "table_name", "tabel_alias", "is_active",
     "is_deleted", "is_pivot_enabled", "is_split_enabled",
     "created_by", "created_date", "created_host")
VALUES
    (source.new_pkid, 'NTT_RISK_MODELLING', 'PyMertonZscore',
     'Parameter Z-Score Summary', 1, 0, 0, 0,
     'svc_app_user', SYSDATE, 'app-server-1');


MERGE INTO NTT_RISK_MODELLING."FieldMappings" target
USING (
    WITH field_values (field_name, field_alias, field_seq) AS (
        SELECT 'date_from',         'Date From',     1 FROM DUAL UNION ALL
        SELECT 'date_to',           'Date To',       2 FROM DUAL UNION ALL
        SELECT 'frequency',         'Frequency',     3 FROM DUAL UNION ALL
        SELECT 'forecast_mev_type', 'Scenario Type', 4 FROM DUAL UNION ALL
        SELECT 'mean',              'Mean',          5 FROM DUAL UNION ALL
        SELECT 'stdev',             'Std Dev',       6 FROM DUAL
    )
    SELECT field_values.field_name,
           field_values.field_alias,
           field_values.field_seq,
           (SELECT NVL(MAX("pkid"), 0)
              FROM NTT_RISK_MODELLING."FieldMappings")
               + ROW_NUMBER() OVER (ORDER BY field_values.field_seq) AS new_pkid
      FROM field_values
) source
ON (target."mapping_tabel" = 'PyMertonZscore'
    AND target."field_name" = source.field_name
    AND target."output_group" IS NULL)
WHEN MATCHED THEN UPDATE SET
    target."field_alias" = source.field_alias,
    target."seq" = source.field_seq,
    target."is_active" = 1,
    target."is_deleted" = 0,
    target."deleted_by" = NULL,
    target."deleted_date" = NULL,
    target."deleted_host" = NULL,
    target."updated_by" = 'svc_app_user',
    target."updated_date" = SYSDATE,
    target."updated_host" = 'app-server-1'
WHEN NOT MATCHED THEN INSERT
    ("pkid", "field_name", "field_alias", "seq", "mapping_tabel",
     "is_active", "is_deleted", "created_by", "created_date", "created_host")
VALUES
    (source.new_pkid, source.field_name, source.field_alias, source.field_seq,
     'PyMertonZscore', 1, 0, 'svc_app_user', SYSDATE, 'app-server-1');


COMMIT;


SELECT "mapping_tabel", "field_name", "field_alias", "seq"
  FROM NTT_RISK_MODELLING."FieldMappings"
 WHERE "mapping_tabel" = 'PyMertonZscore'
   AND "is_deleted" = 0
 ORDER BY "seq";


SELECT "schema_name", "table_name", "tabel_alias"
  FROM NTT_RISK_MODELLING."TableMappings"
 WHERE "schema_name" = 'NTT_RISK_MODELLING'
   AND "table_name" = 'PyMertonZscore'
   AND "is_deleted" = 0;

---- selesai----

UPDATE NTT_RISK_MODELLING."TableMappings"
SET "default_order_by"='bucket ASC'
WHERE "table_name" ='PyWeightingScenarioInterpolasi|fl_pd_calculation';

 
UPDATE NTT_RISK_MODELLING."TableMappings"
SET "default_order_by"='bucket_from ASC, bucket_to ASC'
WHERE "table_name" ='PyNormInverse';

 
UPDATE NTT_RISK_MODELLING."TableMappings"
SET "default_order_by"='year ASC, month ASC, bucket ASC'
WHERE "table_name" ='PyWeightingScenarioInterpolasi|CPD';

 
 
UPDATE NTT_RISK_MODELLING."TableMappings"
SET "default_order_by"='year ASC, month ASC, bucket ASC'
WHERE "table_name" ='PyWeightingScenarioInterpolasi|MPD';


UPDATE NTT_RISK_MODELLING."TableMappings"
SET "default_order_by"='bucket ASC'
WHERE "table_name" ='PyWeightingScenarioInterpolasi';



-- EXCLUDED FOR PRODUCTION DEPLOYMENT: table statistics collection intentionally skipped

UPDATE NTT_RISK_MODELLING."TableMappings"
   SET "default_order_by" =
       'best_model DESC, MAPE_TIER(insample_mape|outsample_mape|20|30|40|50) ASC, adj_r_squared DESC, model_seq ASC',
       "updated_date" = SYSTIMESTAMP
 WHERE "table_name" = 'PyFlImpact'
   AND "is_active" = 1
   AND "is_deleted" = 0;


COMMIT;


SELECT "table_name", "default_order_by"
  FROM NTT_RISK_MODELLING."TableMappings"
 WHERE "table_name" = 'PyFlImpact'
   AND "is_active" = 1
   AND "is_deleted" = 0;

   
UPDATE NTT_RISK_MODELLING."FieldMappings"
SET "field_alias" =
    CASE "field_name"
        WHEN 'adj_r_squared'  THEN 'Adj R Squared (%)'
        WHEN 'r_squared'      THEN 'R Squared (%)'
        WHEN 'insample_mape'  THEN 'Insample Mape (%)'
        WHEN 'outsample_mape' THEN 'OutSample Mape (%)'
        WHEN 'year'           THEN 'FL Impact Year {0} (%)'
        WHEN 'mult_r_squared' THEN 'Mult R Squared (%)'
    END,
    "updated_date" = SYSTIMESTAMP
WHERE "mapping_tabel" = 'PyFlImpact'
  AND "field_name" IN (
      'adj_r_squared',
      'r_squared',
      'insample_mape',
      'outsample_mape',
      'year',
      'mult_r_squared'
  )
  AND "is_active" = 1
  AND "is_deleted" = 0;

  
  UPDATE NTT_RISK_MODELLING."FieldMappings"
SET
    "field_alias" =
        CASE "field_name"
            WHEN 'adj_r_squared'   THEN 'Adj R Squared (%)'
            WHEN 'r_squared'       THEN 'R Squared (%)'
            WHEN 'pdrate_mape'     THEN 'Insample Mape (%)'
            WHEN 'avg_pdrate_mape' THEN 'OutSample Mape (%)'
            WHEN 'mult_r_squared'  THEN 'Mult R Squared (%)'
        END,
    "updated_date" = SYSTIMESTAMP
WHERE "mapping_tabel" = 'PyMultLinearRegrResultPen'
  AND "field_name" IN (
      'adj_r_squared',
      'r_squared',
      'pdrate_mape',
      'avg_pdrate_mape',
      'mult_r_squared'
  )
  AND "is_active" = 1
  AND "is_deleted" = 0;

  
  MERGE INTO NTT_PARAMETER."GlobalMessage" target
USING
(
    SELECT
        messages.*,
        (SELECT NVL(MAX("pkid"), 0) FROM NTT_PARAMETER."GlobalMessage")
            + ROW_NUMBER() OVER (ORDER BY messages.accept_language) AS new_pkid
    FROM
    (
        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'en-US' AS accept_language,
            'SCENARIO_REPAYMENT_RATE_NOT_CONFIGURED' AS message_name,
            'This scenario cannot be selected. Please choose another scenario.' AS message_value
        FROM DUAL

        UNION ALL

        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'id-ID' AS accept_language,
            'SCENARIO_REPAYMENT_RATE_NOT_CONFIGURED' AS message_name,
            'Skenario ini tidak dapat dipilih. Silakan pilih skenario lain.' AS message_value
        FROM DUAL
    ) messages
) source
ON
(
    target."accept_language" = source.accept_language
    AND target."name" = source.message_name
)
WHEN MATCHED THEN
    UPDATE SET
        target."api_project_name" = source.api_project_name,
        target."value" = source.message_value,
        target."description" = NULL,
        target."updated_by" = 'system',
        target."updated_date" = CURRENT_TIMESTAMP,
        target."updated_host" = 'localhost',
        target."is_deleted" = 0
WHEN NOT MATCHED THEN
    INSERT
    (
        "pkid", "api_project_name", "accept_language", "name", "value",
        "description", "created_by", "created_date", "created_host", "is_deleted"
    )
    VALUES
    (
        source.new_pkid, source.api_project_name, source.accept_language,
        source.message_name, source.message_value, NULL, 'system',
        CURRENT_TIMESTAMP, 'localhost', 0
    );


COMMIT;


MERGE INTO NTT_PARAMETER."GlobalMessage" target
USING
(
    SELECT
        messages.*,
        (SELECT NVL(MAX("pkid"), 0) FROM NTT_PARAMETER."GlobalMessage")
            + ROW_NUMBER() OVER (ORDER BY messages.accept_language) AS new_pkid
    FROM
    (
        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'en-US' AS accept_language,
            'SCENARIO_NO_REPAYMENT_RATE_LABEL' AS message_name,
            'No Repayment Rate' AS message_value
        FROM DUAL

        UNION ALL

        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'id-ID' AS accept_language,
            'SCENARIO_NO_REPAYMENT_RATE_LABEL' AS message_name,
            'Tanpa Repayment Rate' AS message_value
        FROM DUAL
    ) messages
) source
ON
(
    target."accept_language" = source.accept_language
    AND target."name" = source.message_name
)
WHEN MATCHED THEN
    UPDATE SET
        target."api_project_name" = source.api_project_name,
        target."value" = source.message_value,
        target."description" = NULL,
        target."updated_by" = 'system',
        target."updated_date" = CURRENT_TIMESTAMP,
        target."updated_host" = 'localhost',
        target."is_deleted" = 0
WHEN NOT MATCHED THEN
    INSERT
    (
        "pkid", "api_project_name", "accept_language", "name", "value",
        "description", "created_by", "created_date", "created_host", "is_deleted"
    )
    VALUES
    (
        source.new_pkid, source.api_project_name, source.accept_language,
        source.message_name, source.message_value, NULL, 'system',
        CURRENT_TIMESTAMP, 'localhost', 0
    );


COMMIT;


MERGE INTO NTT_PARAMETER."GlobalMessage" target
USING
(
    SELECT
        messages.*,
        (SELECT NVL(MAX("pkid"), 0) FROM NTT_PARAMETER."GlobalMessage")
            + ROW_NUMBER() OVER (ORDER BY messages.accept_language) AS new_pkid
    FROM
    (
        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'en-US' AS accept_language,
            'REPAYMENT_RATE_PERCENTAGE_REQUIRED' AS message_name,
            'Repayment rate percentage must have value!' AS message_value
        FROM DUAL

        UNION ALL

        SELECT
            'Impairment, PSAK413_Impairment' AS api_project_name,
            'id-ID' AS accept_language,
            'REPAYMENT_RATE_PERCENTAGE_REQUIRED' AS message_name,
            'Persentase repayment rate harus memiliki nilai!' AS message_value
        FROM DUAL
    ) messages
) source
ON
(
    target."accept_language" = source.accept_language
    AND target."name" = source.message_name
)
WHEN MATCHED THEN
    UPDATE SET
        target."api_project_name" = source.api_project_name,
        target."value" = source.message_value,
        target."description" = NULL,
        target."updated_by" = 'system',
        target."updated_date" = CURRENT_TIMESTAMP,
        target."updated_host" = 'localhost',
        target."is_deleted" = 0
WHEN NOT MATCHED THEN
    INSERT
    (
        "pkid", "api_project_name", "accept_language", "name", "value",
        "description", "created_by", "created_date", "created_host", "is_deleted"
    )
    VALUES
    (
        source.new_pkid, source.api_project_name, source.accept_language,
        source.message_name, source.message_value, NULL, 'system',
        CURRENT_TIMESTAMP, 'localhost', 0
    );


COMMIT;
