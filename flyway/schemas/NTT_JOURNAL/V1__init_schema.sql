-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_JOURNAL
-- Description: Sample table for NTT_JOURNAL schema
-- =============================================

CREATE TABLE NTT_JOURNAL."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
