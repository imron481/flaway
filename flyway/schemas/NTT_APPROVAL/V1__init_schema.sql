-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_APPROVAL
-- Description: Sample table for NTT_APPROVAL schema
-- =============================================

CREATE TABLE NTT_APPROVAL."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
