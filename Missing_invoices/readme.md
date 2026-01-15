## Identify fields that could be related with the exclusion logic
- [Get value counts per col and drop cols with null values](https://colab.research.google.com/drive/1WG04q6OUm7LDRnIf8jMdyn0gyJqt_Iqc?usp=sharing)
- From a given list of target variables see if there is any case that is correlated with a high proportion of missing invoices.
  - For instance, invoices received via API or CXML, Tier 3 suppliers, some requester ids or a specific list of suppliers are correlated with a high proportion of missing invoices:
    - Integration Channels (P1): Automated transmissions via cXML (100% missing) and API (77% missing) are largely absent from the manual report.

    - High-Impact Requesters (P2): Invoices from IDs 10944 and 10727 account for 148 missing records; check for spend-category exclusions.

    - Excluded Service Vendors (P3): High-volume professional services like DLA Piper and Capterra are currently 100% missing.

    - Volume Outliers (P4): Shipping Term "0" represents the largest single gap with 303 missing invoices.

    - Payment Terms (P6): Audit Terms 10 and 13, which show an 86% and 75% discrepancy rate, respectively.

    - Currency Logic (P7): Non-standard Currencies 117 and 21 are frequently omitted compared to primary currencies.
