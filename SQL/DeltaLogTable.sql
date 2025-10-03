USE Peerless_Order_History;
GO

CREATE TABLE dbo.OrderDeltaRunLog (
    RunID INT IDENTITY(1,1) PRIMARY KEY,       -- Unique run identifier
    RunStartTime DATETIME2 NOT NULL,           -- When the run began
    RunEndTime DATETIME2 NULL,                 -- When the run finished
    SnapshotDate DATE NOT NULL,                -- Current snapshot date
    PrevSnapshotDate DATE NOT NULL,            -- Previous snapshot date
    RowsInserted INT DEFAULT 0,                -- Number of deltas written
    RunStatus VARCHAR(20) NOT NULL,            -- e.g., 'Success', 'Failed'
    ErrorMessage NVARCHAR(4000) NULL           -- Optional error details
);