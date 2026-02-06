# Flyway Database Migration

Dokumentasi lengkap untuk mengelola database migration menggunakan Flyway.

---

## ?? Daftar Isi

1. [Konfigurasi Database](#konfigurasi-database)
2. [Struktur Project](#struktur-project)
3. [Perintah Docker Lengkap](#perintah-docker-lengkap)
4. [Membuat Migration Baru](#membuat-migration-baru)
5. [Konvensi Penamaan File](#konvensi-penamaan-file)
6. [Troubleshooting](#troubleshooting)

---

## ??? Konfigurasi Database

| Property | Value |
|----------|-------|
| Host | `oracle-config.bsi.regla.cloud` |
| Port | `1521` |
| Service Name | `REGLA_DEV_BSI_CONFIG` |
| Schema | `NTT_RISK_MODELLING` |
| Username | `system` |
| DB Version | Oracle DB Enterprise 21.3.0.0 |

---

## ?? Struktur Project

```
flaway/
??? .github/
?   ??? workflows/
?       ??? flyway.yml
??? flyway/
?   ??? flyway.conf
?   ??? README.md
?   ??? sql/
?       ??? V1__init_schema.sql
?       ??? V2__add_department_table.sql
?       ??? V3__xxx.sql (dst)
??? .gitignore
```

---

## ?? Perintah Docker Lengkap

### ?? Cek Status Migration (INFO)

Melihat versi migration yang sudah dijalankan dan yang pending:

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING info
```

---

### ?? Jalankan Semua Migration (MIGRATE ALL)

Menjalankan semua migration dari versi awal sampai terbaru:

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true migrate
```

---

### 1?? Jalankan Sampai V1 Saja

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true -target=1 migrate
```

---

### 2?? Jalankan Sampai V2 (V1 + V2)

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true -target=2 migrate
```

---

### 3?? Jalankan Sampai V3 (V1 + V2 + V3)

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING -baselineOnMigrate=true -target=3 migrate
```

---

### ? Validate Migration

Memastikan migration files valid tanpa menjalankan:

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING validate
```

---

### ?? Repair Migration History

Memperbaiki migration yang gagal atau checksum error:

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING repair
```

---

### ?? Baseline

Membuat baseline untuk database yang sudah ada:

```powershell
docker run --rm -v ${PWD}/flyway/sql:/flyway/sql flyway/flyway:10.0.0 -url="jdbc:oracle:thin:@//oracle-config.bsi.regla.cloud:1521/REGLA_DEV_BSI_CONFIG" -user="system" -password="Gp8USXo48nTCIb7U1kSgsB2" -schemas=NTT_RISK_MODELLING baseline
```

---

## ?? Ringkasan Perintah

| Aksi | Perintah | Keterangan |
|------|----------|------------|
| Cek status | `info` | Lihat versi yang sudah/belum dijalankan |
| Jalankan semua | `migrate` | Jalankan semua pending migration |
| Sampai V1 | `-target=1 migrate` | Hanya V1 |
| Sampai V2 | `-target=2 migrate` | V1 + V2 |
| Sampai V3 | `-target=3 migrate` | V1 + V2 + V3 |
| Validasi | `validate` | Cek file valid tanpa execute |
| Perbaiki | `repair` | Fix migration gagal |
| Baseline | `baseline` | Set baseline version |

---

## ?? Membuat Migration Baru

### Langkah-langkah

1. Buat file SQL baru di folder `flyway/sql/`
2. Gunakan format nama: `V{VERSION}__{DESKRIPSI}.sql`
3. Tulis SQL script
4. Test dengan `info` untuk memastikan terdeteksi
5. Jalankan `migrate`

### Contoh: Membuat V3

**File:** `flyway/sql/V3__add_product_table.sql`

```sql
-- =============================================
-- Migration: V3__add_product_table.sql
-- Description: Add Product table
-- =============================================

CREATE TABLE NTT_RISK_MODELLING."Product" (
    "ProductId" NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "ProductCode" VARCHAR2(50) NOT NULL,
    "ProductName" VARCHAR2(255) NOT NULL,
    "Price" NUMBER(18,2),
    "IsActive" NUMBER(1) DEFAULT 1,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
```

---

## ?? Konvensi Penamaan File

### Format

```
V{VERSION}__{DESCRIPTION}.sql
```

| Bagian | Penjelasan | Contoh |
|--------|------------|--------|
| `V` | Prefix wajib (Versioned) | `V` |
| `{VERSION}` | Nomor versi | `1`, `2`, `3` |
| `__` | Double underscore (pemisah) | `__` |
| `{DESCRIPTION}` | Deskripsi dengan underscore | `init_schema` |
| `.sql` | Extension file | `.sql` |

### Contoh Nama File yang Valid

| File | Versi | Deskripsi |
|------|-------|-----------|
| `V1__init_schema.sql` | 1 | Initial schema |
| `V2__add_department_table.sql` | 2 | Add department table |
| `V3__add_product_table.sql` | 3 | Add product table |
| `V4__add_index_employee.sql` | 4 | Add index to employee |
| `V5__alter_table_add_column.sql` | 5 | Alter table |

### Format Nama Objek Database

| Objek | Format | Contoh |
|-------|--------|--------|
| Schema | UPPERCASE | `NTT_RISK_MODELLING` |
| Table | PascalCase dengan quotes | `"Employee"` |
| Column | PascalCase dengan quotes | `"EmployeeId"` |
| Index | `idx_Table_Column` | `"idx_Employee_Code"` |
| Foreign Key | `fk_Table_RefTable` | `"fk_Employee_Department"` |

---

## ?? Troubleshooting

### Error: ORA-12505 (SID not found)

**Penyebab:** Format URL salah (menggunakan SID bukan SERVICE_NAME)

**Solusi:** Gunakan format SERVICE_NAME:
```
jdbc:oracle:thin:@//HOST:PORT/SERVICE_NAME
```

### Error: Schema history table does not exist

**Penyebab:** Pertama kali menjalankan di schema yang sudah ada isinya

**Solusi:** Tambahkan parameter `-baselineOnMigrate=true`

### Error: Migration checksum mismatch

**Penyebab:** File migration diubah setelah dijalankan

**Solusi:** 
1. Jangan ubah file migration yang sudah dijalankan
2. Atau jalankan `repair` (hanya untuk development)

### Migration Tidak Terdeteksi

**Penyebab:** 
1. Nama file tidak sesuai format
2. File tidak di folder yang benar

**Solusi:**
1. Pastikan nama file: `V{number}__{description}.sql`
2. Pastikan file di folder `flyway/sql/`

### Tabel Dihapus Manual tapi Migration Tidak Jalan

**Penyebab:** History di `flyway_schema_history` masih mencatat migration sudah dijalankan

**Solusi:** Hapus record di tabel history:
```sql
DELETE FROM NTT_RISK_MODELLING.flyway_schema_history;
COMMIT;
```

### Schema Terbuat Dobel (Lowercase & Uppercase)

**Penyebab:** Oracle case-sensitive untuk nama schema

**Solusi:** Gunakan UPPERCASE untuk parameter `-schemas`:
```
-schemas=NTT_RISK_MODELLING
```

---

## ?? Bantuan

Jika ada pertanyaan atau masalah, hubungi tim DevOps.
