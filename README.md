# Modern SQL Data Warehouse & DataOps Project 🚀

Welcome to the **Data Warehouse & DataOps** project repository! This repository demonstrates an enterprise-grade, modern Medallion data warehousing solution built using dbt, SQL Server (or a local PostgreSQL container), and continuous integration (CI) workflows. 

Designed to scale to 2026 industry standards, the project shifts database management from procedural stored procedures to a declarative, dry, and testable analytics engineering pipeline.

---

## 🏗️ Architecture Overview

The pipeline leverages a three-layer **Medallion Architecture**:
1. **Bronze Layer (Raw Source Data):** Direct raw data loaded from CSV files (CRM and ERP source systems).
2. **Silver Layer (Staging & Cleansing):** Cleanses, standardizes casing, normalizes codes, handles date conversions, and deduplicates records. Materialized as dbt views.
3. **Gold Layer (Analytics Marts):** Re-models clean data into a Star Schema (fact and dimensions) with physical materializations and temporal (SCD Type 2) joins.

```mermaid
graph TD
    subgraph Bronze Layer [Raw Ingestion]
        B1[CRM Customer Info]
        B2[CRM Product Info]
        B3[CRM Sales Details]
        B4[ERP Customer Details]
        B5[ERP Customer Locations]
        B6[ERP Product Category]
    end

    subgraph Silver Layer [Staging & Cleansing]
        S1[stg_crm_cust_info]
        S2[stg_crm_prd_info]
        S3[stg_crm_sales_details]
        S4[stg_erp_cust_az12]
        S5[stg_erp_loc_a101]
        S6[stg_erp_px_cat_g1v2]
    end

    subgraph Gold Layer [Marts & Dimensional Model]
        G1[(dim_customers)]
        G2[(dim_products)]
        G3[(fact_sales)]
    end

    B1 --> S1 --> G1
    B4 --> S4 --> G1
    B5 --> S5 --> G1
    
    B2 --> S2 --> G2
    B6 --> S6 --> G2
    
    B3 --> S3 --> G3
    G1 --> G3
    G2 --> G3
```

---

## 📊 Gold Layer ER Diagram (Star Schema)

The analytical data is structured into a optimized star schema:

```mermaid
erDiagram
    dim_customers ||--o{ fact_sales : "customer_key"
    dim_products ||--o{ fact_sales : "product_key"
    
    fact_sales {
        string order_number PK
        string product_key FK
        string customer_key FK
        date order_date
        date shipping_date
        date due_date
        int sales_amount
        int quantity
        int price
    }
    
    dim_customers {
        string customer_key PK
        int customer_id
        string customer_number
        string first_name
        string last_name
        string country
        string marital_status
        string gender
        date birthdate
    }
    
    dim_products {
        string product_key PK
        int product_id
        string product_number
        string product_name
        string category
        string subcategory
        int cost
        string product_line
        date valid_from
        date valid_to
        int is_current
    }
```

---

## 🛠️ Project Structure

The project has been refactored to align with standard analytics engineering structures:

```text
├── .github/
│   └── workflows/
│       └── ci.yml           # Automated CI tests pipeline
├── .sqlfluff                # Formatter & linter configuration
├── README.md                # Documentation
├── docker-compose.yml       # Local PostgreSQL sandbox configuration
├── dbt_project.yml          # dbt project configurations
├── profiles.yml             # dbt adapter database configuration
├── models/
│   ├── staging/             # Raw ingestion cleansing models
│   │   ├── src_sources.yml
│   │   ├── stg_crm_cust_info.sql
│   │   ├── stg_crm_prd_info.sql
│   │   ├── stg_crm_sales_details.sql
│   │   ├── stg_erp_cust_az12.sql
│   │   ├── stg_erp_loc_a101.sql
│   │   ├── stg_erp_px_cat_g1v2.sql
│   │   └── schema.yml       # Declarative staging tests
│   └── marts/               # Final Star Schema (fact & dimension tables)
│       ├── dim_customers.sql
│       ├── dim_products.sql
│       ├── fact_sales.sql
│       └── marts.yml        # Declarative marts tests & constraints
└── macros/
    └── clean_gender.sql     # Reusable cleaning logic
```

---

## 🚀 Quickstart & Setup

### Prerequisites
- [Docker & Docker Compose](https://www.docker.com/)
- [Python 3.10+](https://www.python.org/)

### 1. Spin up Local Database Sandbox
Launch the isolated database container running PostgreSQL:
```bash
docker-compose up -d
```

### 2. Install dbt and Dependencies
Create a virtual environment and install dbt packages:
```bash
python -m venv venv
source venv/Scripts/activate # On Windows: venv\Scripts\activate
pip install dbt-postgres sqlfluff-templater-dbt
```

### 3. Run Pipeline and Data Quality Tests
Compile the configurations, execute the incremental pipeline, and trigger assertions:
```bash
dbt deps     # Fetch packages
dbt run      # Materialize staging views & physical gold tables
dbt test     # Run unique, null, and relationship validations
```

### 4. Code Standards & Linting
Validate SQL style constraints against `.sqlfluff` configs:
```bash
sqlfluff lint models/
```
