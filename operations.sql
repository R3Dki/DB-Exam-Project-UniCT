-- ============================================================================
-- operations.sql
-- Operazioni definite nella sezione 2.4 della relazione
-- Rete di Distribuzione Idrica — Antonio Smeraldi, Mat. 1000075024
--
-- NOTA: le operazioni della Cat. 1 sono racchiuse in una singola transazione
-- per rispettare le dipendenze FK: Nodes -> Pumps/Pipes -> Meters -> Contracts
-- ============================================================================


-- ============================================================================
-- CATEGORIA 1: Gestione dell'infrastruttura di rete
-- ============================================================================

-- Op. 1 — Inserimento elementi di rete in ordine FK-safe
BEGIN;

INSERT INTO Nodes (Latitude, Longitude, Status) VALUES (45.4654, 9.1859, 'Offline');
INSERT INTO Nodes (Latitude, Longitude, Status) VALUES (45.4701, 9.1923, 'Offline');
INSERT INTO Nodes (Latitude, Longitude, Status) VALUES (45.4623, 9.1801, 'Offline');

-- Op. 1b: Pompe (dipendono da Nodes)
INSERT INTO pumps (model, serialnumber, attachedto, powerkw, maxflowratelps, installationdate)
VALUES ('TEST', 'SPS203s203', 1, 20.5, 30, NULL);

-- Op. 1c: Condotte (dipendono da Nodes, richiedono almeno 2 nodi)
INSERT INTO Pipes (NodeA, NodeB, CrossSection, Length, Status)
VALUES (1, 2, 0.0314, 120.00, 'Offline');    -- Id = 1

INSERT INTO Pipes (NodeA, NodeB, CrossSection, Length, Status)
VALUES (2, 3, 0.0314,  95.00, 'Offline');    -- Id = 2

INSERT INTO Pipes (NodeA, NodeB, CrossSection, Length, Status)
VALUES (1, 3, 0.0201, 200.00, 'Offline');    -- Id = 3

-- Op. 1d: Contatori (dipendono da Pipes)
-- Normalmente creati automaticamente dal trigger trg_contract_new_meter (Op. 4).
-- Insert manuale solo se necessario:
INSERT INTO Meters (SerialNumber, MeterType, AttachedTo, Status)
VALUES ('MTR-000000001', 'Smart',      1, 'Disconnected');

INSERT INTO Meters (SerialNumber, MeterType, AttachedTo, Status)
VALUES ('MTR-000000002', 'Smart',      2, 'Disconnected');

INSERT INTO Meters (SerialNumber, MeterType, AttachedTo, Status)
VALUES ('MTR-000000003', 'NotPresent', 3, 'Disconnected');

COMMIT;


-- ----------------------------------------------------------------------------
-- Op. 2 — Aggiornamento stato elemento di rete
-- Il trigger trg_*_operation_completed chiude l'operazione aperta.
-- Il trigger trg_*_fault_maintenance apre una nuova operazione se Fault/Maintenance.
-- Il trigger trg_free_technicians_on_operation_completion rilascia i tecnici.

UPDATE Nodes  SET Status = 'Maintenance' WHERE Id = 1;
UPDATE Pumps  SET Status = 'Online'      WHERE Id = 1;
UPDATE Pipes  SET Status = 'Fault'       WHERE Id = 1;
UPDATE Meters SET Status = 'Online'      WHERE Id = 1;


-- ============================================================================
-- CATEGORIA 2: Gestione di clienti e contratti
-- ============================================================================

-- Op. 3 — Registrazione nuovo cliente (nessuna dipendenza FK)
INSERT INTO Clients (Name, City, ZIPCode, Address, Phone, Email)
VALUES ('Mario Rossi',    'Milano', '20121', 'Via Dante 12',    '+39 02 1234567', 'mario.rossi@email.it');

INSERT INTO Clients (Name, City, ZIPCode, Address, Phone, Email)
VALUES ('Acque SpA',      'Milano', '20122', 'Via Manzoni 5',   '+39 02 9876543', 'info@acquespa.it');

INSERT INTO Clients (Name, City, ZIPCode, Address, Phone, Email)
VALUES ('Giulia Bianchi', 'Milano', '20135', 'Corso XXII Marzo 8', '+39 02 5556677', 'g.bianchi@email.it');


-- ----------------------------------------------------------------------------
-- Op. 4 — Stipula nuovo contratto
-- Il trigger trg_contract_new_meter (BEFORE INSERT) crea automaticamente il Meter
-- e imposta Contracts.Meter prima della scrittura della riga.
-- Dipende da: Clients (deve esistere prima).

-- Contratto Civil
INSERT INTO Contracts (
    Client, PropertyCity, PropertyZIPCode, PropertyAddress,
    ClientType, EstablishedBillCost, AllocatedFlowrate, ContractIssueDate
)
VALUES (1, 'Milano', '20121', 'Via Dante 12', 'Civil', NULL, 0.15, CURRENT_TIMESTAMP);

-- Contratto NonMetered (canone fisso)
INSERT INTO Contracts (
    Client, PropertyCity, PropertyZIPCode, PropertyAddress,
    ClientType, EstablishedBillCost, AllocatedFlowrate, ContractIssueDate
)
VALUES (2, 'Milano', '20122', 'Via Manzoni 5', 'NonMetered', 45.00, 2.50, CURRENT_TIMESTAMP);

-- Contratto Industrial
INSERT INTO Contracts (
    Client, PropertyCity, PropertyZIPCode, PropertyAddress,
    ClientType, EstablishedBillCost, AllocatedFlowrate, ContractIssueDate
)
VALUES (3, 'Milano', '20135', 'Corso XXII Marzo 8', 'Industrial', NULL, 1.20, CURRENT_TIMESTAMP);


-- ----------------------------------------------------------------------------
-- Op. 5 — Chiusura contratto
-- Il trigger trg_contract_ended emette automaticamente operazione Detach sul Meter.
UPDATE Contracts
SET ContractEndDate = CURRENT_TIMESTAMP
WHERE Id = 1
  AND ContractEndDate IS NULL;


-- ============================================================================
-- CATEGORIA 3: Letture e fatturazione
-- ============================================================================

-- Op. 6 — Inserimento lettura contatore
-- Il trigger trg_reading_create_bill genera automaticamente la bolletta.
-- Dipende da: Meters (deve esistere e avere un contratto attivo).

-- Lettura automatica da contatore Smart (Technician = NULL)
INSERT INTO Readings (Meter, Volume, Technician)
VALUES (1, 1247.83, NULL);

-- Lettura manuale da tecnico
INSERT INTO Readings (Meter, Volume, Technician)
VALUES (2, 530.10, 3);


-- ----------------------------------------------------------------------------
-- Op. 7 — Registrazione pagamento bolletta
-- Il trigger trg_overdue_paid_reattach verifica se riconnettere il contatore.
-- Dipende da: Bills (deve esistere, generata da Op. 6).
UPDATE Bills
SET PaymentDate = CURRENT_TIMESTAMP
WHERE Id = 1
  AND PaymentDate IS NULL;


-- ============================================================================
-- CATEGORIA 4: Gestione di tecnici e operazioni tecniche
-- ============================================================================

-- Op. 8 — Inserimento nuovo tecnico (nessuna dipendenza FK)
INSERT INTO Technicians (FullName, FiscalCode, IBAN, Wage, EmploymentDate)
VALUES ('Luca Ferrari',   'FRRLCU90A01F205X', 'IT60X0542811101000000123456', 1800.00, CURRENT_TIMESTAMP);

INSERT INTO Technicians (FullName, FiscalCode, IBAN, Wage, EmploymentDate)
VALUES ('Sara Conti',     'CNTSRA88B41F205Y', 'IT40Q0306909606100000006789', 1950.00, CURRENT_TIMESTAMP);

INSERT INTO Technicians (FullName, FiscalCode, IBAN, Wage, EmploymentDate)
VALUES ('Marco Esposito', 'SPSMRC85C15H501Z', 'IT23A0200805364000400057321', 1750.00, CURRENT_TIMESTAMP);


-- ----------------------------------------------------------------------------
-- Op. 9 — Dimissioni tecnico
-- Il trigger trg_technician_resigned libera i task e cerca sostituti.
UPDATE Technicians
SET ResignationDate = CURRENT_TIMESTAMP
WHERE Id = 3
  AND ResignationDate IS NULL;


-- ----------------------------------------------------------------------------
-- Op. 10 — Creazione manuale operazione tecnica
-- I trigger trg1/trg2_auto_allocate assegnano i tecnici automaticamente.
-- Dipende da: elemento target (Node/Pump/Pipe/Meter) deve esistere.

INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
VALUES ('Check',  'Pump', 1, 'Ispezione periodica pompa principale',        'Normal', 1);

INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
VALUES ('Repair', 'Node', 2, 'Guasto nodo di distribuzione zona nord',      'Urgent', 2);

INSERT INTO Operations (Type, TargetType, TargetId, Description, Priority, RequiredTechnicians)
VALUES ('Reading', 'Meter', 1, 'Lettura manuale contatore zona centro',     'Normal', 1);


-- ----------------------------------------------------------------------------
-- Op. 11 — Chiusura manuale operazione tecnica
-- Il trigger trg_free_technicians rilascia i tecnici assegnati.
-- Dipende da: Operations (deve esistere con CompletionDate NULL).
UPDATE Operations
SET CompletionDate = CURRENT_TIMESTAMP
WHERE Id = 1
  AND CompletionDate IS NULL;


-- ----------------------------------------------------------------------------
-- Op. 12 — Assegnazione manuale tecnico a operazione
-- Dipende da: Operations e Technicians (devono esistere entrambi).
INSERT INTO TechnicianTasks (Operation, Technician)
VALUES (2, 1);

INSERT INTO TechnicianTasks (Operation, Technician)
VALUES (2, 2);


-- ============================================================================
-- CATEGORIA 5: Operazioni automatiche e batch (trigger / pg_cron)
-- ============================================================================

-- Op. 13a/13b — Allocazione automatica tecnici
-- Gestita dai trigger trg1_auto_allocate_normal e trg2_auto_allocate_urgent.
-- Nessuna query manuale richiesta.

-- Op. 14 — Verifica capacita portata rete
-- Gestita dal trigger trg_check_flowrate_capacity su AFTER INSERT ON Meters.
-- Nessuna query manuale richiesta.

-- Op. 15 — Disconnessione automatica contatori inattivi (ogni giorno alle 02:00)
SELECT cron.schedule(
    'disconnetti-contatori-inattivi',
    '0 2 * * *',
    $$
    UPDATE Meters m
    SET Status = 'Disconnected'
    WHERE m.Status NOT IN ('Disconnected', 'Offline')
      AND NOT EXISTS (
          SELECT 1 FROM Readings r
          WHERE r.Meter = m.Id
            AND r.Date >= CURRENT_TIMESTAMP - (
                SELECT s.DisconnectionTimeThreshold * INTERVAL '1 day'
                FROM Settings s LIMIT 1
            )
      )
      AND EXISTS (
          SELECT 1 FROM Contracts c
          WHERE c.Meter = m.Id
            AND c.ContractEndDate IS NULL
      );
    $$
);

-- Op. 16 — Generazione stipendi mensili (1° del mese alle 06:00)
SELECT cron.schedule(
    'genera-stipendi-mensili',
    '0 6 1 * *',
    $$
    INSERT INTO Salaries (Technician, WageAmount, PaymentDate)
    SELECT Id, Wage, CURRENT_TIMESTAMP
    FROM Technicians
    WHERE ResignationDate IS NULL;
    $$
);


-- ============================================================================
-- CATEGORIA 6: Consultazioni e reportistica
-- ============================================================================

-- Op. 17 — Portata allocata per cliente e overview supply/demand
SELECT * FROM vw_flowrate_per_client;
SELECT * FROM vw_flowrate_overview;

-- Op. 18 — Consumo medio per cliente e per contratto
SELECT * FROM vw_avg_consumption;

-- Op. 19 — Clienti, contratti e stato contatori
SELECT * FROM vw_client_contracts;

-- Op. 20 — Conto economico mensile e bilancio totale
SELECT * FROM vw_monthly_financials;

-- Op. 21 — Spese stipendi e statistiche operazioni tecniche
SELECT * FROM vw_technician_wages;
SELECT * FROM vw_total_salary_expenses;
SELECT * FROM vw_total_operation_expenses;
SELECT * FROM vw_monthly_operation_expenses;

-- Op. 22 — Puntualita pagamenti e totale fatturato per cliente
SELECT * FROM vw_payment_punctuality;
SELECT * FROM vw_total_paid_per_client;


-- ============================================================================
-- CATEGORIA 7: Configurazione del sistema
-- ============================================================================

-- Op. 23 — Aggiornamento fasce di tassazione progressiva
-- Configurazione iniziale (3 fasce):
INSERT INTO ProgressiveTaxation (MinimumVolume, PricePerCubicMeter) VALUES (  0.00, 0.45);
INSERT INTO ProgressiveTaxation (MinimumVolume, PricePerCubicMeter) VALUES ( 50.00, 0.72);
INSERT INTO ProgressiveTaxation (MinimumVolume, PricePerCubicMeter) VALUES (150.00, 1.10);

-- Aggiornamento prezzo fascia base
UPDATE ProgressiveTaxation SET PricePerCubicMeter = 0.50 WHERE MinimumVolume = 0.00;

-- Rimozione fascia obsoleta
DELETE FROM ProgressiveTaxation WHERE MinimumVolume = 150.00;


-- ----------------------------------------------------------------------------
-- Op. 24 — Modifica parametri di configurazione globale (Settings singleton)
UPDATE Settings
SET
    DisconnectionTimeThreshold           = COALESCE(NULL,  DisconnectionTimeThreshold),
    CivilDefaultFlowrate                 = COALESCE(NULL,  CivilDefaultFlowrate),
    MaxAllowedFlowrateBottleneck         = COALESCE(20,    MaxAllowedFlowrateBottleneck),
    AutomaticTechnicianAllocation        = COALESCE(NULL,  AutomaticTechnicianAllocation),
    TechnicianMeasurementOperationsLimit = COALESCE(NULL,  TechnicianMeasurementOperationsLimit),
    OverdueDailyBillIncreasePercentile   = COALESCE(NULL,  OverdueDailyBillIncreasePercentile);