

## 📦 Project Summary: Sales Order Delta Tracker  9-30-2025 6:30 AM

### 🧭 Phase 1: Requirements & Planning
| Task | Description |
|------|-------------|
| `Define snapshot schema` | Identify required fields (Order ID, Line Item, Qty, Unit Price, etc.) |
| `Set delta thresholds` | Define what constitutes a “significant change” (e.g., >10% value shift) |
| `Choose storage target` | Decide between local SQL vs AWS RDS for snapshot ingestion |
| `Select reporting tool` | Choose Power BI, Metabase, or other UI for delta visualization |

---

### 📤 Phase 2: Data Extraction from Acumatica
| Task | Description |
|------|-------------|
| `Build Generic Inquiry for open orders` | Filter by status, include line-level detail |
| `Configure Export Scenario` | Automate daily CSV export of GI results |
| `Secure export destination` | Save to local folder, S3 bucket, or SharePoint with access controls |
| `Test daily export job` | Validate file format, completeness, and timestamping |

---

### 🗃️ Phase 3: Data Ingestion & Storage
| Task | Description |
|------|-------------|
| `Design snapshot table schema` | Create raw ingestion table in SQL or RDS |
| `Build ingestion script` | Python, PowerShell, or Glue job to load CSV into storage |
| `Automate ingestion` | Schedule daily ETL job (cron, Task Scheduler, Lambda, etc.) |
| `Version snapshots` | Append daily data with date key for historical tracking |

---

### 🔍 Phase 4: Delta Logic & Comparison
| Task | Description |
|------|-------------|
| `Design delta comparison logic` | Compare today vs yesterday by Order ID + Line Item |
| `Build delta table` | Store computed changes (qty, value, status) with flags |
| `Validate delta accuracy` | Test edge cases (partial shipments, price edits, cancellations) |
| `Log anomalies` | Track unexpected changes or missing records for auditability |

---

### 📊 Phase 5: Reporting & Visualization
| Task | Description |
|------|-------------|
| `Connect BI tool to delta table` | Power BI, Metabase, or custom dashboard |
| `Design delta dashboard` | Show top changes, trends, filters by SKU/customer/date |
| `Configure alerts` | Optional: email or Teams alert for major changes |
| `User testing & feedback` | Validate dashboard usability and accuracy with stakeholders |

---

### 🔐 Phase 6: Security & Maintenance
| Task | Description |
|------|-------------|
| `Implement access controls` | Role-based access to storage and dashboard |
| `Encrypt sensitive data` | Use at-rest and in-transit encryption (RDS, S3, local drives) |
| `Backup strategy` | Daily snapshot backups and delta logs |
| `Document SOPs` | Write onboarding guide, troubleshooting checklist, and change log

---

## 🧱 Suggested Sprint Breakdown

| Sprint | Focus |
|--------|-------|
| **Sprint 1** | Planning, GI setup, export scenario |
| **Sprint 2** | Ingestion pipeline, snapshot table |
| **Sprint 3** | Delta logic, comparison engine |
| **Sprint 4** | Reporting dashboard, alerting |
| **Sprint 5** | Security hardening, documentation, handoff

---
