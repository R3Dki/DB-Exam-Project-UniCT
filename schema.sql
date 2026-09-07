-- Create ENUM types if they don't already exist
DO $$ BEGIN
    CREATE TYPE STATUS_ENUM AS ENUM ('Online', 'Offline', 'Maintenance', 'Fault', 'Disconnected');
    CREATE TYPE METER_TYPE_ENUM AS ENUM ('Smart', 'Manual', 'NotPresent');
    CREATE TYPE OPERATION_TYPE_ENUM AS ENUM ('Check', 'Repair', 'Attach', 'Detach', 'Install', 'Reading');
    CREATE TYPE TARGET_TYPE_ENUM AS ENUM ('Meter', 'Pump', 'Node', 'Pipe');
    CREATE TYPE OPERATION_PRIORITY_ENUM AS ENUM ('Urgent', 'Important', 'Normal');
    CREATE TYPE CLIENT_TYPE_ENUM AS ENUM ('Civil', 'Industrial', 'NonMetered');
    EXCEPTION WHEN DUPLICATE_OBJECT THEN RAISE NOTICE 'Enums already exist. Skipping.';
END $$;

-- Grid Elements
    -- Nodes Table
    CREATE TABLE IF NOT EXISTS Nodes (
        Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Latitude DECIMAL(10,8) NOT NULL,
        Longitude DECIMAL(10,8) NOT NULL,
        Status STATUS_ENUM NOT NULL DEFAULT 'Offline',
        InstallationDate TIMESTAMP
    );

    -- Pumps Table
    CREATE TABLE IF NOT EXISTS Pumps (
        Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Model VARCHAR(30) NOT NULL,
        SerialNumber VARCHAR(30) UNIQUE NOT NULL,
        AttachedTo BIGINT REFERENCES Nodes(Id) ON DELETE CASCADE,
        PowerKw DECIMAL(7,2) NOT NULL,
        MaxFlowRateLps DECIMAL(8,2) NOT NULL,
        Status STATUS_ENUM DEFAULT 'Offline' NOT NULL,
        InstallationDate TIMESTAMP,
        CONSTRAINT chk_power_kw CHECK (PowerKw >= 0),
        CONSTRAINT chk_max_flow_rate CHECK (MaxFlowRateLps >= 0)
    );

    -- Pipes Table
    CREATE TABLE IF NOT EXISTS Pipes (
        Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        NodeA BIGINT REFERENCES Nodes(Id) ON DELETE CASCADE,
        NodeB BIGINT REFERENCES Nodes(Id) ON DELETE CASCADE,
        CrossSection DECIMAL(8,3) NOT NULL, -- In cm
        Length DECIMAL(10,5) NOT NULL, -- In m
        Status STATUS_ENUM DEFAULT 'Offline' NOT NULL,
        InstallationDate TIMESTAMP,
        CONSTRAINT chk_length CHECK (Length >= 0),
        CONSTRAINT chk_cross_section CHECK (CrossSection >= 0)
    );
-- Grid Elements


-- Clients Table
CREATE TABLE IF NOT EXISTS Clients (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Name VARCHAR(70) NOT NULL,
    ZIPCode INT NOT NULL,
    City VARCHAR(50) NOT NULL,
    Address VARCHAR(50) NOT NULL,
    Phone VARCHAR(18) NOT NULL,
    Email VARCHAR(80) NOT NULL
);

-- Meters Table
CREATE TABLE IF NOT EXISTS Meters (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    SerialNumber VARCHAR(30) UNIQUE NOT NULL,
    MeterType METER_TYPE_ENUM NOT NULL,
    AttachedTo BIGINT REFERENCES Pipes(Id) ON DELETE SET NULL,
    Status STATUS_ENUM NOT NULL DEFAULT 'Offline',
    InstallationDate TIMESTAMP,
    CONSTRAINT chk_meter_type CHECK (MeterType IN ('Smart', 'Manual', 'NotPresent'))
);

-- Contracts Table
CREATE TABLE IF NOT EXISTS Contracts (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Client BIGINT REFERENCES Clients(Id) ON DELETE CASCADE,
    PropertyZIPCode INT NOT NULL,
    PropertyCity VARCHAR(50) NOT NULL,
    PropertyAddress VARCHAR(50) NOT NULL,
    ClientType CLIENT_TYPE_ENUM NOT NULL,
    Meter BIGINT UNIQUE REFERENCES Meters(Id) ON DELETE SET NULL,
    EstablishedBillCost DECIMAL(16,2),
    BillingPeriod INTERVAL,
    AllocatedFlowrate DECIMAL(8,2),
    ContractIssueDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ContractEndDate TIMESTAMP,
    CONSTRAINT chk_allocated_flowrate CHECK (AllocatedFlowrate >= 0) -- Check
);

-- Operations Table
CREATE TABLE IF NOT EXISTS Operations (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Type OPERATION_TYPE_ENUM NOT NULL,
    TargetType TARGET_TYPE_ENUM,
    TargetId BIGINT, -- If NULL it's likely an 'Install' Operation
    IssueDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CompletionDate TIMESTAMP,
    Description TEXT,
    OperationCost DECIMAL(16,2),
    Priority OPERATION_PRIORITY_ENUM NOT NULL,
    RequiredTechnicians INT DEFAULT 1
);

-- Technicians Table
CREATE TABLE IF NOT EXISTS Technicians (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    FullName VARCHAR(70) NOT NULL,
    FiscalCode VARCHAR(20) UNIQUE NOT NULL,
    IBAN VARCHAR(40),
    Wage DECIMAL(16,2) NOT NULL,
    EmploymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ResignationDate TIMESTAMP
);

-- TechnicianTasks Table
CREATE TABLE IF NOT EXISTS TechnicianTasks (
    --Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Operation BIGINT REFERENCES Operations(Id) ON DELETE CASCADE,
    Technician BIGINT REFERENCES Technicians(Id) ON DELETE CASCADE,
    AssignmentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ReleaseDate TIMESTAMP,
    PRIMARY KEY (Operation, Technician)
);

-- Salaries Table
CREATE TABLE IF NOT EXISTS Salaries (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Technician BIGINT REFERENCES Technicians(Id) ON DELETE CASCADE,
    WageAmount DECIMAL(16,2) NOT NULL,
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Readings Table
CREATE TABLE IF NOT EXISTS Readings (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Meter BIGINT REFERENCES Meters(Id) ON DELETE CASCADE,
    Volume DECIMAL(14,2) NOT NULL,
    TimePeriod INTERVAL,
    Technician BIGINT REFERENCES Technicians(Id) DEFAULT NULL,
    Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_volume CHECK (Volume >= 0)
);

-- Bills Table
CREATE TABLE IF NOT EXISTS Bills (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Reading BIGINT REFERENCES Readings(Id) ON DELETE CASCADE,
    Contract BIGINT REFERENCES Contracts(Id) ON DELETE CASCADE,
    BillAmount DECIMAL(16,2) NOT NULL,
    IssuingDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    DueDate TIMESTAMP NOT NULL,
    PaymentDate TIMESTAMP
);

-- Progressive Taxation Table
CREATE TABLE IF NOT EXISTS ProgressiveTaxation (
    Id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    MinimumVolume DECIMAL(10,2) UNIQUE NOT NULL,
    PricePerCubicMeter DECIMAL(16,2) NOT NULL
);

-- Settings Table
CREATE TABLE IF NOT EXISTS Settings (
    DisconnectionTimeThreshold INTERVAL NOT NULL,
    CivilDefaultFlowrate DECIMAL(8,2) NOT NULL,
    MaxAllowedFlowrateBottleneck DECIMAL(4,2) NOT NULL,
    OverdueDailyBillIncreasePercentile DECIMAL(5,2) NOT NULL,
    TechnicianMeasurementOperationsLimit INT NOT NULL,
    AutomaticTechnicianAllocation BOOL NOT NULL,
    CONSTRAINT single_row CHECK (TRUE), -- Single Row Constraint
    CONSTRAINT chk_max_allowed_flowrate CHECK (MaxAllowedFlowrateBottleneck >= 0)
);

-- Default Settings Configuration, there must be ONLY ONE row in this table.
DO $$ BEGIN
    IF NOT EXISTS (SELECT * FROM settings) THEN
        INSERT INTO Settings VALUES (INTERVAL '3 MONTH', 0.8, 1, 5, 30, TRUE);
    END IF;
END $$;