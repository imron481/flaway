-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_DATA_MANAGENENT
-- Description: Sample table for NTT_DATA_MANAGENENT schema
-- =============================================

CREATE TABLE NTT_DATA_MANAGENENT."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
