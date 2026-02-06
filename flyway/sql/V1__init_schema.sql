-- =============================================
-- Migration: V1__init_schema.sql
-- Description: Sample Table for NTT_RISK_MODELLING Schema
-- Database: Oracle 21.3.0.0
-- Schema: NTT_RISK_MODELLING
-- Format: NTT_RISK_MODELLING."TableName"
-- =============================================

CREATE TABLE NTT_RISK_MODELLING."Employee" (
    "EmployeeId" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "EmployeeCode" VARCHAR2(50) NOT NULL,
    "FirstName" VARCHAR2(100) NOT NULL,
    "LastName" VARCHAR2(100),
    "Email" VARCHAR2(255),
    "Department" VARCHAR2(100),
    "IsActive" NUMBER(1) DEFAULT 1,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
