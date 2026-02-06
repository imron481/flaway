-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_EMAIL_NOTIFICATION
-- Description: Sample table for NTT_EMAIL_NOTIFICATION schema
-- =============================================

CREATE TABLE NTT_EMAIL_NOTIFICATION."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
