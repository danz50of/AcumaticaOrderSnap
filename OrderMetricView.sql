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
        SUM(ABS(DeltaExtPrice)) AS DeletedTotal,
        COUNT(*) AS DeletedCount
    FROM dbo.OrderDelta
    WHERE Notes = 'DeletedLine'
    GROUP BY SnapshotDate
),
Modified AS (
    SELECT 
        SnapshotDate,
        SUM(ABS(DeltaExtPrice)) AS ModifiedTotal,
        COUNT(*) AS ModifiedCount
    FROM dbo.OrderDelta
    WHERE Notes IN ('Modified','StatusChange','NewLine')
    GROUP BY SnapshotDate
)
SELECT
    d.SnapshotDate,
    d.OpenOrderTotal AS TodayOpenOrderTotal,
    LAG(d.OpenOrderTotal) OVER (ORDER BY d.SnapshotDate) AS YesterdayOpenOrderTotal,
    d.OpenOrderTotal 
      - LAG(d.OpenOrderTotal) OVER (ORDER BY d.SnapshotDate) AS DiffFromYesterday,
    ISNULL(del.DeletedTotal, 0)  AS DeletedTotal,
    ISNULL(del.DeletedCount, 0)  AS DeletedCount,
    ISNULL(mod.ModifiedTotal, 0) AS ModifiedTotal,
    ISNULL(mod.ModifiedCount, 0) AS ModifiedCount
FROM DailyTotals d
LEFT JOIN Deleted  del ON d.SnapshotDate = del.SnapshotDate
LEFT JOIN Modified mod ON d.SnapshotDate = mod.SnapshotDate;
GO