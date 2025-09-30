ALTER PROCEDURE dbo.PopulateOrderDelta
    @SnapshotDate DATE,
    @PrevSnapshotDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RunID INT, @RowCount INT = 0, @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        -- Insert log start
        INSERT INTO dbo.OrderDeltaRunLog (RunStartTime, SnapshotDate, PrevSnapshotDate, RunStatus)
        VALUES (SYSDATETIME(), @SnapshotDate, @PrevSnapshotDate, 'Running');

        SET @RunID = SCOPE_IDENTITY();

        ----------------------------------------------------------------------
        -- Insert Modified deltas (existing lines that changed)
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
            cur.UnitPrice - prev.UnitPrice,
            cur.ExtPrice - prev.ExtPrice,
            CASE WHEN prev.ExtPrice <> 0
                 THEN ((cur.ExtPrice - prev.ExtPrice) / prev.ExtPrice) * 100
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
            ON cur.OrderNbr = prev.OrderNbr
           AND cur.LineNbr = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate = @SnapshotDate
          AND (
                cur.OpenQty    <> prev.OpenQty
             OR cur.UnitPrice <> prev.UnitPrice
             OR cur.ExtPrice  <> prev.ExtPrice
             OR cur.OrderStatus <> prev.OrderStatus
          );

        SET @RowCount = @RowCount + @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- Insert Deleted deltas (prev exists, cur missing)
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
            0,
            1,
            'DeletedLine'
        FROM dbo.OrderSnapshot prev
        LEFT JOIN dbo.OrderSnapshot cur
          ON cur.OrderNbr = prev.OrderNbr
         AND cur.LineNbr  = prev.LineNbr
         AND cur.SnapshotDate = @SnapshotDate
        WHERE prev.SnapshotDate = @PrevSnapshotDate
          AND cur.OrderNbr IS NULL;

        SET @RowCount = @RowCount + @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- Update previous snapshot rows to mark as Deleted
        ----------------------------------------------------------------------
        UPDATE s
        SET s.Notes = 'Deleted'
        FROM dbo.OrderSnapshot s
        LEFT JOIN dbo.OrderSnapshot cur
          ON cur.OrderNbr = s.OrderNbr
         AND cur.LineNbr  = s.LineNbr
         AND cur.SnapshotDate = @SnapshotDate
        WHERE s.SnapshotDate = @PrevSnapshotDate
          AND cur.OrderNbr IS NULL;

        ----------------------------------------------------------------------
        -- Update log success
        ----------------------------------------------------------------------
        UPDATE dbo.OrderDeltaRunLog
        SET RunEndTime = SYSDATETIME(),
            RowsInserted = @RowCount,
            RunStatus = 'Success'
        WHERE RunID = @RunID;

    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE dbo.OrderDeltaRunLog
        SET RunEndTime = SYSDATETIME(),
            RunStatus = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE RunID = @RunID;

        THROW;
    END CATCH
END;
GO