-- =============================================
-- Migration: V2__add_department_table.sql
-- Description: Add Department table
-- Database: Oracle 21.3.0.0
-- Schema: ntt_risk_modelling
-- =============================================

-- Create Department table
CREATE TABLE ntt_risk_modelling."Department" (
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
CREATE INDEX ntt_risk_modelling."idx_Department_Code" 
    ON ntt_risk_modelling."Department"("DepartmentCode");

-- Add Foreign Key from Employee to Department
ALTER TABLE ntt_risk_modelling."Employee" 
    ADD "DepartmentId" NUMBER;

ALTER TABLE ntt_risk_modelling."Employee"
    ADD CONSTRAINT "fk_Employee_Department"
    FOREIGN KEY ("DepartmentId")
    REFERENCES ntt_risk_modelling."Department"("DepartmentId");

-- Insert sample data
INSERT INTO ntt_risk_modelling."Department" ("DepartmentCode", "DepartmentName", "Description")
VALUES ('IT', 'Information Technology', 'IT Department');

INSERT INTO ntt_risk_modelling."Department" ("DepartmentCode", "DepartmentName", "Description")
VALUES ('HR', 'Human Resources', 'HR Department');

INSERT INTO ntt_risk_modelling."Department" ("DepartmentCode", "DepartmentName", "Description")
VALUES ('FIN', 'Finance', 'Finance Department');

COMMIT;