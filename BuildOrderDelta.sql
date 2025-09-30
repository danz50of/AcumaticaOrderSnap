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

        -- Insert deltas
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
            NULL
        FROM dbo.OrderSnapshot cur
        INNER JOIN dbo.OrderSnapshot prev
            ON cur.OrderNbr = prev.OrderNbr
           AND cur.LineNbr = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate = @SnapshotDate;

        SET @RowCount = @@ROWCOUNT;

        -- Update log success
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