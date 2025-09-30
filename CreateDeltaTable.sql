USE Peerless_Order_History;
GO

CREATE TABLE dbo.OrderDelta (
    SnapshotDate DATE NOT NULL,                          -- Date of comparison
    OrderNbr VARCHAR(20) NOT NULL,                       -- Sales order ID
    LineNbr INT NOT NULL,                                -- Line item number

    DeltaOpenQty DECIMAL(18,4) NULL,                     -- Change in open quantity
    DeltaUnitPrice DECIMAL(18,4) NULL,                   -- Change in unit price
    DeltaExtPrice DECIMAL(18,4) NULL,                    -- Change in extended price
    DeltaPct DECIMAL(6,2) NULL,                          -- Percent change in value
    DeltaStatusChange BIT NOT NULL DEFAULT 0,            -- Status change flag
    IsSignificant BIT NOT NULL DEFAULT 0,                -- Threshold flag
    Notes TEXT NULL,                                     -- Optional annotation

    CONSTRAINT PK_OrderDelta PRIMARY KEY (SnapshotDate, OrderNbr, LineNbr)
);

-- For filtering significant changes
CREATE NONCLUSTERED INDEX IX_OrderDelta_IsSignificant
ON dbo.OrderDelta (IsSignificant);

-- For status change tracking
CREATE NONCLUSTERED INDEX IX_OrderDelta_DeltaStatusChange
ON dbo.OrderDelta (DeltaStatusChange);
