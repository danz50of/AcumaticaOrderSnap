# 📘 Project Summary: Sales Order Delta Tracker  *(Updated 10-02-2025 5:30AM)*  
**Database**: `Peerless_Order_History`  
**Purpose**: Track daily changes in open sales orders using snapshot ingestion and delta logic.

---

## ✅ Phase 1: Planning & Architecture  
- [x] Define snapshot schema
- [x] Choose storage target (SQL Server)
- [x] Estimate data volume and retention
- [x] Design database creation parameters
- [x] Set database owner and permissions

 ** Complete **

---

## ✅ Phase 2: Acumatica Integration  
- [x] Build Generic Inquiry (GI) for open orders  
- [x] Confirm field mappings and data dictionary  
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
- [x] Define delta comparison rules  
- [x] Build stored procedure to compare snapshots (`PopulateOrderDelta`)  
- [x] Flag significant changes (via `IsSignificant` logic)  
- [x] Annotate deletions in previous snapshot (`Notes = 'Deleted'`)  
- [ ] Validate delta accuracy against test data  
- [ ] Confirm behavior for shipped orders vs modified orders  
- [ ] Finalize lifecycle traceability (NewLine, Modified, DeletedLine)

---

## ⏳ Phase 5: Reporting & Visualization  
- [x] Create summary view `vw_OrderMetrics`  
- [ ] Create line-level drill-through view  
- [ ] Design dashboard spec (Power BI, Metabase)  
- [ ] Build visuals: KPI cards, trend charts, deletion analysis  
- [ ] Export delta results to CSV or API

---

## 🏁 Suggested Sprint Breakdown

### 🔹 Sprint 1: Snapshot Ingestion Pipeline  
- Finalize field mappings from GI  
- Build SQL ingestion script  
- Automate daily snapshot load into `OrderSnapshot`

### 🔹 Sprint 2: Delta Comparison Engine  
- Finalize delta logic and thresholds  
- Deploy `PopulateOrderDelta` with logging and deletion handling  
- Validate with 2–3 days of sample data  
- Confirm behavior for shipped orders

### 🔹 Sprint 3: Reporting & Archival  
- Deploy `vw_OrderMetrics`  
- Create drill-through view for line-level analysis  
- Design archival strategy for old snapshots  
- Build dashboard layer (Power BI or Excel)

---

## 📌 Today's Priorities (10-02-2025)

1. ✅ Deploy `vw_OrderMetrics` successfully  
2. 🧪 Run analysis on test data and validate delta logic  
3. 📦 Ship one order and observe delta behavior  
4. 🧹 Confirm no false positives from shipped status  
5. 📐 Finalize all SQL objects for reporting baseline


