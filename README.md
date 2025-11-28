## Data Model & Key Field Relationships

### 1. Tables Overview

| Table Name                      | Purpose                                    | Key Fields                                         |
|----------------------------------|--------------------------------------------|----------------------------------------------------|
| `COUPA_INVOICE_HEADER_BCV` (CIH) | Main invoice record (header)               | `ID`, `INVOICE_NUMBER`, `PAYMENT_DATE`, `AMOUNT_DUE` |
| `COUPA_INVOICE_LINE_BCV` (CIL)   | Line-level invoice details                 | `ID`, `INVOICE_HEADER_ID`, `CURRENCY_ID`           |
| `COUPA_EXCHANGE_RATE_BCV` (CRB)  | Stores currency exchange rates             | `FROM_CURRENCY_ID`, `TO_CURRENCY_ID`, `RATE`, `CURRENCY_CODE` |
| `COUPA_CURRENCY_BCV` (CCB)       | Reference for all currencies (not joined in query, optional) | `CODE`, `NAME`                         |

---

### 2. Table Relationships (Joins)

- **Invoice Header to Invoice Line**
  - `CIH.ID = CIL.INVOICE_HEADER_ID`
  - Each invoice header (`CIH`) may have multiple related invoice lines (`CIL`).

- **Invoice Line to Exchange Rate**
  - `CIL.CURRENCY_ID = CRB.TO_CURRENCY_ID`
  - Connects the invoice line’s currency to the corresponding exchange rate for conversion.

- **Exchange Rate to Currency Table** (optional, commented in SQL)
  - `CRB.CURRENCY_CODE = CCB.CODE`
  - Provides descriptive currency names/details.

---

### 3. Relationship Diagram

```mermaid
erDiagram
    COUPA_INVOICE_HEADER_BCV ||--o{ COUPA_INVOICE_LINE_BCV : "ID = INVOICE_HEADER_ID"
    COUPA_INVOICE_LINE_BCV   }o--|| COUPA_EXCHANGE_RATE_BCV : "CURRENCY_ID = TO_CURRENCY_ID"
    COUPA_EXCHANGE_RATE_BCV  }o--|| COUPA_CURRENCY_BCV : "CURRENCY_CODE = CODE"
