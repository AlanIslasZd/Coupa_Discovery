# Flavia_Ask_Dec_5

## Objective

### Reconcile invoice data between Coupa (from Cleansed/Coupa tables in ZDP) and the “Closed Invoices NOV2025” GDrive file shared by Finance.  
Specifically:
- Identify invoices present in Coupa but missing from the GDrive file used for the WC Dashboard.
- Clarify any vendor category filters or exclusion logic that may explain the differences.

## Contents

- **missing_invoices_link.txt / spreadsheet**  
  List of invoices found in Coupa but not in the GDrive “Closed Invoices NOV2025” file.
- **reconciliation_query.sql**  
  SQL query used to extract November 2025 invoice data from Cleansed/Coupa for comparison.

## Methodology

1. Extract all invoices with `PAYMENT_DATE` in November 2025 from Cleansed/Coupa (ZDP).
2. Cross-reference with the GDrive “Closed Invoices NOV2025” file shared by Finance.
3. Output any invoices present in Coupa but missing from the GDrive file.
4. Investigate possible exclusion logic (e.g., vendor categories).
5. Share the findings and open questions with Finance (Flavia).

## Open Questions

- Was any filter or exclusion logic (such as vendor categories) applied when preparing the GDrive file?
- Is vendor category data available in Coupa, or managed elsewhere?
- Who can clarify Coupa data model for vendor categories if not directly accessible?

---

[Link to the list of invoices I found only in Coupa and are missing in GDrive](https://docs.google.com/spreadsheets/d/1LTN2y8URJMg1iiOL0lATVC7ZiCkjjhGETSXEOyi7lbs/edit?usp=sharing)
