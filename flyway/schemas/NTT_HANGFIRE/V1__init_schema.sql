-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_HANGFIRE
-- Description: Sample table for NTT_HANGFIRE schema
-- =============================================

CREATE TABLE NTT_HANGFIRE."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
