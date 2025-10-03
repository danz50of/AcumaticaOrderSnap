SELECT *
FROM dbo.vw_OrderMetrics
ORDER BY SnapshotDate DESC;

SELECT SUM(DeletedTotal) AS DeletedThisMonth
FROM dbo.vw_OrderMetrics
WHERE YEAR(SnapshotDate) = YEAR(GETDATE())
  AND MONTH(SnapshotDate) = MONTH(GETDATE());

select * from OrderDelta;

select * from OrderSnapshot;