-- ============================================================================
-- HELPER: Resolve TargetType from table name
-- ============================================================================
CREATE OR REPLACE FUNCTION get_target_type(table_name TEXT)
RETURNS TARGET_TYPE_ENUM AS $$
BEGIN
    RETURN CASE table_name
        WHEN 'nodes'  THEN 'Node'::target_type_enum
        WHEN 'pumps'  THEN 'Pump'::target_type_enum
        WHEN 'pipes'  THEN 'Pipe'::target_type_enum
        WHEN 'meters' THEN 'Meter'::target_type_enum
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- ============================================================================
-- TRIGGER 1: Status set to 'Fault' or 'Maintenance' → issue Operation
--            or if a row is instanced or set to 'Offline' and InstallationDate is NULL issue an 'Install' Operation
-- ============================================================================
-- Priority: 'Urgent' for Pumps/Nodes/Pipes, 'Normal' for Meters
-- RequiredTechnicians: 4 for Pumps, 2 for Nodes/Pipes, 1 for Meters
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_status_f_m_i()
RETURNS TRIGGER AS $$
DECLARE
    operation_target_type  TARGET_TYPE_ENUM;
    operation_priority     OPERATION_PRIORITY_ENUM;
    operation_technicians_count  INT;
    operation_description TEXT;
    previous_operation_type OPERATION_TYPE_ENUM;
BEGIN
    -- Only fire when status changes to 'Fault', 'Offline' or 'Maintenance'
    -- Skip if old status was already Fault/Maintenance/Offline
    -- Skip if the Target was set to Offline by an operation
   IF (TG_OP = 'UPDATE' AND OLD.status NOT IN ('Online', 'Fault', 'Maintenance')) OR
      NEW.status NOT IN ('Maintenance', 'Fault', 'Disconnected', 'Offline') OR
      old.status = new.status THEN
       RAISE WARNING 'Skip condition in fn_status_f_m_i encountered.';
       RETURN NEW;
   END IF;
    /*IF NEW.Status = 'Online' OR
       (TG_OP = 'UPDATE' AND OLD.Status IN ('Fault', 'Offline')) OR
       (NEW.Status IN ('Offline', 'Disconnected') AND NEW.InstallationDate IS NOT NULL) OR
       (NEW.Status = 'Disconnected' AND OLD.Status <> 'Online') THEN
        RAISE WARNING 'Skip condition in fn_status_f_m_i encountered.';
        RETURN NEW;
    END IF;*/

    operation_target_type := get_target_type(TG_TABLE_NAME);

    SELECT o.type INTO previous_operation_type FROM Operations o
        WHERE o.TargetType = get_target_type(tg_table_name)
        AND o.TargetId   = NEW.Id
        AND o.CompletionDate IS NULL;

    IF FOUND AND previous_operation_type NOT IN ('Check', 'Repair') THEN
        RAISE WARNING 'Skip condition 2 in fn_status_f_m_i encountered.';
        RETURN NEW;
    ELSE
        UPDATE Operations SET CompletionDate = CURRENT_TIMESTAMP
        WHERE TargetType = get_target_type(TG_TABLE_NAME)
        AND TargetId = NEW.Id
        AND CompletionDate IS NULL
        AND Type = 'Check';
    END IF;

    IF operation_target_type = 'Meter' THEN
        IF NEW.AttachedTo IS NULL THEN
            INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
                VALUES ('Attach', operation_target_type, NEW.Id, 'Reconnect Meter to grid', 'Important', 1);
            RAISE NOTICE 'Skip condition 3 in fn_status_f_m_i encountered.';
            RETURN NEW;
        END IF;
        IF NEW.status = 'Online' AND OLD.installationdate IS NULL THEN
            UPDATE meters m SET installationdate = current_timestamp WHERE NEW.Id = m.Id;
        ELSE
            RAISE NOTICE 'Skip condition 4 in fn_status_f_m_i encountered.';
            --RETURN NEW;
        END IF;
    END IF;

    -- Set priority and required technicians based on element type
    IF NEW.Status = 'Maintenance' THEN
        operation_priority := 'Normal';
        operation_technicians_count := 1;
    ELSIF NEW.Status = 'Fault' THEN
        CASE TG_TABLE_NAME
            WHEN 'pumps' THEN
                operation_priority := 'Urgent';
                operation_technicians_count := 4;
            WHEN 'nodes' THEN
                operation_priority := 'Urgent';
                operation_technicians_count := 2;
            WHEN'pipes' THEN
                operation_priority := 'Urgent';
                operation_technicians_count := 2;
            WHEN 'meters' THEN
                operation_priority := 'Important';
                operation_technicians_count := 1;
        END CASE;
    ELSE -- Not installed case
        IF OLD.status = 'Fault' THEN
            UPDATE Operations SET CompletionDate = CURRENT_TIMESTAMP
            WHERE TargetType = get_target_type(TG_TABLE_NAME)
            AND TargetId = NEW.Id
            AND CompletionDate IS NULL
            AND Type = 'Repair';
            RETURN NEW;
        END IF;
        CASE TG_TABLE_NAME
            WHEN 'pumps' THEN
                operation_priority := 'Urgent';
                operation_technicians_count := 4;
            WHEN 'nodes' THEN
                operation_priority := 'Important';
                operation_technicians_count := 2;
            WHEN 'pipes' THEN
                operation_priority := 'Important';
                operation_technicians_count := 2;
            WHEN 'meters' THEN
                operation_priority := 'Normal';
                operation_technicians_count := 1;
        END CASE;
    END IF;

    -- Automatically set description
    IF NEW.Status = 'Maintenance' THEN
        operation_description := 'Regular maintenance operation';
    ELSIF NEW.Status = 'Fault' THEN
        operation_description := 'Component fault detected, repairment required';
    ELSE -- Not installed case
        operation_description := 'Component installation required';
    END IF;

    INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
    VALUES (
        CASE NEW.Status
            WHEN 'Fault' THEN 'Repair'
            WHEN 'Offline' THEN 'Install'
            WHEN 'Disconnected' THEN 'Install'
            ELSE 'Check'
        END::operation_type_enum, -- Cast to Operation Type Enum
        operation_target_type,
        NEW.Id,
        operation_description,
        operation_priority,
        operation_technicians_count
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_nodes_fault_maintenance
    AFTER INSERT OR UPDATE OF Status ON Nodes
    FOR EACH ROW EXECUTE FUNCTION fn_status_f_m_i();

CREATE OR REPLACE TRIGGER trg_pumps_fault_maintenance
    AFTER INSERT OR UPDATE OF Status ON Pumps
    FOR EACH ROW EXECUTE FUNCTION fn_status_f_m_i();

CREATE OR REPLACE TRIGGER trg_pipes_fault_maintenance
    AFTER INSERT OR UPDATE OF Status ON Pipes
    FOR EACH ROW EXECUTE FUNCTION fn_status_f_m_i();

CREATE OR REPLACE TRIGGER trg_meters_fault_maintenance
    AFTER INSERT OR UPDATE OF Status ON Meters
    FOR EACH ROW EXECUTE FUNCTION fn_status_f_m_i();


-- ============================================================================
-- TRIGGER 2: Automatically Complete Operations on Status Update
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_operation_completed()
RETURNS TRIGGER AS $$
DECLARE
    operation_type OPERATION_TYPE_ENUM;
BEGIN
    IF NEW.Status NOT IN ('Online', 'Disconnected', 'Fault') OR
       (OLD.Status = 'Maintenance' AND NEW.Status NOT IN ('Fault', 'Online')) OR
       (NEW.Status = 'Fault' AND OLD.Status <> 'Maintenance')OR
       OLD.Status = NEW.Status THEN
        RAISE WARNING 'Skip condition in fn_operation_completed encountered.';
        RETURN NEW;
    END IF;

    SELECT o.type INTO operation_type FROM operations o WHERE TargetType = get_target_type(TG_TABLE_NAME)
      AND TargetId = NEW.Id
      AND CompletionDate IS NULL
      AND Type <> 'Reading';

    IF NOT FOUND THEN
        RAISE WARNING 'Skip condition 2 in fn_operation_completed encountered.';
        RETURN NEW;
    END IF;

    -- Check operation type success
    CASE operation_type
        WHEN 'Check' THEN
            IF NEW.status NOT IN ('Online', 'Fault', 'Disconnected') THEN
                RETURN NEW;
            END IF;
        WHEN 'Repair' THEN
            IF NEW.status <> 'Online' THEN
                RETURN NEW;
            END IF;
        WHEN 'Attach' THEN
            IF NEW.status <> 'Online' THEN
                RETURN NEW;
            END IF;
        WHEN 'Detach' THEN
            IF NEW.status NOT IN ('Disconnected', 'Offline') THEN
                RETURN NEW;
            END IF;
        WHEN 'Install' THEN
            IF NEW.status <> 'Online' THEN
                RETURN NEW;
            END IF;
        ELSE
            RAISE EXCEPTION 'Impossible Case Encountered';
    END CASE;


    -- Close the most recent open operation for this target
    UPDATE Operations
    SET CompletionDate = CURRENT_TIMESTAMP
    WHERE TargetType = get_target_type(TG_TABLE_NAME)
      AND TargetId = NEW.Id
      AND CompletionDate IS NULL
      AND Type <> 'Reading';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_nodes_operation_completed
    AFTER UPDATE OF Status ON Nodes
    FOR EACH ROW EXECUTE FUNCTION fn_operation_completed();

CREATE OR REPLACE TRIGGER trg_pumps_operation_completed
    AFTER UPDATE OF Status ON Pumps
    FOR EACH ROW EXECUTE FUNCTION fn_operation_completed();

CREATE OR REPLACE TRIGGER trg_pipes_operation_completed
    AFTER UPDATE OF Status ON Pipes
    FOR EACH ROW EXECUTE FUNCTION fn_operation_completed();

CREATE OR REPLACE TRIGGER trg_meters_operation_completed
    AFTER UPDATE OF Status ON Meters
    FOR EACH ROW EXECUTE FUNCTION fn_operation_completed();


-- ============================================================================
-- TRIGGER 3: Operation CompletionDate set → release all TechnicianTasks
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_release_operation_technicians()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND
       OLD.CompletionDate IS NULL AND
       NEW.CompletionDate IS NOT NULL
    THEN
        UPDATE TechnicianTasks
        SET ReleaseDate = CURRENT_TIMESTAMP
        WHERE Operation  = NEW.Id
          AND ReleaseDate IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_free_technicians_on_operation_completion
    AFTER UPDATE OF CompletionDate ON Operations
    FOR EACH ROW EXECUTE FUNCTION fn_release_operation_technicians();


-- ============================================================================
-- TRIGGER 4: Contract created → create Meter
-- ============================================================================
-- MeterType: 'Smart' for Civil/Industrial, 'NotPresent' for NonMetered
-- SerialNumber: random placeholder (for example purposes)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_contract_new_meter()
RETURNS TRIGGER AS $$
DECLARE
    meter_type METER_TYPE_ENUM;
    meter_id BIGINT;
    meter_serial VARCHAR(30);
BEGIN
    -- Determine meter type from client type
    IF NEW.ClientType IN ('Civil', 'Industrial') THEN
        meter_type := 'Smart';
    ELSE
        meter_type := 'NotPresent';
    END IF;

    -- Generate a random serial number (example purposes)
    meter_serial := 'MTR-' || lpad(floor(random() * 1000000000)::TEXT, 9, '0');

    INSERT INTO Meters (SerialNumber, MeterType, AttachedTo, Status)
    VALUES (meter_serial, meter_type, (SELECT Id FROM Pipes ORDER BY random() LIMIT 1), 'Disconnected')
    RETURNING Id INTO meter_id;

    -- Link the meter to the contract
    NEW.Meter := meter_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_contract_new_meter
    BEFORE INSERT ON Contracts
    FOR EACH ROW EXECUTE FUNCTION fn_contract_new_meter();


-- ============================================================================
-- TRIGGER 5: Meter's pipe reference set to NULL → issue Attach Operation
-- ============================================================================
-- If a meter's AttachedTo (pipe reference) is set to NULL (e.g. pipe deleted
-- via ON DELETE CASCADE or manual update), issue an 'Attach' operation so a
-- technician can reconnect the meter to a pipe.
-- Only fires when AttachedTo transitions from a value to NULL.
-- Skips if an open Attach operation already exists for this meter.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_meter_pipe_detached()
RETURNS TRIGGER AS $$
BEGIN
    -- Only when AttachedTo goes from a value to NULL
    IF OLD.AttachedTo IS NULL OR NEW.AttachedTo IS NOT NULL THEN
        RAISE WARNING 'Skip condition in fn_meter_pipe_detached encountered.';
        RETURN NEW;
    END IF;

    -- Skip if there's already an open operation for this meter
    IF EXISTS (
        SELECT 1 FROM Operations o
        WHERE o.TargetType = 'Meter'
          AND o.TargetId   = NEW.Id
          AND o.CompletionDate IS NULL
    ) THEN
        RAISE WARNING 'Skip condition 2 in fn_meter_pipe_detached encountered.';
        RETURN NEW;
    END IF;

    RAISE NOTICE 'Meter Pipe reference set to NULL, Disconnecting.';
    NEW.Status = 'Disconnected';

    INSERT INTO operations (type, targettype, targetid, description, priority, requiredtechnicians)
    VALUES ('Attach', 'Meter', NEW.Id, 'Reattach disconnected meter', 'Important', 1);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_meter_pipe_detached
    BEFORE UPDATE OF AttachedTo ON Meters
    FOR EACH ROW EXECUTE FUNCTION fn_meter_pipe_detached();


-- ============================================================================
-- TRIGGER 6: Contract ended (ContractEndDate set) → disconnect meter
--             and issue a 'Detach' Operation for the meter
-- ============================================================================
-- When a contract is closed:
--   1. Set the associated Meter's Status to 'Disconnected'
--   2. Issue a 'Detach' Operation so a technician physically detaches it
-- Only fires when ContractEndDate transitions from NULL to a value.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_contract_ended()
RETURNS TRIGGER AS $$
DECLARE
    meter_id     BIGINT;
    meter_status STATUS_ENUM;
BEGIN
    IF OLD.ContractEndDate IS NOT NULL OR
       NEW.ContractEndDate IS NULL THEN
        RAISE WARNING 'Skip condition in fn_contract_ended encountered.';
        RETURN NEW;  -- already ended, no-op
    END IF;

    meter_id := OLD.Meter;

    -- Nothing to do if contract has no meter
    IF meter_id IS NULL THEN
        RAISE WARNING 'Skip condition 2 in fn_contract_ended encountered.';
        RETURN NEW;
    END IF;

    -- Get current meter status
    SELECT m.Status INTO meter_status
    FROM Meters m
    WHERE m.Id = meter_id;

    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    -- Issue a Detach operation for the meter (only if one isn't already open)
    IF NOT EXISTS (
        SELECT 1 FROM Operations o
        WHERE o.Type       = 'Detach'
          AND o.TargetType = 'Meter'
          AND o.TargetId   = meter_id
          AND o.CompletionDate IS NULL
    ) THEN
        INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
        VALUES (
            'Detach',
            'Meter',
            meter_id,
            'Contract ended - meter flagged for removal',
            'Normal',
            1
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_contract_ended
    AFTER UPDATE OF ContractEndDate ON Contracts
    FOR EACH ROW EXECUTE FUNCTION fn_contract_ended();


-- ============================================================================
-- TRIGGER 7: Reading created → auto-generate Bill
-- ============================================================================
-- Metered contracts: progressive taxation based on volume
-- NonMetered contracts: use EstablishedBillCost
-- DueDate: Current Date + 1 Month
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_reading_create_bill()
RETURNS TRIGGER AS $$
DECLARE
    billing_contract      RECORD; -- Getting the whole Contract row to decrease the SELECT queries needed.
    bill_amount   DECIMAL(16,2);
    previous_reading_volume   DECIMAL(14,2);
    effective_volume   DECIMAL(14,2);
    price_per_cm          DECIMAL(16,2); -- Price per Cubic Meter
BEGIN

    -- Loading Billing Contract
    SELECT c.*
    INTO billing_contract
    FROM Contracts c
    WHERE c.Meter = NEW.Meter
      AND c.ContractEndDate IS NULL
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE WARNING 'No active contract found for Meter %', NEW.Meter;
        RETURN NEW;
    END IF;

    IF billing_contract.ClientType = 'NonMetered' THEN
        -- Non Metered Contract
        bill_amount := billing_contract.EstablishedBillCost;
    ELSE
        -- Get the previous reading's volume for this meter
        SELECT r.Volume
        INTO previous_reading_volume
        FROM Readings r
        WHERE r.Meter = NEW.Meter
          AND r.Id <> NEW.Id
        ORDER BY r.Date DESC
        LIMIT 1;

        -- First reading ever → previous volume is 0
        previous_reading_volume := COALESCE(previous_reading_volume, 0);

        -- Consumption = current cumulative − previous cumulative
        effective_volume := NEW.Volume - previous_reading_volume;

        -- Guard against negative (e.g. meter reset / data error)
        IF effective_volume <= 0 THEN
            effective_volume := 0;
        END IF;

        -- Find the progressive taxation band, found by looking at the
        -- lowest threshold (descending order) and finding if the
        -- effective_volume is equal or bigger than the threshold
        SELECT pt.PricePerCubicMeter
        INTO price_per_cm
        FROM ProgressiveTaxation pt
        WHERE pt.MinimumVolume <= effective_volume
        ORDER BY pt.MinimumVolume DESC
        LIMIT 1;

        -- Fallback price if no range is found
        price_per_cm := COALESCE(price_per_cm, 1);

        bill_amount := price_per_cm * effective_volume;
    END IF;

    -- Autocomplete Reading Operation
    IF EXISTS (SELECT * FROM operations o WHERE TargetType = 'Meter'
      AND TargetId = NEW.Meter
      AND CompletionDate IS NULL
      AND Type = 'Reading') THEN
        UPDATE operations SET CompletionDate = CURRENT_TIMESTAMP
        WHERE TargetType = 'Meter'
        AND TargetId = NEW.Meter
        AND CompletionDate IS NULL
        AND Type = 'Reading';
    END IF;

    -- Insert Bill
    INSERT INTO Bills (Reading, Contract, BillAmount, DueDate)
    VALUES (
        NEW.Id,
        billing_contract.Id,
        bill_amount,
        CURRENT_TIMESTAMP + INTERVAL '1 month'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_reading_create_bill
    AFTER INSERT ON Readings
    FOR EACH ROW EXECUTE FUNCTION fn_reading_create_bill();


-- ============================================================================
-- TRIGGER 8: Bill paid (PaymentDate set) → if overdue & meter disconnected,
--            issue 'Attach' Operation (only once)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_overdue_paid_reattach()
RETURNS TRIGGER AS $$
DECLARE
    target_meter RECORD; -- Record used in order to reduce SELECT queries
    existing_operation_id BIGINT;
BEGIN
    -- Only when PaymentDate is being set
    IF NEW.PaymentDate IS NULL OR
       (TG_OP = 'UPDATE' AND OLD.PaymentDate IS NOT NULL) OR
       NEW.PaymentDate <= NEW.DueDate THEN
        RETURN NEW;
    END IF;

    -- Get the meter
    SELECT m.* INTO target_meter   FROM Meters m   WHERE m.Id = (
        SELECT r.Meter FROM Readings r WHERE r.Id = NEW.Reading LIMIT 1
    );

    -- Only act if the meter is currently disconnected
    IF target_meter.Status <> 'Disconnected' THEN
        RETURN NEW;
    END IF;

    -- Check if an 'Attach' operation already exists (not yet completed) and skip if that's the case
    SELECT o.Id INTO existing_operation_id
    FROM Operations o
    WHERE o.Type       = 'Attach'
      AND o.TargetType = 'Meter'
      AND o.TargetId   = target_meter.Id
      AND o.CompletionDate IS NULL
    LIMIT 1;

    IF FOUND THEN
        RAISE WARNING 'Attach operation already present Id: %', existing_operation_id;
        RETURN NEW;
    END IF;

    INSERT INTO Operations (Type, TargetType, TargetId, Priority, RequiredTechnicians)
    VALUES ('Attach', 'Meter', target_meter.Id, 'Normal', 1);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_overdue_paid_reattach
    AFTER UPDATE OF PaymentDate ON Bills
    FOR EACH ROW EXECUTE FUNCTION fn_overdue_paid_reattach();


-- ============================================================================
-- TRIGGER 9: Meter inserted → check supply/demand balance
-- ============================================================================
-- If total demand is within MaxAllowedFlowrateBottleneck% of supply,
-- issue an 'Install' Operation (TargetId/TargetType NULL) for a new pump.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_check_flowrate_capacity()
RETURNS TRIGGER AS $$
DECLARE
    total_demand   DECIMAL;
    total_supply   DECIMAL;
    existing_operation_id    BIGINT;
BEGIN

    RAISE NOTICE 'Checking Flowrate';

    -- Total demand = sum of AllocatedFlowrate from active contracts with meters
    SELECT COALESCE(SUM(c.AllocatedFlowrate), 0)
    INTO total_demand
    FROM Contracts c
    WHERE c.Meter IS NOT NULL
      AND c.ContractEndDate IS NULL;

    -- Total supply = sum of MaxFlowRateLps from 'Online' pumps
    SELECT COALESCE(SUM(p.MaxFlowRateLps), 0)
    INTO total_supply
    FROM Pumps p
    WHERE p.Status = 'Online';

    -- If supply is 0 or demand reaches threshold % of supply
    IF total_demand <= 0 THEN
        RAISE NOTICE 'No demand.';
        RETURN NEW;
    END IF;
    IF total_supply >= 0
       AND (total_supply / total_demand * 100) <= (100 - (
            SELECT s.MaxAllowedFlowrateBottleneck FROM Settings s LIMIT 1 -- Get Threshold
    )) THEN
        -- Check if there's already an open Install operation with Pump target
        SELECT o.Id INTO existing_operation_id
        FROM Operations o
        WHERE o.Type       = 'Install'
          AND o.TargetType = 'Pump'
          AND o.TargetId   IS NULL
          AND o.CompletionDate IS NULL
          AND o.priority = 'Important'
          AND o.RequiredTechnicians = 4
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE WARNING 'Insufficient Grid Flowrate Capacity, please install a new Pump with at least a Flowrate of % L/s.', total_demand * ((SELECT s.MaxAllowedFlowrateBottleneck FROM Settings s LIMIT 1) / 100);
            INSERT INTO Operations (Type, TargetType, TargetId, Priority, RequiredTechnicians, Description)
            VALUES (
                'Install',
                'Pump',
                NULL,
                'Important',
                4,
                'Max available flowrate is too low to guarantee regular supply, install new pump'
            );
        END IF;
    END IF;
    RAISE NOTICE 'Supply to Demand ratio is in spec. S/D: %', (total_supply / total_demand * 100);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_flowrate_capacity
    AFTER INSERT ON Meters
    FOR EACH ROW EXECUTE FUNCTION fn_check_flowrate_capacity();


-- ============================================================================
-- TRIGGER 10 (maybe): Urgent Operation created + AutoAllocation ON
--            → allocate technicians even if busy
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_auto_allocate_urgent()
RETURNS TRIGGER AS $$
DECLARE
    required_technicians      INT;
    allocated_technicians    INT := 0;
    current_technician        RECORD;
BEGIN
    IF NOT (SELECT s.AutomaticTechnicianAllocation FROM Settings s LIMIT 1) OR NEW.Priority <> 'Urgent' THEN
        RETURN NEW;
    END IF;

    required_technicians := COALESCE(NEW.RequiredTechnicians, 1);
    RAISE NOTICE '==================== Automatic Technician Allocation Begin ====================';
    -- 1st pass: assign free technicians (no open tasks at all)
    FOR current_technician IN
        SELECT t.Id
        FROM Technicians t
        WHERE t.ResignationDate IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM TechnicianTasks tt
              WHERE tt.Technician = t.Id AND tt.ReleaseDate IS NULL
          )
          AND NOT EXISTS (
              SELECT 1 FROM TechnicianTasks tt
              WHERE tt.Technician = t.Id AND tt.Operation = NEW.Id
          )
        ORDER BY t.Id
    LOOP
        EXIT WHEN allocated_technicians >= required_technicians;

        INSERT INTO TechnicianTasks (Operation, Technician)
        VALUES (NEW.Id, current_technician.Id);
        RAISE NOTICE 'Technician: %, Id: % - Allocated to Operation Id: %', (SELECT fullname FROM technicians WHERE id = current_technician.Id), current_technician.Id, NEW.Id;
        allocated_technicians := allocated_technicians + 1;
    END LOOP;

    -- 2nd pass: if still short, assign busy technicians NOT on other Urgent ops
    IF allocated_technicians < required_technicians THEN
        FOR current_technician IN
            SELECT t.Id
            FROM Technicians t
            WHERE t.ResignationDate IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM TechnicianTasks tt
                  JOIN Operations o ON o.Id = tt.Operation
                  WHERE tt.Technician = t.Id
                    AND tt.ReleaseDate IS NULL
                    AND o.Priority = 'Urgent'
              )
              AND NOT EXISTS (
                  SELECT 1 FROM TechnicianTasks tt
                  WHERE tt.Technician = t.Id AND tt.Operation = NEW.Id
              )
            ORDER BY t.Id
        LOOP
            EXIT WHEN allocated_technicians >= required_technicians;

            INSERT INTO TechnicianTasks (Operation, Technician)
            VALUES (NEW.Id, current_technician.Id);
            RAISE NOTICE 'Technician: %, Id: % - Allocated to Operation Id: %', (SELECT fullname FROM technicians WHERE id = current_technician.Id), current_technician.Id, NEW.Id;
            allocated_technicians := allocated_technicians + 1;
        END LOOP;
    END IF;

    -- 3rd pass (last resort): assign anyone not already on THIS operation
    IF allocated_technicians < required_technicians THEN
        FOR current_technician IN
            SELECT t.Id
            FROM Technicians t
            WHERE t.ResignationDate IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM TechnicianTasks tt
                  WHERE tt.Technician = t.Id AND tt.Operation = NEW.Id
              )
            ORDER BY t.Id
        LOOP
            EXIT WHEN allocated_technicians >= required_technicians;

            INSERT INTO TechnicianTasks (Operation, Technician)
            VALUES (NEW.Id, current_technician.Id);
            RAISE NOTICE 'Technician: %, Id: % - Allocated to Operation Id: %', (SELECT fullname FROM technicians WHERE id = current_technician.Id), current_technician.Id, NEW.Id;
            allocated_technicians := allocated_technicians + 1;
        END LOOP;
    END IF;

    RAISE NOTICE '==================== Automatic Technician Allocation End ======================';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg2_auto_allocate_urgent -- 2 to guarantee second execution in order
    AFTER INSERT ON Operations
    FOR EACH ROW EXECUTE FUNCTION fn_auto_allocate_urgent();


-- ============================================================================
-- TRIGGER 11 (maybe): Non-urgent Operation created + AutoAllocation ON
--            → allocate available technicians
-- ============================================================================
-- For 'Reading' operations: can assign techs already on other Reading tasks
-- if they are below TechnicianMeasurementOperationsLimit.
-- For other operations: only assign free technicians.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_auto_allocate_normal()
RETURNS TRIGGER AS $$
DECLARE
    automatic_allocation BOOL;
    required_technicians INT;
    allocated_technicians INT := 0;
    v_reading_limit INT;
    current_technician RECORD;
BEGIN
    -- Urgent ops are handled by the other trigger
    IF NEW.Priority = 'Urgent' THEN
        RETURN NEW;
    END IF;

    SELECT s.AutomaticTechnicianAllocation, s.TechnicianMeasurementOperationsLimit
    INTO automatic_allocation, v_reading_limit
    FROM Settings s LIMIT 1;

    IF NOT automatic_allocation THEN
        RETURN NEW;
    END IF;

    required_technicians := COALESCE(NEW.RequiredTechnicians, 1);
    RAISE NOTICE '==================== Automatic Technician Allocation Begin ====================';

    IF NEW.Type = 'Reading' THEN
        -- For Reading operations:
        -- Assign techs who are free OR already on Reading tasks below the limit
        FOR current_technician IN
            SELECT t.Id
            FROM Technicians t
            WHERE t.ResignationDate IS NULL
              AND NOT EXISTS (
                  -- Exclude techs with non-Reading open tasks
                  SELECT 1 FROM TechnicianTasks tt
                  JOIN Operations o ON o.Id = tt.Operation
                  WHERE tt.Technician = t.Id
                    AND tt.ReleaseDate IS NULL
                    AND o.Type <> 'Reading'
              )
              AND NOT EXISTS (
                  SELECT 1 FROM TechnicianTasks tt
                  WHERE tt.Technician = t.Id AND tt.Operation = NEW.Id
              )
              AND (
                  SELECT COUNT(*)
                  FROM TechnicianTasks tt
                  JOIN Operations o ON o.Id = tt.Operation
                  WHERE tt.Technician = t.Id
                    AND tt.ReleaseDate IS NULL
                    AND o.Type = 'Reading'
              ) < v_reading_limit
            ORDER BY t.Id
        LOOP
            EXIT WHEN allocated_technicians >= required_technicians;

            INSERT INTO TechnicianTasks (Operation, Technician)
            VALUES (NEW.Id, current_technician.Id);
            RAISE NOTICE 'Technician: %, Id: % - Allocated to Operation Id: %', (SELECT fullname FROM technicians WHERE id = current_technician.Id), current_technician.Id, NEW.Id;
            allocated_technicians := allocated_technicians + 1;
        END LOOP;
    ELSE
        -- For non-Reading operations: only assign completely free technicians
        FOR current_technician IN
            SELECT t.Id
            FROM Technicians t
            WHERE t.ResignationDate IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM TechnicianTasks tt
                  WHERE tt.Technician = t.Id AND tt.ReleaseDate IS NULL
              )
              AND NOT EXISTS (
                  SELECT 1 FROM TechnicianTasks tt
                  WHERE tt.Technician = t.Id AND tt.Operation = NEW.Id
              )
            ORDER BY t.Id
        LOOP
            EXIT WHEN allocated_technicians >= required_technicians;

            INSERT INTO TechnicianTasks (Operation, Technician)
            VALUES (NEW.Id, current_technician.Id);
            RAISE NOTICE 'Technician: %, Id: % - Allocated to Operation Id: %', (SELECT fullname FROM technicians WHERE id = current_technician.Id), current_technician.Id, NEW.Id;
            allocated_technicians := allocated_technicians + 1;
        END LOOP;
    END IF;

    RAISE NOTICE '==================== Automatic Technician Allocation End ======================';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg1_auto_allocate_normal -- 1 to guarantee first execution in order
    AFTER INSERT ON Operations
    FOR EACH ROW EXECUTE FUNCTION fn_auto_allocate_normal();

-- ============================================================================
-- TRIGGER 12: Technician resigned (ResignationDate set)
--             → release all open TechnicianTasks
--             → attempt to reallocate a replacement for each affected Operation
-- ============================================================================
-- Behaviour:
--   - Only fires when ResignationDate transitions from NULL to a value
--   - For each open TechnicianTask of the resigned technician:
--       1. Sets ReleaseDate = CURRENT_TIMESTAMP (releases the task)
--       2. Looks for a replacement technician using the same priority rules
--          as the existing auto-allocation triggers:
--            · Urgent ops  → free tech first, then busy-non-urgent, then anyone
--            · Non-urgent  → free tech only (Reading ops respect the limit)
--       3. If no replacement is found → RAISE WARNING
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_technician_resigned()
RETURNS TRIGGER AS $$
DECLARE
    v_reading_limit       INT;
    open_task             RECORD;   -- cursor over the resigned tech's open tasks
    target_op             RECORD;   -- the Operation row for that task
    replacement_id        BIGINT;
BEGIN
    -- Only fire when ResignationDate goes from NULL → a value
    IF OLD.ResignationDate IS NOT NULL OR NEW.ResignationDate IS NULL THEN
        RETURN NEW;
    END IF;

    -- Fetch settings once
    SELECT s.TechnicianMeasurementOperationsLimit
    INTO v_reading_limit
    FROM Settings s LIMIT 1;

    RAISE NOTICE '====== Resignation: releasing tasks for Technician % (%) ======',
                 NEW.FullName, NEW.Id;

    -- Iterate over every open task belonging to the resigned technician
    FOR open_task IN
        SELECT tt.Operation
        FROM TechnicianTasks tt
        WHERE tt.Technician  = NEW.Id
          AND tt.ReleaseDate IS NULL
    LOOP
        -- 1. Release the task
        UPDATE TechnicianTasks
        SET    ReleaseDate = CURRENT_TIMESTAMP
        WHERE  Technician  = NEW.Id
          AND  Operation   = open_task.Operation;

        -- 2. Load the operation details
        SELECT * INTO target_op
        FROM   Operations
        WHERE  Id = open_task.Operation;

        replacement_id := NULL;

        -- ── URGENT operations: 3-pass allocation (mirrors fn_auto_allocate_urgent) ──
        IF target_op.Priority = 'Urgent' THEN

            -- Pass 1: completely free technician
            SELECT t.Id INTO replacement_id
            FROM   Technicians t
            WHERE  t.ResignationDate IS NULL
              AND  t.Id <> NEW.Id
              AND  NOT EXISTS (
                       SELECT 1 FROM TechnicianTasks tt
                       WHERE  tt.Technician = t.Id AND tt.ReleaseDate IS NULL
                   )
              AND  NOT EXISTS (
                       SELECT 1 FROM TechnicianTasks tt
                       WHERE  tt.Technician = t.Id AND tt.Operation = target_op.Id
                   )
            ORDER BY t.Id
            LIMIT 1;

            -- Pass 2: busy but not on another Urgent op
            IF replacement_id IS NULL THEN
                SELECT t.Id INTO replacement_id
                FROM   Technicians t
                WHERE  t.ResignationDate IS NULL
                  AND  t.Id <> NEW.Id
                  AND  NOT EXISTS (
                           SELECT 1 FROM TechnicianTasks tt
                           JOIN   Operations o ON o.Id = tt.Operation
                           WHERE  tt.Technician  = t.Id
                             AND  tt.ReleaseDate IS NULL
                             AND  o.Priority     = 'Urgent'
                       )
                  AND  NOT EXISTS (
                           SELECT 1 FROM TechnicianTasks tt
                           WHERE  tt.Technician = t.Id AND tt.Operation = target_op.Id
                       )
                ORDER BY t.Id
                LIMIT 1;
            END IF;

            -- Pass 3: last resort – anyone not already on this operation
            IF replacement_id IS NULL THEN
                SELECT t.Id INTO replacement_id
                FROM   Technicians t
                WHERE  t.ResignationDate IS NULL
                  AND  t.Id <> NEW.Id
                  AND  NOT EXISTS (
                           SELECT 1 FROM TechnicianTasks tt
                           WHERE  tt.Technician = t.Id AND tt.Operation = target_op.Id
                       )
                ORDER BY t.Id
                LIMIT 1;
            END IF;

        -- ── NON-URGENT operations: free technician only ──
        ELSIF target_op.Type = 'Reading' THEN

            -- Reading ops: allow techs already on other Reading tasks, up to the limit
            SELECT t.Id INTO replacement_id
            FROM   Technicians t
            WHERE  t.ResignationDate IS NULL
              AND  t.Id <> NEW.Id
              AND  NOT EXISTS (
                       SELECT 1 FROM TechnicianTasks tt
                       JOIN   Operations o ON o.Id = tt.Operation
                       WHERE  tt.Technician  = t.Id
                         AND  tt.ReleaseDate IS NULL
                         AND  o.Type        <> 'Reading'
                   )
              AND  NOT EXISTS (
                       SELECT 1 FROM TechnicianTasks tt
                       WHERE  tt.Technician = t.Id AND tt.Operation = target_op.Id
                   )
              AND (
                       SELECT COUNT(*)
                       FROM   TechnicianTasks tt
                       JOIN   Operations o ON o.Id = tt.Operation
                       WHERE  tt.Technician  = t.Id
                         AND  tt.ReleaseDate IS NULL
                         AND  o.Type         = 'Reading'
                   ) < v_reading_limit
            ORDER BY t.Id
            LIMIT 1;

        ELSE

            -- All other non-urgent ops: only completely free technicians
            SELECT t.Id INTO replacement_id
            FROM   Technicians t
            WHERE  t.ResignationDate IS NULL
              AND  t.Id <> NEW.Id
              AND  NOT EXISTS (
                       SELECT 1 FROM TechnicianTasks tt
                       WHERE  tt.Technician = t.Id AND tt.ReleaseDate IS NULL
                   )
              AND  NOT EXISTS (
                       SELECT 1 FROM TechnicianTasks tt
                       WHERE  tt.Technician = t.Id AND tt.Operation = target_op.Id
                   )
            ORDER BY t.Id
            LIMIT 1;

        END IF;

        -- 3. Assign replacement or warn
        IF replacement_id IS NOT NULL THEN
            INSERT INTO TechnicianTasks (Operation, Technician)
            VALUES (target_op.Id, replacement_id);

            RAISE NOTICE 'Operation %: Technician % replaced by Technician %',
                         target_op.Id, NEW.Id, replacement_id;
        ELSE
            RAISE WARNING
                'Operation % (Type: %, Priority: %): no replacement found for resigned Technician % — manual assignment required.',
                target_op.Id, target_op.Type, target_op.Priority, NEW.Id;
        END IF;

    END LOOP;

    RAISE NOTICE '====== Resignation handling complete for Technician % ======', NEW.Id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_technician_resigned
    AFTER UPDATE OF ResignationDate ON Technicians
    FOR EACH ROW EXECUTE FUNCTION fn_technician_resigned();