-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_PARAMETER
-- Description: Sample table for NTT_PARAMETER schema
-- =============================================

CREATE TABLE NTT_PARAMETER."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
