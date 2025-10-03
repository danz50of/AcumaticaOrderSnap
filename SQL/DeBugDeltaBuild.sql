DECLARE @SnapshotDate DATE       = '2024-10-01';
DECLARE @PrevSnapshotDate DATE   = '2024-09-30';

-- Baseline (Initial) records
SELECT
    'Initial' AS RecordType,
    cur.SnapshotDate,
    cur.OrderNbr,
    cur.LineNbr,
    cur.OpenQty     AS DeltaOpenQty,
    cur.UnitPrice   AS DeltaUnitPrice,
    cur.ExtPrice    AS DeltaExtPrice,
    NULL            AS DeltaPct,
    0               AS DeltaStatusChange,
    0               AS IsSignificant,
    'Baseline snapshot' AS Notes
FROM dbo.OrderSnapshot cur
WHERE cur.SnapshotDate = @SnapshotDate

UNION ALL

-- Delta comparison records
SELECT
    'Delta' AS RecordType,
    @SnapshotDate AS SnapshotDate,
    COALESCE(cur.OrderNbr, prev.OrderNbr) AS OrderNbr,
    COALESCE(cur.LineNbr, prev.LineNbr)   AS LineNbr,
    ISNULL(cur.OpenQty, 0)   - ISNULL(prev.OpenQty, 0)   AS DeltaOpenQty,
    ISNULL(cur.UnitPrice, 0) - ISNULL(prev.UnitPrice, 0) AS DeltaUnitPrice,
    ISNULL(cur.ExtPrice, 0)  - ISNULL(prev.ExtPrice, 0)  AS DeltaExtPrice,
    CASE WHEN ISNULL(prev.ExtPrice, 0) <> 0
         THEN ((ISNULL(cur.ExtPrice, 0) - ISNULL(prev.ExtPrice, 0)) / ISNULL(prev.ExtPrice, 0)) * 100
         ELSE NULL END AS DeltaPct,
    CASE WHEN ISNULL(cur.OrderStatus, '') <> ISNULL(prev.OrderStatus, '') THEN 1 ELSE 0 END AS DeltaStatusChange,
    CASE 
        WHEN ABS(ISNULL(cur.ExtPrice, 0) - ISNULL(prev.ExtPrice, 0)) > 1000 
             OR ISNULL(cur.OrderStatus, '') <> ISNULL(prev.OrderStatus, '')
             OR ISNULL(cur.OpenQty, 0) <> ISNULL(prev.OpenQty, 0)
        THEN 1 ELSE 0 
    END AS IsSignificant,
    CASE 
        WHEN prev.OrderNbr IS NULL THEN 'NewLine'
        WHEN cur.OrderNbr IS NULL THEN 'DeletedLine'
        WHEN ISNULL(cur.OrderStatus, '') <> ISNULL(prev.OrderStatus, '') THEN 'StatusChange'
        ELSE 'Modified'
    END AS Notes
FROM dbo.OrderSnapshot cur
FULL OUTER JOIN dbo.OrderSnapshot prev
  ON cur.OrderNbr = prev.OrderNbr
 AND cur.LineNbr  = prev.LineNbr
WHERE (cur.SnapshotDate = @SnapshotDate OR cur.SnapshotDate IS NULL)
  AND (prev.SnapshotDate = @PrevSnapshotDate OR prev.SnapshotDate IS NULL);