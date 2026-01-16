graph TD
    %% Global Risk Pool
    A[<b>510 Total Risk Pool</b><br/>Invoices with matching ID + Supplier]
    style A fill:#1e293b,stroke:#0f172a,color:#fff

    A -->|Exact Matches| B(<b>410 Strict Duplicates</b><br/>Identical across all fields)
    style B fill:#ecfdf5,stroke:#059669,color:#065f46

    A -->|Inconsistent Metadata| C{<b>100 Fuzzy Duplicates</b><br/>Requires Finance Review}
    style C fill:#fffbeb,stroke:#d97706,color:#92400e

    %% Fuzzy Breakdown
    C --> D[<b>84 Amount Mismatches</b><br/>High Risk: Potential Cash Leakage]
    style D fill:#fff1f2,stroke:#e11d48,color:#9f1239

    C --> E[<b>16 Metadata Drift</b><br/>Creator/Date Variations]
    style E fill:#f0f9ff,stroke:#0284c7,color:#075985

    %% Callouts
    subgraph Legend
    B --- B_note[Automated Cleanup]
    D --- D_note[Manual Audit Priority]
    end
