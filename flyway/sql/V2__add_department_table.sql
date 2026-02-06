-- =============================================
-- Migration: V2__add_department_table.sql
-- Description: Add Department table
-- Database: Oracle 21.3.0.0
-- Schema: NTT_RISK_MODELLING
-- =============================================

-- Create Department table
CREATE TABLE NTT_RISK_MODELLING."Department" (
    "DepartmentId" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "DepartmentCode" VARCHAR2(50) NOT NULL,
    "DepartmentName" VARCHAR2(255) NOT NULL,
    "Description" VARCHAR2(500),
    "ManagerId" NUMBER,
    "IsActive" NUMBER(1) DEFAULT 1,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index
CREATE INDEX NTT_RISK_MODELLING."idx_Department_Code" 
    ON NTT_RISK_MODELLING."Department"("DepartmentCode");

-- Add Foreign Key from Employee to Department
ALTER TABLE NTT_RISK_MODELLING."Employee" 
    ADD "DepartmentId" NUMBER;

ALTER TABLE NTT_RISK_MODELLING."Employee"
    ADD CONSTRAINT "fk_Employee_Department"
    FOREIGN KEY ("DepartmentId")
    REFERENCES NTT_RISK_MODELLING."Department"("DepartmentId");

-- Insert sample data
INSERT INTO NTT_RISK_MODELLING."Department" ("DepartmentCode", "DepartmentName", "Description")
VALUES ('IT', 'Information Technology', 'IT Department');

INSERT INTO NTT_RISK_MODELLING."Department" ("DepartmentCode", "DepartmentName", "Description")
VALUES ('HR', 'Human Resources', 'HR Department');

INSERT INTO NTT_RISK_MODELLING."Department" ("DepartmentCode", "DepartmentName", "Description")
VALUES ('FIN', 'Finance', 'Finance Department');

COMMIT;