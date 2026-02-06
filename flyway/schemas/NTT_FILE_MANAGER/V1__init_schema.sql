-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_FILE_MANAGER
-- Description: Sample table for NTT_FILE_MANAGER schema
-- =============================================

CREATE TABLE NTT_FILE_MANAGER."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
