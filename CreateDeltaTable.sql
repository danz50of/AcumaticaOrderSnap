CREATE TABLE OrderDelta (
    SnapshotDate DATE NOT NULL,                          -- Date of comparison
    OrderNbr VARCHAR(20) NOT NULL,                       -- Sales order ID
    LineNbr INT NOT NULL,                                -- Line item number
    
    DeltaOpenQty DECIMAL(18,4) NULL,                     -- Change in open quantity
    DeltaUnitPrice DECIMAL(18,4) NULL,                   -- Change in unit price
    DeltaExtPrice DECIMAL(18,4) NULL,                    -- Change in extended price
    DeltaPct DECIMAL(6,2) NULL,                          -- Percent change in value
    DeltaStatusChange BOOLEAN NOT NULL DEFAULT FALSE,    -- Status change flag
    IsSignificant BOOLEAN NOT NULL DEFAULT FALSE,        -- Threshold flag
    Notes TEXT NULL,                                     -- Optional annotation
    
    PRIMARY KEY (SnapshotDate, OrderNbr, LineNbr)
);