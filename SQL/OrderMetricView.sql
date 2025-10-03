CREATE OR ALTER VIEW dbo.vw_OrderMetrics
AS
WITH DailyTotals AS (
    SELECT 
        SnapshotDate,
        SUM(OpenQty * UnitPrice) AS OpenOrderTotal
    FROM dbo.OrderSnapshot
    GROUP BY SnapshotDate
),
Deleted AS (
    SELECT 
        SnapshotDate,
        SUM(DeltaExtPrice) AS DeletedTotal,
        COUNT(*) AS DeletedCount
    FROM dbo.OrderDelta
    WHERE Notes = 'DeletedLine'
    GROUP BY SnapshotDate
),
Modified AS (
    SELECT 
        SnapshotDate,
        SUM(DeltaExtPrice) AS ModifiedTotal,
        COUNT(*) AS ModifiedCount
    FROM dbo.OrderDelta
    WHERE Notes IN ('Modified','StatusChange')
    GROUP BY SnapshotDate
),
NewOrders AS (
    SELECT 
        SnapshotDate,
        SUM(DeltaExtPrice) AS NewOrderTotal,
        COUNT(*) AS NewOrderCount
    FROM dbo.OrderDelta
    WHERE Notes = 'NewLine'
    GROUP BY SnapshotDate
)
SELECT
    d.SnapshotDate,
    d.OpenOrderTotal AS TodayOpenOrderTotal,
    LAG(d.OpenOrderTotal) OVER (ORDER BY d.SnapshotDate) AS YesterdayOpenOrderTotal,
    d.OpenOrderTotal 
      - LAG(d.OpenOrderTotal) OVER (ORDER BY d.SnapshotDate) AS DiffFromYesterday,
    ISNULL(del.DeletedTotal, 0)     AS DeletedTotal,
    ISNULL(del.DeletedCount, 0)     AS DeletedCount,
    ISNULL(mod.ModifiedTotal, 0)    AS ModifiedTotal,
    ISNULL(mod.ModifiedCount, 0)    AS ModifiedCount,
    ISNULL(nw.NewOrderTotal, 0)     AS NewOrderTotal,
    ISNULL(nw.NewOrderCount, 0)     AS NewOrderCount
FROM DailyTotals d
LEFT JOIN Deleted  del ON d.SnapshotDate = del.SnapshotDate
LEFT JOIN Modified mod ON d.SnapshotDate = mod.SnapshotDate
LEFT JOIN NewOrders nw ON d.SnapshotDate = nw.SnapshotDate;
GO