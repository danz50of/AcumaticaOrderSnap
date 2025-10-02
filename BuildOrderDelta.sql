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


        SET @RowCount = @RowCount + @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- Update previous snapshot rows to mark as Deleted
        ----------------------------------------------------------------------
    UPDATE s
    SET s.Notes = 'DeletedLine'
    FROM dbo.OrderSnapshot s
    INNER JOIN dbo.OrderSnapshot prev
      ON s.OrderNbr     = prev.OrderNbr
     AND s.LineNbr      = prev.LineNbr
     AND prev.SnapshotDate = @PrevSnapshotDate
    WHERE s.SnapshotDate = @SnapshotDate
      AND s.OrderStatus = 'Canceled';

        ----------------------------------------------------------------------
        -- Insert NewLine deltas (cur exists, prev missing)
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
            cur.OpenQty,
            cur.UnitPrice,
            cur.ExtPrice,
            NULL,
            0,
            1,
            'NewLine'
        FROM dbo.OrderSnapshot cur
        LEFT JOIN dbo.OrderSnapshot prev
          ON cur.OrderNbr = prev.OrderNbr
         AND cur.LineNbr  = prev.LineNbr
         AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate = @SnapshotDate
          AND prev.OrderNbr IS NULL;

        SET @RowCount = @RowCount + @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- Update previous snapshot rows to mark as Deleted
        ----------------------------------------------------------------------
        
        UPDATE s
        SET s.Notes = 'NewLine'
        FROM dbo.OrderSnapshot s
        LEFT JOIN dbo.OrderSnapshot prev
          ON s.OrderNbr = prev.OrderNbr
         AND s.LineNbr  = prev.LineNbr
         AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE s.SnapshotDate = @SnapshotDate
          AND prev.OrderNbr IS NULL;

        ----------------------------------------------------------------------
        -- 1. FulfilledComplete (OpenQty→0, price same)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (
            SnapshotDate,
            OrderNbr,
            LineNbr,
            DeltaOpenQty,
            DeltaUnitPrice,
            DeltaExtPrice,
            DeltaPct,
            DeltaStatusChange,
            IsSignificant,
            Notes
        )
        SELECT
            @SnapshotDate,
            cur.OrderNbr,
            cur.LineNbr,
            cur.OpenQty - prev.OpenQty,                  -- negative delta
            0,                                            -- no unit price change
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
        WHERE cur.SnapshotDate  = @SnapshotDate
          AND prev.OpenQty      > 0
          AND cur.OpenQty       = 0
          AND cur.UnitPrice     = prev.UnitPrice;


        ----------------------------------------------------------------------
        -- 2. FulfilledPartial (OpenQty drops but stays >0, price same)
        ----------------------------------------------------------------------
        INSERT INTO dbo.OrderDelta (
            SnapshotDate,
            OrderNbr,
            LineNbr,
            DeltaOpenQty,
            DeltaUnitPrice,
            DeltaExtPrice,
            DeltaPct,
            DeltaStatusChange,
            IsSignificant,
            Notes
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
        WHERE cur.SnapshotDate  = @SnapshotDate
          AND cur.OpenQty       < prev.OpenQty
          AND cur.OpenQty       > 0
          AND cur.UnitPrice     = prev.UnitPrice;



        UPDATE s
        SET s.Notes = 'FulfilledComplete'
        FROM dbo.OrderSnapshot s
        INNER JOIN dbo.OrderSnapshot prev
            ON s.OrderNbr = prev.OrderNbr
           AND s.LineNbr  = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE s.SnapshotDate = @SnapshotDate
          AND s.OpenQty = 0
          AND prev.OpenQty > 0
          AND s.OrderQty = prev.OrderQty
          AND s.UnitPrice = prev.UnitPrice
          AND s.OrderStatus = prev.OrderStatus;

        ----------------------------------------------------------------------
        -- Insert FulfilledPartial (OpenQty dropped but not zero)
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
            (cur.OpenQty - prev.OpenQty) * cur.UnitPrice,
            NULL,
            0,
            0,
            'FulfilledPartial'
        FROM dbo.OrderSnapshot cur
        INNER JOIN dbo.OrderSnapshot prev
            ON cur.OrderNbr = prev.OrderNbr
           AND cur.LineNbr = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE cur.SnapshotDate = @SnapshotDate
          AND cur.OpenQty > 0
          AND cur.OpenQty < prev.OpenQty
          AND cur.OrderQty = prev.OrderQty
          AND cur.UnitPrice = prev.UnitPrice
          AND cur.OrderStatus = prev.OrderStatus;

        UPDATE s
        SET s.Notes = 'FulfilledPartial'
        FROM dbo.OrderSnapshot s
        INNER JOIN dbo.OrderSnapshot prev
            ON s.OrderNbr = prev.OrderNbr
           AND s.LineNbr  = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE s.SnapshotDate = @SnapshotDate
          AND s.OpenQty > 0
          AND s.OpenQty < prev.OpenQty
          AND s.OrderQty = prev.OrderQty
          AND s.UnitPrice = prev.UnitPrice
          AND s.OrderStatus = prev.OrderStatus;

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