-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_CUSTOM_REPORT
-- Description: Sample table for NTT_CUSTOM_REPORT schema
-- =============================================

CREATE TABLE NTT_CUSTOM_REPORT."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
