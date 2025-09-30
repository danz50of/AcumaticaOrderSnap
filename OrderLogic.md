# 🔄 Order Flow & Lifecycle Logic  
**Date**: 9-30-2025 11:17AM  
**Database**: `Peerless_Order_History`  
**Purpose**: Define the full lifecycle of a sales order line, including all terminal and transitional states, to support historical tracking and delta analysis.

---

## 🧠 Philosophy Shift

> **Capture all orders, all statuses, all changes.**  
> This ensures complete visibility into the lifecycle of every order line—from creation to fulfillment, cancellation, or deletion.

---

## 🧱 Order Lifecycle States

| State | Description | Terminal? |
|-------|-------------|-----------|
| **Open** | Order line is active and awaiting fulfillment | ❌ |
| **Credit Hold** | Temporarily blocked due to credit issues | ❌ |
| **Released from Hold** | Reinstated after credit clearance | ❌ |
| **Shipped** | Product has been fulfilled and shipped | ✅ |
| **Canceled** | Order line was canceled by user or system | ✅ |
| **Deleted** | Line was removed from the order entirely | ✅ |

---

## 📦 Delta Logic Implications

- **Shipping is a delta**: `OpenQty` drops to zero, `OrderStatus` changes to `Shipped`
- **Cancellation is a delta**: `OrderStatus` changes to `Canceled`, `OpenQty` may remain
- **Credit Hold transitions**: `OrderStatus` toggles between `Credit Hold` and `Open`
- **Deletion detection**: Line disappears from snapshot; flagged via absence

---

## 📊 Dashboard Capabilities Enabled

- % of orders shipped vs canceled vs deleted
- Time-to-ship metrics per customer, SKU, or warehouse
- Credit hold frequency and resolution time
- Historical audit trail of every order line’s journey

---

## 🛠 Implementation Notes

- **No status filter in GI**: `DZ_Order_SnapShot` must include all statuses
- **Snapshot must persist all lines**: Even if terminal
- **Delta logic must detect terminal transitions**: Shipped, canceled, deleted
- **Deleted lines require absence detection**: Compare snapshot N to N-1

---

## 🏁 Next Steps

- [ ] Confirm `DZ_Order_SnapShot` includes all statuses
- [ ] Add logic to detect deleted lines (missing from snapshot)
- [ ] Update delta comparison rules to include terminal transitions
- [ ] Define dashboard KPIs based on lifecycle states