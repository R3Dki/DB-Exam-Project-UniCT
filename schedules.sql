-- ============================================================================
-- ROUTINE 1: Daily — Overdue Bill Increase + Disconnection
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_daily_overdue_bills()
RETURNS VOID AS $$
DECLARE
    settings_row        RECORD;
    bill_row            RECORD;
    meter_id            BIGINT;
    days_overdue        DECIMAL;
    increase_amount     DECIMAL(16,2);
BEGIN
    SELECT * INTO settings_row FROM Settings LIMIT 1;

    FOR bill_row IN
        SELECT b.*
        FROM Bills b
        WHERE b.PaymentDate IS NULL
          AND b.DueDate < CURRENT_TIMESTAMP
    LOOP
        -- Get the meter from the reading
        SELECT r.Meter INTO meter_id
        FROM Readings r
        WHERE r.Id = bill_row.Reading
        LIMIT 1;

        days_overdue := EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - bill_row.DueDate)) / 86400;

        -- Check if DisconnectionTimeThreshold is exceeded
        IF (CURRENT_TIMESTAMP - bill_row.DueDate) >= settings_row.DisconnectionTimeThreshold THEN

            -- Issue Detach operation ONLY ONCE
            IF NOT EXISTS (
                SELECT 1 FROM Operations o
                WHERE o.Type        = 'Detach'
                  AND o.TargetType  = 'Meter'
                  AND o.TargetId    = meter_id
                  AND o.CompletionDate IS NULL
                  AND o.Description LIKE 'Overdue bill%'
            ) THEN
                INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
                VALUES (
                    'Detach',
                    'Meter',
                    meter_id,
                    'Overdue bill - disconnection threshold exceeded for Bill #' || bill_row.Id,
                    'Normal',
                    1
                );
            END IF;

        ELSE
            -- Increase bill amount by daily percentile (ONLY if not yet at threshold)
            increase_amount := bill_row.BillAmount * (settings_row.OverdueDailyBillIncreasePercentile / 100.0);

            UPDATE Bills
            SET BillAmount = BillAmount + increase_amount
            WHERE Id = bill_row.Id;
        END IF;

    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- ROUTINE 2: Daily — Check BillingPeriod and issue Reading Operations
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_daily_billing_period_check()
RETURNS VOID AS $$
DECLARE
    contract_row    RECORD;
    last_reading    TIMESTAMP;
    next_due        TIMESTAMP;
BEGIN
    FOR contract_row IN
        SELECT c.*, m.MeterType, m.Id AS MeterId
        FROM Contracts c
        JOIN Meters m ON m.Id = c.Meter
        WHERE c.ContractEndDate IS NULL
          AND c.BillingPeriod IS NOT NULL
          AND m.MeterType = 'Manual'  -- Only Manual meters need a Reading Operation
    LOOP
        -- Get the date of the last reading for this meter
        SELECT MAX(r.Date) INTO last_reading
        FROM Readings r
        WHERE r.Meter = contract_row.MeterId;

        -- If no reading yet, use contract issue date as baseline
        last_reading := COALESCE(last_reading, contract_row.ContractIssueDate);
        next_due     := last_reading + contract_row.BillingPeriod;

        -- Check if billing period has elapsed
        IF CURRENT_TIMESTAMP >= next_due THEN

            -- Issue Reading operation ONLY ONCE (no open one already exists)
            IF NOT EXISTS (
                SELECT 1 FROM Operations o
                WHERE o.Type       = 'Reading'
                  AND o.TargetType = 'Meter'
                  AND o.TargetId   = contract_row.MeterId
                  AND o.CompletionDate IS NULL
            ) THEN
                INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
                VALUES (
                    'Reading',
                    'Meter',
                    contract_row.MeterId,
                    'Scheduled manual reading for Contract #' || contract_row.Id,
                    'Normal',
                    1
                );
            END IF;

        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- ROUTINE 3: Monthly — Generate Salaries for all active Technicians
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_monthly_salaries()
RETURNS VOID AS $$
DECLARE
    tech_row RECORD;
BEGIN
    FOR tech_row IN
        SELECT t.Id, t.Wage
        FROM Technicians t
        WHERE t.ResignationDate IS NULL
          OR t.ResignationDate > DATE_TRUNC('month', CURRENT_TIMESTAMP)
    LOOP
        -- Only insert if salary for this month hasn't been issued yet
        IF NOT EXISTS (
            SELECT 1 FROM Salaries s
            WHERE s.Technician   = tech_row.Id
              AND DATE_TRUNC('month', s.PaymentDate) = DATE_TRUNC('month', CURRENT_TIMESTAMP)
        ) THEN
            INSERT INTO Salaries (Technician, WageAmount)
            VALUES (tech_row.Id, tech_row.Wage);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- SCHEDULING with pg_cron
-- Run: CREATE EXTENSION IF NOT EXISTS pg_cron;
-- ============================================================================

-- Daily at midnight
SELECT cron.schedule('daily-overdue-bills',       '0 0 * * *', 'SELECT fn_daily_overdue_bills()');
SELECT cron.schedule('daily-billing-period-check', '0 0 * * *', 'SELECT fn_daily_billing_period_check()');

-- First day of every month
SELECT cron.schedule('monthly-salaries', '0 0 1 * *', 'SELECT fn_monthly_salaries()');