# Flyway Database Migration - Multi Schema

Dokumentasi lengkap untuk mengelola database migration menggunakan Flyway dengan multiple schema.

---

## 📋 Daftar Schema

| No | Schema |
|----|--------|
| 1 | `NTT_USER` |
| 2 | `NTT_APPROVAL` |
| 3 | `NTT_AUDIT` |
| 4 | `NTT_CUSTOM_REPORT` |
| 5 | `NTT_DATA_MANAGENENT` |
| 6 | `NTT_EMAIL_NOTIFICATION` |
| 7 | `NTT_FILE_MANAGER` |
| 8 | `NTT_HANGFIRE` |
| 9 | `NTT_JOURNAL` |
| 10 | `NTT_PARAMETER` |
| 11 | `NTT_PLATFORM_SETTING` |
| 12 | `NTT_PSAK413_IMPAIRMENT` |
| 13 | `NTT_RISK_MODELLING` |
| 14 | `NTT_WORKFLOW` |

---

## 🗄️ Konfigurasi Database

| Property | Value |
|----------|-------|
| Host | `oracle-config.bsi.regla.cloud` |
| Port | `1521` |
| Service Name | `REGLA_DEV_BSI_CONFIG` |
| Username | `system` |
| DB Version | Oracle DB Enterprise 21.3.0.0 |

---

## 📁 Struktur Project

```
flaway/
├── .github/
│   └── workflows/
│       └── flyway.yml
├── flyway/
│   ├── flyway.conf
│   ├── README.md
│   └── schemas/
│       ├── NTT_USER/
│       │   ├── V1__init_schema.sql
│       │   └── V2__xxx.sql
│       ├── NTT_APPROVAL/
│       │   ├── V1__init_schema.sql
│       │   └── V2__xxx.sql
│       ├── NTT_AUDIT/
│       ├── NTT_CUSTOM_REPORT/
│       ├── NTT_DATA_MANAGENENT/
│       ├── NTT_EMAIL_NOTIFICATION/
│       ├── NTT_FILE_MANAGER/
│       ├── NTT_HANGFIRE/
│       ├── NTT_JOURNAL/
│       ├── NTT_PARAMETER/
│       ├── NTT_PLATFORM_SETTING/
│       ├── NTT_PSAK413_IMPAIRMENT/
│       ├── NTT_RISK_MODELLING/
│       └── NTT_WORKFLOW/
└── .gitignore
```

---

## 🐳 Perintah Docker Lengkap

### 📊 Cek Status Migration (INFO)

**NTT_USER:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_USER:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_USER info
```

**NTT_APPROVAL:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_APPROVAL:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_APPROVAL info
```

**NTT_AUDIT:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_AUDIT:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_AUDIT info
```

**NTT_CUSTOM_REPORT:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_CUSTOM_REPORT:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_CUSTOM_REPORT info
```

**NTT_DATA_MANAGENENT:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_DATA_MANAGENENT:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_DATA_MANAGENENT info
```

**NTT_EMAIL_NOTIFICATION:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_EMAIL_NOTIFICATION:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_EMAIL_NOTIFICATION info
```

**NTT_FILE_MANAGER:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_FILE_MANAGER:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_FILE_MANAGER info
```

**NTT_HANGFIRE:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_HANGFIRE:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_HANGFIRE info
```

**NTT_JOURNAL:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_JOURNAL:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_JOURNAL info
```

**NTT_PARAMETER:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_PARAMETER:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_PARAMETER info
```

**NTT_PLATFORM_SETTING:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_PLATFORM_SETTING:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_PLATFORM_SETTING info
```

**NTT_PSAK413_IMPAIRMENT:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_PSAK413_IMPAIRMENT:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_PSAK413_IMPAIRMENT info
```

**NTT_RISK_MODELLING:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_RISK_MODELLING:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING info
```

**NTT_WORKFLOW:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_WORKFLOW:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_WORKFLOW info
```

---

## 🚀 Jalankan Migration

### Template Perintah

```powershell
docker run --rm -v ${PWD}/flyway/schemas/{SCHEMA_NAME}:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas={SCHEMA_NAME} -baselineOnMigrate=true migrate
```

Ganti `{SCHEMA_NAME}` dengan nama schema yang diinginkan.

---

### Contoh: Migrate NTT_RISK_MODELLING

**Semua Versi:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_RISK_MODELLING:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true migrate
```

**Sampai V1:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_RISK_MODELLING:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true -target=1 migrate
```

**Sampai V2:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_RISK_MODELLING:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true -target=2 migrate
```

---

### Contoh: Migrate NTT_USER

**Semua Versi:**
```powershell
docker run --rm -v ${PWD}/flyway/schemas/NTT_USER:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_USER -baselineOnMigrate=true migrate
```

---

## 🔧 Repair Migration

```powershell
docker run --rm -v ${PWD}/flyway/schemas/{SCHEMA_NAME}:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas={SCHEMA_NAME} repair
```

---

## ✅ Validate Migration

```powershell
docker run --rm -v ${PWD}/flyway/schemas/{SCHEMA_NAME}:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas={SCHEMA_NAME} validate
```

---

## 📊 Ringkasan Perintah

| Aksi | Perintah |
|------|----------|
| Cek status | `info` |
| Jalankan semua | `migrate` |
| Sampai V1 | `-target=1 migrate` |
| Sampai V2 | `-target=2 migrate` |
| Validasi | `validate` |
| Perbaiki | `repair` |

---

## 📝 Membuat Migration Baru

1. Buka folder schema: `flyway/schemas/{SCHEMA_NAME}/`
2. Buat file baru: `V{VERSION}__{description}.sql`
3. Tulis SQL script dengan format:

```sql
-- =============================================
-- Migration: V2__add_new_table.sql
-- Schema: {SCHEMA_NAME}
-- Description: Add new table
-- =============================================

CREATE TABLE {SCHEMA_NAME}."NewTable" (
    "Id" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Name" VARCHAR2(255) NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
```

---

## 📋 Konvensi Penamaan

| Objek | Format | Contoh |
|-------|--------|--------|
| Schema | UPPERCASE | `NTT_RISK_MODELLING` |
| Table | PascalCase dengan quotes | `"Employee"` |
| Column | PascalCase dengan quotes | `"EmployeeId"` |
| File | `V{version}__{description}.sql` | `V1__init_schema.sql` |

---

## 🔍 Troubleshooting

### Tabel Dihapus Manual tapi Migration Tidak Jalan

Hapus record di tabel history:
```sql
DELETE FROM {SCHEMA_NAME}.flyway_schema_history;
COMMIT;
```

### Cari Tabel History

```sql
SELECT owner, table_name 
FROM all_tables 
WHERE UPPER(table_name) LIKE '%FLYWAY%';
```
