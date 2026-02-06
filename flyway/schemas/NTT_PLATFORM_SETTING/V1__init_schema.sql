-- =============================================
-- Migration: V1__init_schema.sql
-- Schema: NTT_PLATFORM_SETTING
-- Description: Sample table for NTT_PLATFORM_SETTING schema
-- =============================================

CREATE TABLE NTT_PLATFORM_SETTING."SampleTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
