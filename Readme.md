# 🧠 OrderDelta Dashboard

A modular, real-time visualization engine for daily order snapshots—built to scale from standalone HTML/JS to embedded Acumatica ASPX screens.

---

## 🚀 Project Goals

- Visualize external SQL snapshot data using Chart.js and DataTables
- Expose data via ASP.NET Web API
- Build a standalone dashboard (crawl)
- Host and secure the dashboard (walk)
- Embed into Acumatica as RSOD1000 (run)

---

## 🐢 Crawl Phase

- ✅ API endpoint: `/api/orderdelta`
- ✅ JS dashboard: `index.html`
- ✅ Chart.js + DataTables integration
- 🔜 Add filters and export buttons

---

## 🚶 Walk Phase

- Host dashboard via IIS or Azure
- Secure API with token auth
- Modularize JS and CSS
- Add drilldowns and user filters

---

## 🏃 Run Phase

- Scaffold RSOD1000.aspx in Acumatica
- Embed dashboard JS
- Link via Site Map
- Validate rendering and interactivity

---

## 🗂️ Folder Structure