-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_PSAK413_IMPAIRMENT
-- Description: Sample table for NTT_PSAK413_IMPAIRMENT schema
-- =============================================

CREATE TABLE NTT_PSAK413_IMPAIRMENT."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
