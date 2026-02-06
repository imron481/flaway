-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_AUDIT
-- Description: Sample table for NTT_AUDIT schema
-- =============================================

CREATE TABLE NTT_AUDIT."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
