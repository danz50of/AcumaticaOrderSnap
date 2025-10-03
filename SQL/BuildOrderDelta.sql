ALTER PROCEDURE dbo.PopulateOrderDelta
    @SnapshotDate DATE,
    @PrevSnapshotDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @RunID INT,
        @RowCount INT = 0,
        @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        -- Log start
        INSERT INTO dbo.OrderDeltaRunLog (
            RunStartTime,
            SnapshotDate,
            PrevSnapshotDate,
            RunStatus
        )
        VALUES (
            SYSDATETIME(),
            @SnapshotDate,
            @PrevSnapshotDate,
            'Running'
        );
        SET @RunID = SCOPE_IDENTITY();

        ----------------------------------------------------------------------
        -- 1. Modified deltas (exclude Canceled so deletion wins)
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
            cur.OpenQty    - prev.OpenQty,
            cur.UnitPrice  - prev.UnitPrice,
            cur.ExtPrice   - prev.ExtPrice,
            CASE 
                WHEN prev.ExtPrice <> 0 
                    THEN ((cur.ExtPrice - prev.ExtPrice) / prev.ExtPrice) * 100
                ELSE NULL 
            END,
            CASE 
                WHEN cur.OrderStatus <> prev.OrderStatus THEN 1 
                ELSE 0 
            END,
            CASE 
                WHEN ABS(cur.ExtPrice - prev.ExtPrice) > 1000 
                     OR cur.OrderStatus <> prev.OrderStatus 
                THEN 1 
                ELSE 0 
            END,
            'Modified'
        FROM dbo.OrderSnapshot AS cur
        INNER JOIN dbo.OrderSnapshot AS prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE 
            cur.SnapshotDate   = @SnapshotDate
            AND cur.OrderStatus <> 'Canceled'
            AND (
                 cur.OpenQty    <> prev.OpenQty
              OR cur.UnitPrice <> prev.UnitPrice
              OR cur.ExtPrice  <> prev.ExtPrice
              OR cur.OrderStatus <> prev.OrderStatus
            );
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 2. DeletedLine (prev exists, cur missing OR cur status = 'Canceled')
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
            prev.OrderNbr,
            prev.LineNbr,
            -prev.OpenQty,
            -prev.UnitPrice,
            -prev.ExtPrice,
            NULL,
            CASE WHEN cur.OrderStatus = 'Canceled' THEN 1 ELSE 0 END,
            1,
            'DeletedLine'
        FROM dbo.OrderSnapshot AS prev
        LEFT JOIN dbo.OrderSnapshot AS cur
            ON cur.OrderNbr     = prev.OrderNbr
           AND cur.LineNbr      = prev.LineNbr
           AND cur.SnapshotDate = @SnapshotDate
        WHERE 
            prev.SnapshotDate = @PrevSnapshotDate
            AND (
                 cur.OrderNbr IS NULL
              OR cur.OrderStatus = 'Canceled'
            );
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 3. NewLine deltas (cur exists, prev missing)
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
            cur.OpenQty,
            cur.UnitPrice,
            cur.ExtPrice,
            NULL,
            0,
            1,
            'NewLine'
        FROM dbo.OrderSnapshot AS cur
        LEFT JOIN dbo.OrderSnapshot AS prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE 
            cur.SnapshotDate = @SnapshotDate
            AND prev.OrderNbr IS NULL;
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 4. FulfilledComplete (OpenQty→0, price same, status unchanged)
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
            cur.OpenQty    - prev.OpenQty,
            0,
            (cur.OpenQty - prev.OpenQty) * prev.UnitPrice,
            NULL,
            0,
            0,
            'FulfilledComplete'
        FROM dbo.OrderSnapshot AS cur
        INNER JOIN dbo.OrderSnapshot AS prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE 
            cur.SnapshotDate  = @SnapshotDate
            AND prev.OpenQty  > 0
            AND cur.OpenQty   = 0
            AND cur.UnitPrice = prev.UnitPrice
            AND cur.OrderStatus = prev.OrderStatus;
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 5. FulfilledPartial (OpenQty drops but >0, price same, status unchanged)
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
            cur.OpenQty    - prev.OpenQty,
            0,
            (cur.OpenQty - prev.OpenQty) * prev.UnitPrice,
            NULL,
            0,
            0,
            'FulfilledPartial'
        FROM dbo.OrderSnapshot AS cur
        INNER JOIN dbo.OrderSnapshot AS prev
            ON cur.OrderNbr      = prev.OrderNbr
           AND cur.LineNbr       = prev.LineNbr
           AND prev.SnapshotDate = @PrevSnapshotDate
        WHERE 
            cur.SnapshotDate = @SnapshotDate
            AND cur.OpenQty  < prev.OpenQty
            AND cur.OpenQty  > 0
            AND cur.UnitPrice = prev.UnitPrice
            AND cur.OrderStatus = prev.OrderStatus;
        SET @RowCount += @@ROWCOUNT;

        ----------------------------------------------------------------------
        -- 6. Annotate snapshot rows for Notes
        ----------------------------------------------------------------------
        UPDATE s
        SET s.Notes = 'DeletedLine'
        FROM dbo.OrderSnapshot AS s
        WHERE 
            s.SnapshotDate = @SnapshotDate
            AND s.OrderStatus = 'Canceled';

        UPDATE s
        SET s.Notes = 'NewLine'
        FROM dbo.OrderSnapshot AS s
        WHERE 
            s.SnapshotDate = @SnapshotDate
            AND NOT EXISTS (
                SELECT 1
                FROM dbo.OrderSnapshot AS prev
                WHERE 
                    prev.SnapshotDate = @PrevSnapshotDate
                    AND prev.OrderNbr = s.OrderNbr
                    AND prev.LineNbr  = s.LineNbr
            );

        UPDATE s
        SET s.Notes = 'FulfilledComplete'
        FROM dbo.OrderSnapshot AS s
        INNER JOIN dbo.OrderSnapshot AS prev
            ON prev.SnapshotDate = @PrevSnapshotDate
           AND prev.OrderNbr = s.OrderNbr
           AND prev.LineNbr  = s.LineNbr
           AND prev.OpenQty > 0
           AND s.OpenQty = 0
           AND prev.UnitPrice = s.UnitPrice
           AND prev.OrderStatus = s.OrderStatus
        WHERE 
            s.SnapshotDate = @SnapshotDate;

        UPDATE s
        SET s.Notes = 'FulfilledPartial'
        FROM dbo.OrderSnapshot AS s
        INNER JOIN dbo.OrderSnapshot AS prev
            ON prev.SnapshotDate = @PrevSnapshotDate
           AND prev.OrderNbr = s.OrderNbr
           AND prev.LineNbr  = s.LineNbr
           AND prev.OpenQty > s.OpenQty
           AND s.OpenQty > 0
           AND prev.UnitPrice = s.UnitPrice
           AND prev.OrderStatus = s.OrderStatus
        WHERE 
            s.SnapshotDate = @SnapshotDate;

        ----------------------------------------------------------------------
        -- Log success
        ----------------------------------------------------------------------
        UPDATE dbo.OrderDeltaRunLog
        SET 
            RunEndTime   = SYSDATETIME(),
            RowsInserted = @RowCount,
            RunStatus    = 'Success'
        WHERE 
            RunID = @RunID;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        UPDATE dbo.OrderDeltaRunLog
        SET 
            RunEndTime   = SYSDATETIME(),
            RunStatus    = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE 
            RunID = @RunID;
        THROW;
    END CATCH
END;
GO