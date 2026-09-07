-- ============================================================================
-- VIEWS
-- ============================================================================


-- ============================================================================
-- 1. Total Flowrate per Client
--    Shows each client's total allocated flowrate across all active contracts
-- ============================================================================
CREATE OR REPLACE VIEW vw_flowrate_per_client AS
SELECT
    cl.Id                               AS ClientId,
    cl.Name                             AS ClientName,
    c.ClientType,
    COUNT(c.Id)                         AS ActiveContracts,
    SUM(c.AllocatedFlowrate)            AS TotalAllocatedFlowrateLps
FROM Clients cl
JOIN Contracts c ON c.Client = cl.Id
WHERE c.ContractEndDate IS NULL
  AND c.AllocatedFlowrate IS NOT NULL
GROUP BY cl.Id, cl.Name, c.ClientType
ORDER BY TotalAllocatedFlowrateLps DESC;


-- ============================================================================
-- 2. Total Flowrate Overview
--    3 rows: total pump supply, total industrial demand, total civil demand
-- ============================================================================
CREATE OR REPLACE VIEW vw_flowrate_overview AS
SELECT 'Pump Supply'      AS Category,
       COALESCE(SUM(p.MaxFlowRateLps), 0) AS TotalFlowrateLps
FROM Pumps p
WHERE p.Status = 'Online'

UNION ALL

SELECT 'Industrial Demand',
       COALESCE(SUM(c.AllocatedFlowrate), 0)
FROM Contracts c
WHERE c.ContractEndDate IS NULL
  AND c.ClientType = 'Industrial'

UNION ALL

SELECT 'Civil Demand',
       COALESCE(SUM(c.AllocatedFlowrate), 0)
FROM Contracts c
WHERE c.ContractEndDate IS NULL
  AND c.ClientType = 'Civil';


-- ============================================================================
-- 3. Clients Average Consumption
--    Average monthly consumption per client and per contract (metered only)
-- ============================================================================
CREATE OR REPLACE VIEW vw_avg_consumption AS
SELECT
    cl.Id                                           AS ClientId,
    cl.Name                                         AS ClientName,
    c.Id                                            AS ContractId,
    c.ClientType,
    COUNT(r.Id)                                     AS TotalReadings,
    ROUND(AVG(r.Volume), 2)                         AS AvgCumulativeVolume,
    ROUND(
        AVG(r.Volume - COALESCE((
            SELECT r2.Volume
            FROM Readings r2
            WHERE r2.Meter = r.Meter
              AND r2.Date < r.Date
            ORDER BY r2.Date DESC
            LIMIT 1
        ), 0))
    , 2)                                            AS AvgMonthlyConsumptionM3
FROM Clients cl
JOIN Contracts c  ON c.Client = cl.Id
JOIN Meters m     ON m.Id = c.Meter
JOIN Readings r   ON r.Meter = m.Id
WHERE c.ClientType IN ('Civil', 'Industrial')
GROUP BY cl.Id, cl.Name, c.Id, c.ClientType
ORDER BY cl.Name, c.Id;


-- ============================================================================
-- 4. Clients and Their Contracts
-- ============================================================================
CREATE OR REPLACE VIEW vw_client_contracts AS
SELECT
    cl.Id                                           AS ClientId,
    cl.Name                                         AS ClientName,
    cl.City                                         AS ClientCity,
    c.Id                                            AS ContractId,
    c.ClientType,
    c.PropertyCity,
    c.PropertyAddress,
    c.AllocatedFlowrate                             AS AllocatedFlowrateLps,
    c.EstablishedBillCost,
    c.BillingPeriod,
    c.ContractIssueDate,
    c.ContractEndDate,
    CASE WHEN c.ContractEndDate IS NULL
         THEN 'Active' ELSE 'Ended' END             AS ContractStatus,
    m.SerialNumber                                  AS MeterSerial,
    m.MeterType,
    m.Status                                        AS MeterStatus
FROM Clients cl
JOIN Contracts c ON c.Client = cl.Id
LEFT JOIN Meters m ON m.Id = c.Meter
ORDER BY cl.Name, c.ContractIssueDate;


-- ============================================================================
-- 5. Monthly Expenses and Gains (in a time period)
--    Gains  = Bills paid in that month
--    Losses = Operation costs + Salaries paid in that month
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_financials AS
WITH monthly_gains AS (
    SELECT
        DATE_TRUNC('month', b.PaymentDate)          AS Month,
        SUM(b.BillAmount)                           AS TotalGains
    FROM Bills b
    WHERE b.PaymentDate IS NOT NULL
    GROUP BY DATE_TRUNC('month', b.PaymentDate)
),
monthly_op_costs AS (
    SELECT
        DATE_TRUNC('month', o.CompletionDate)       AS Month,
        SUM(o.OperationCost)                        AS TotalOperationCosts
    FROM Operations o
    WHERE o.CompletionDate IS NOT NULL
      AND o.OperationCost IS NOT NULL
    GROUP BY DATE_TRUNC('month', o.CompletionDate)
),
monthly_salaries AS (
    SELECT
        DATE_TRUNC('month', s.PaymentDate)          AS Month,
        SUM(s.WageAmount)                           AS TotalSalaries
    FROM Salaries s
    GROUP BY DATE_TRUNC('month', s.PaymentDate)
)
SELECT
    COALESCE(g.Month, oc.Month, sal.Month)          AS Month,
    COALESCE(g.TotalGains, 0)                       AS Gains,
    COALESCE(oc.TotalOperationCosts, 0)             AS OperationCosts,
    COALESCE(sal.TotalSalaries, 0)                  AS SalaryCosts,
    COALESCE(oc.TotalOperationCosts, 0)
        + COALESCE(sal.TotalSalaries, 0)            AS TotalExpenses,
    COALESCE(g.TotalGains, 0)
        - COALESCE(oc.TotalOperationCosts, 0)
        - COALESCE(sal.TotalSalaries, 0)            AS NetResult
FROM monthly_gains g
FULL OUTER JOIN monthly_op_costs oc  ON oc.Month  = g.Month
FULL OUTER JOIN monthly_salaries sal ON sal.Month = COALESCE(g.Month, oc.Month)
ORDER BY Month;


-- ============================================================================
-- 6. Total Financials Summary
--    For tracking overall money: total gains, total costs, net balance.
--    Note: to track an initial investment/capital, insert it manually into
--    a dedicated table or add a starting_capital parameter here.
--    This view gives you the NET RESULT from all recorded transactions.
-- ============================================================================
CREATE OR REPLACE VIEW vw_total_financials AS
SELECT
    (SELECT COALESCE(SUM(b.BillAmount), 0)
     FROM Bills b
     WHERE b.PaymentDate IS NOT NULL)               AS TotalGains,

    (SELECT COALESCE(SUM(o.OperationCost), 0)
     FROM Operations o
     WHERE o.OperationCost IS NOT NULL)             AS TotalOperationCosts,

    (SELECT COALESCE(SUM(s.WageAmount), 0)
     FROM Salaries s)                               AS TotalSalaryCosts,

    (SELECT COALESCE(SUM(o.OperationCost), 0)
     FROM Operations o WHERE o.OperationCost IS NOT NULL)
    +
    (SELECT COALESCE(SUM(s.WageAmount), 0)
     FROM Salaries s)                               AS TotalExpenses,

    (SELECT COALESCE(SUM(b.BillAmount), 0)
     FROM Bills b WHERE b.PaymentDate IS NOT NULL)
    -
    (SELECT COALESCE(SUM(o.OperationCost), 0)
     FROM Operations o WHERE o.OperationCost IS NOT NULL)
    -
    (SELECT COALESCE(SUM(s.WageAmount), 0)
     FROM Salaries s)                               AS NetBalance;

-- NOTE: If you want to track an initial capital/investment, create this table:
--
--   CREATE TABLE IF NOT EXISTS Capital (
--       Id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
--       Amount      DECIMAL(16,2) NOT NULL,
--       Description TEXT,
--       Date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
--   );
--
-- Then add it to the NetBalance calculation:
--   + (SELECT COALESCE(SUM(Amount), 0) FROM Capital)


-- ============================================================================
-- 7. Technician Wages
--    Current wage for each active technician
-- ============================================================================
CREATE OR REPLACE VIEW vw_technician_wages AS
SELECT
    t.Id                                            AS TechnicianId,
    t.FullName,
    t.FiscalCode,
    t.Wage                                          AS MonthlyWage,
    t.EmploymentDate,
    t.ResignationDate,
    CASE WHEN t.ResignationDate IS NULL
         THEN 'Active' ELSE 'Resigned' END          AS Status
FROM Technicians t
ORDER BY t.FullName;


-- ============================================================================
-- 8. Total Money Spent on Technician Wages
-- ============================================================================
CREATE OR REPLACE VIEW vw_total_salary_expenses AS
SELECT
    t.Id                                            AS TechnicianId,
    t.FullName,
    COUNT(s.Id)                                     AS TotalPayments,
    SUM(s.WageAmount)                               AS TotalPaid,
    MIN(s.PaymentDate)                              AS FirstPayment,
    MAX(s.PaymentDate)                              AS LastPayment
FROM Technicians t
LEFT JOIN Salaries s ON s.Technician = t.Id
GROUP BY t.Id, t.FullName
ORDER BY TotalPaid DESC;


-- ============================================================================
-- 9. Total Operation Expenses
-- ============================================================================
CREATE OR REPLACE VIEW vw_total_operation_expenses AS
SELECT
    COALESCE(SUM(o.OperationCost), 0)              AS TotalOperationCost,
    COUNT(o.Id)                                     AS TotalOperations,
    COUNT(o.Id) FILTER (WHERE o.CompletionDate IS NOT NULL) AS CompletedOperations,
    COUNT(o.Id) FILTER (WHERE o.CompletionDate IS NULL)     AS OpenOperations,
    ROUND(AVG(o.OperationCost), 2)                 AS AvgOperationCost,
    MAX(o.OperationCost)                            AS MaxOperationCost,
    MIN(o.OperationCost)                            AS MinOperationCost
FROM Operations o;


-- ============================================================================
-- 10. Monthly Operation Expenses
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_operation_expenses AS
SELECT
    DATE_TRUNC('month', o.CompletionDate)           AS Month,
    COUNT(o.Id)                                     AS OperationCount,
    COALESCE(SUM(o.OperationCost), 0)              AS TotalCost,
    ROUND(AVG(o.OperationCost), 2)                 AS AvgCost
FROM Operations o
WHERE o.CompletionDate IS NOT NULL
GROUP BY DATE_TRUNC('month', o.CompletionDate)
ORDER BY Month;


-- ============================================================================
-- 11. Operations per Month — Count and Cost
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_operations_summary AS
SELECT
    DATE_TRUNC('month', o.IssueDate)               AS Month,
    COUNT(o.Id)                                     AS TotalOperations,
    COALESCE(SUM(o.OperationCost), 0)              AS TotalCost
FROM Operations o
GROUP BY DATE_TRUNC('month', o.IssueDate)
ORDER BY Month;


-- ============================================================================
-- 12. Operations per Month — Separated by Type
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_operations_by_type AS
SELECT
    DATE_TRUNC('month', o.IssueDate)               AS Month,
    o.Type                                          AS OperationType,
    COUNT(o.Id)                                     AS OperationCount,
    COALESCE(SUM(o.OperationCost), 0)              AS TotalCost,
    ROUND(AVG(o.OperationCost), 2)                 AS AvgCost
FROM Operations o
GROUP BY DATE_TRUNC('month', o.IssueDate), o.Type
ORDER BY Month, o.Type;


-- ============================================================================
-- 13. Average Client Payment Punctuality
--    Average days between Bill IssuingDate and PaymentDate
--    Positive = paid late, Negative = paid early (unlikely but possible)
-- ============================================================================
CREATE OR REPLACE VIEW vw_payment_punctuality AS
SELECT
    cl.Id                                                       AS ClientId,
    cl.Name                                                     AS ClientName,
    c.Id                                                        AS ContractId,
    c.ClientType,
    COUNT(b.Id)                                                 AS TotalBillsPaid,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (b.PaymentDate - b.DueDate)) / 86400
    )::NUMERIC, 1)                                             AS AvgDaysFromDueDate,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (b.PaymentDate - b.IssuingDate)) / 86400
    )::NUMERIC, 1)                                             AS AvgDaysToPayFromIssue,
    COUNT(b.Id) FILTER (WHERE b.PaymentDate > b.DueDate)       AS LatePayments,
    COUNT(b.Id) FILTER (WHERE b.PaymentDate <= b.DueDate)      AS OnTimePayments
FROM Clients cl
JOIN Contracts c ON c.Client = cl.Id
JOIN Bills b     ON b.Contract = c.Id
WHERE b.PaymentDate IS NOT NULL
GROUP BY cl.Id, cl.Name, c.Id, c.ClientType
ORDER BY AvgDaysFromDueDate DESC;


-- ============================================================================
-- 14. Total Amount Paid by Client (across all contracts)
-- ============================================================================
CREATE OR REPLACE VIEW vw_total_paid_per_client AS
SELECT
    cl.Id                                           AS ClientId,
    cl.Name                                         AS ClientName,
    cl.City,
    COUNT(DISTINCT c.Id)                            AS TotalContracts,
    COUNT(b.Id)                                     AS TotalBillsPaid,
    COALESCE(SUM(b.BillAmount), 0)                 AS TotalAmountPaid,
    COUNT(b.Id) FILTER (WHERE b.PaymentDate IS NULL) AS UnpaidBills,
    COALESCE(SUM(b.BillAmount)
        FILTER (WHERE b.PaymentDate IS NULL), 0)   AS OutstandingAmount
FROM Clients cl
JOIN Contracts c ON c.Client = cl.Id
LEFT JOIN Bills b ON b.Contract = c.Id
GROUP BY cl.Id, cl.Name, cl.City
ORDER BY TotalAmountPaid DESC;


-- ============================================================================
-- 15. Monthly Amount Paid by Client
--    Total of paid bills per client per month, across all their contracts
-- ============================================================================
CREATE OR REPLACE VIEW vw_monthly_paid_per_client AS
SELECT
    cl.Id                                           AS ClientId,
    cl.Name                                         AS ClientName,
    DATE_TRUNC('month', b.PaymentDate)              AS Month,
    COUNT(b.Id)                                     AS BillsPaid,
    SUM(b.BillAmount)                               AS TotalPaid
FROM Clients cl
JOIN Contracts c ON c.Client = cl.Id
JOIN Bills b     ON b.Contract = c.Id
WHERE b.PaymentDate IS NOT NULL
GROUP BY cl.Id, cl.Name, DATE_TRUNC('month', b.PaymentDate)
ORDER BY cl.Name, Month;