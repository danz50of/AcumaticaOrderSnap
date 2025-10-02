# 📘 Project Summary: Sales Order Delta Tracker  9-30-2025 3:33PM
**Database**: `Peerless_Order_History`  
**Purpose**: Track daily changes in open sales orders using snapshot ingestion and delta logic.

---

## ✅ Phase 1: Planning & Architecture

- [x] Define snapshot schema  
- [x] Choose storage target (SQL Server)  
- [x] Estimate data volume and retention  
- [x] Design database creation parameters  
- [x] Set database owner and permissions  

---

## ✅ Phase 2: Acumatica Integration

- [x] Build Generic Inquiry (GI) for open orders  
- [ ] Confirm field mappings and data dictionary  
- [x] Export daily snapshot to CSV or direct SQL  
- [ ] Automate snapshot extraction (scheduled job)  

---

## ✅ Phase 3: Snapshot & Delta Schema

- [x] Design `OrderSnapshot` table schema  
- [x] Design `OrderDelta` table schema  
- [x] Create tables in Peerless_Order_History  
- [x] Add indexing for analytics  
- [ ] Partitioning or archival strategy  

---

## ⏳ Phase 4: Delta Logic & Comparison

- [ ] Define delta comparison rules  
- [X] Build stored procedure or script to compare snapshots  
- [ ] Flag significant changes  
- [ ] Annotate or override deltas manually  

---

## ⏳ Phase 5: Reporting & Visualization

- [ ] Design dashboard spec (Power BI, Metabase)  
- [ ] Build views or materialized tables for reporting  
- [ ] Export delta results to CSV or API  

---

## 🏁 Suggested Sprint Breakdown

### 🔹 Sprint 1: Snapshot Ingestion Pipeline
- Finalize field mappings from GI  
- Build Python or SQL ingestion script  
- Automate daily snapshot load into `OrderSnapshot`  

### 🔹 Sprint 2: Delta Comparison Engine
- Define delta logic and thresholds  
- Build stored procedure or Python script to populate `OrderDelta`  
- Test with 2–3 days of sample data  

### 🔹 Sprint 3: Reporting & Archival
- Create views for dashboard queries  
- Design archival strategy for old snapshots  
- Build export or visualization layer  