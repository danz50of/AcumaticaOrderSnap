CREATE TABLE OrderSnapshot (
    SnapshotDate DATE NOT NULL,                          -- Date of snapshot
    OrderNbr VARCHAR(20) NOT NULL,                       -- Sales order ID
    LineNbr INT NOT NULL,                                -- Line item number
    InventoryID VARCHAR(30) NOT NULL,                    -- SKU or product code
    OrderQty DECIMAL(18,4) NOT NULL,                     -- Total quantity ordered
    OpenQty DECIMAL(18,4) NOT NULL,                      -- Remaining quantity
    UnitPrice DECIMAL(18,4) NOT NULL,                    -- Price per unit
    ExtPrice DECIMAL(18,4) NOT NULL,                     -- OpenQty × UnitPrice
    CustomerID VARCHAR(30) NOT NULL,                     -- Customer reference
    OrderDate DATE NOT NULL,                             -- Original order date
    RequestedShipDate DATE NULL,                         -- Target ship date
    WarehouseID VARCHAR(20) NULL,                        -- Fulfillment location
    SalespersonID VARCHAR(20) NULL,                      -- Salesperson attribution
    OrderStatus VARCHAR(20) NOT NULL,                    -- Status (e.g., Open)
    
    PRIMARY KEY (SnapshotDate, OrderNbr, LineNbr)        -- Composite key for tracking
);