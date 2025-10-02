ALTER PROCEDURE dbo.PopulateOrderDelta
    @SnapshotDate DATE,
    @PrevSnapshotDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RunID INT, @RowCount INT = 0, @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        -- Log start…
        INSERT INTO dbo.OrderDeltaRunLog (...)
        VALUES (...);
        SET @RunID = SCOPE_IDENTITY();

        ----------------------------------------------------------------------
        -- 1. Modified deltas (exclude Canceled so deletion wins)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (
            SnapshotDate, OrderNbr, LineNbr,
            DeltaOpenQty, DeltaUnitPrice, DeltaExtPrice,
            DeltaPct, DeltaStatusChange, IsSignificant, Notes
        )
        SELECT
            @SnapshotDate,
            cur.OrderNbr,
            cur.LineNbr,
            cur.OpenQty    - prev.OpenQty,
            cur.UnitPrice - prev.UnitPrice,
            cur.ExtPrice  - prev.ExtPrice,
            CASE WHEN prev.ExtPrice <> 0 
                 THEN (cur.ExtPrice - prev.ExtPrice) / prev.ExtPrice * 100 
                 ELSE NULL END,
            CASE WHEN cur.OrderStatus <> prev.OrderStatus THEN 1 ELSE 0 END,
            CASE 
                WHEN ABS(cur.ExtPrice - prev.ExtPrice) > 1000 
                     OR cur.OrderStatus <> prev.OrderStatus 
                THEN 1 ELSE 0 
            END,
            'Modified'
        FROM dbo.OrderSnapshot cur
        INNER JOIN dbo.OrderSnapshot prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate    = @SnapshotDate
          AND cur.OrderStatus    <> 'Canceled'               -- ← exclude Canceled
          AND (
                cur.OpenQty    <> prev.OpenQty
             OR cur.UnitPrice <> prev.UnitPrice
             OR cur.ExtPrice  <> prev.ExtPrice
             OR cur.OrderStatus <> prev.OrderStatus
          );
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 2. DeletedLine (missing OR Canceled)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (
            SnapshotDate, OrderNbr, LineNbr,
            DeltaOpenQty, DeltaUnitPrice, DeltaExtPrice,
            DeltaPct, DeltaStatusChange, IsSignificant, Notes
        )
        SELECT
            @SnapshotDate,
            prev.OrderNbr,
            prev.LineNbr,
            -prev.OpenQty,
            -prev.UnitPrice,
            -prev.ExtPrice,
            NULL,
            CASE WHEN cur.OrderStatus = 'Canceled' THEN 1 ELSE 0 END,
            1,
            'DeletedLine'
        FROM dbo.OrderSnapshot prev
        LEFT JOIN dbo.OrderSnapshot cur
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND cur.SnapshotDate  = @SnapshotDate
        WHERE prev.SnapshotDate = @PrevSnapshotDate
          AND (
               cur.OrderNbr IS NULL
            OR cur.OrderStatus = 'Canceled'
          );
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 3. NewLine (as before)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (...)
        SELECT ...
        WHERE cur.SnapshotDate = @SnapshotDate
          AND prev.OrderNbr IS NULL;
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 4a. FulfilledComplete (only when status UNCHANGED)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (
            SnapshotDate, OrderNbr, LineNbr,
            DeltaOpenQty, DeltaUnitPrice, DeltaExtPrice,
            DeltaPct, DeltaStatusChange, IsSignificant, Notes
        )
        SELECT
            @SnapshotDate,
            cur.OrderNbr,
            cur.LineNbr,
            cur.OpenQty - prev.OpenQty,
            0,
            (cur.OpenQty - prev.OpenQty) * prev.UnitPrice,
            NULL,
            0,
            0,
            'FulfilledComplete'
        FROM dbo.OrderSnapshot cur
        INNER JOIN dbo.OrderSnapshot prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate = @SnapshotDate
          AND prev.OpenQty     > 0
          AND cur.OpenQty      = 0
          AND cur.UnitPrice    = prev.UnitPrice
          AND cur.OrderStatus  = prev.OrderStatus;   -- ← guard on status
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 4b. FulfilledPartial (only when status UNCHANGED)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (
            SnapshotDate, OrderNbr, LineNbr,
            DeltaOpenQty, DeltaUnitPrice, DeltaExtPrice,
            DeltaPct, DeltaStatusChange, IsSignificant, Notes
        )
        SELECT
            @SnapshotDate,
            cur.OrderNbr,
            cur.LineNbr,
            cur.OpenQty - prev.OpenQty,
            0,
            (cur.OpenQty - prev.OpenQty) * prev.UnitPrice,
            NULL,
            0,
            0,
            'FulfilledPartial'
        FROM dbo.OrderSnapshot cur
        INNER JOIN dbo.OrderSnapshot prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate = @SnapshotDate
          AND cur.OpenQty      < prev.OpenQty
          AND cur.OpenQty      > 0
          AND cur.UnitPrice    = prev.UnitPrice
          AND cur.OrderStatus  = prev.OrderStatus;   -- ← guard on status
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 5. Annotate Snapshot rows…
        ----------------------------------------------------------------------
        UPDATE s
        SET s.Notes = 'DeletedLine'
        FROM dbo.OrderSnapshot s
        WHERE s.SnapshotDate = @SnapshotDate
          AND s.OrderStatus  = 'Canceled';

        UPDATE s
        SET s.Notes = 'NewLine'
        FROM dbo.OrderSnapshot s
        WHERE s.SnapshotDate = @SnapshotDate
          AND NOT EXISTS(
              SELECT 1
              FROM dbo.OrderSnapshot prev
              WHERE prev.SnapshotDate = @PrevSnapshotDate
                AND prev.OrderNbr = s.OrderNbr
                AND prev.LineNbr  = s.LineNbr
          );

        UPDATE s
        SET s.Notes = 'FulfilledComplete'
        FROM dbo.OrderSnapshot s
        WHERE s.SnapshotDate = @SnapshotDate
          AND s.OpenQty = 0
          AND EXISTS(
              SELECT 1
              FROM dbo.OrderSnapshot prev
              WHERE prev.SnapshotDate = @PrevSnapshotDate
                AND prev.OrderNbr = s.OrderNbr
                AND prev.LineNbr  = s.LineNbr
                AND prev.OpenQty > 0
                AND prev.UnitPrice = s.UnitPrice
                AND prev.OrderStatus = s.OrderStatus
          );

        UPDATE s
        SET s.Notes = 'FulfilledPartial'
        FROM dbo.OrderSnapshot s
        WHERE s.SnapshotDate = @SnapshotDate
          AND s.OpenQty > 0
          AND EXISTS(
              SELECT 1
              FROM dbo.OrderSnapshot prev
              WHERE prev.SnapshotDate = @PrevSnapshotDate
                AND prev.OrderNbr = s.OrderNbr
                AND prev.LineNbr  = s.LineNbr
                AND prev.OpenQty > s.OpenQty
                AND prev.UnitPrice = s.UnitPrice
                AND prev.OrderStatus = s.OrderStatus
          );

        ----------------------------------------------------------------------
        -- Log success…
        ----------------------------------------------------------------------
        UPDATE dbo.OrderDeltaRunLog
        SET RunEndTime  = SYSDATETIME(),
            RowsInserted= @RowCount,
            RunStatus   = 'Success'
        WHERE RunID     = @RunID;
    END TRY
    BEGIN CATCH
        -- Log failure…
        UPDATE dbo.OrderDeltaRunLog
        SET RunEndTime   = SYSDATETIME(),
            RunStatus    = 'Failed',
            ErrorMessage = ERROR_MESSAGE()
        WHERE RunID = @RunID;
        THROW;
    END CATCH
END;