-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_USER
-- Description: Sample table for NTT_USER schema
-- =============================================

CREATE TABLE NTT_USER."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
