-- ============================================================================
-- SEED DATA SCRIPT
-- Compatible with the provided schema (triggers disabled during seeding)
-- Run this AFTER the schema and triggers have been created.
-- ============================================================================

-- Disable triggers during seeding to avoid side effects
SET session_replication_role = replica;

-- ============================================================================
-- PROGRESSIVE TAXATION (10 rows)
-- ============================================================================
INSERT INTO ProgressiveTaxation (MinimumVolume, PricePerCubicMeter) VALUES
(0,     0.45),
(10,    0.60),
(25,    0.80),
(50,    1.05),
(100,   1.35),
(200,   1.70),
(350,   2.10),
(500,   2.60),
(750,   3.20),
(1000,  4.00);


-- ============================================================================
-- NODES (40 rows)
-- ============================================================================
INSERT INTO Nodes (Latitude, Longitude, Status, InstallationDate) VALUES
-- Milano area
(45.46427400, 9.18951000, 'Online',      '2018-03-10 08:00:00'),
(45.47012300, 9.20143200, 'Online',      '2018-03-12 08:00:00'),
(45.45891200, 9.17634100, 'Online',      '2018-04-01 08:00:00'),
(45.48234500, 9.21567800, 'Maintenance', '2018-04-15 08:00:00'),
(45.46100000, 9.19800000, 'Online',      '2019-01-20 08:00:00'),
-- Roma area
(41.89474100, 12.48220800, 'Online',     '2017-06-05 08:00:00'),
(41.90123400, 12.47654300, 'Online',     '2017-06-10 08:00:00'),
(41.88765400, 12.49012300, 'Online',     '2017-07-01 08:00:00'),
(41.91234500, 12.46789000, 'Fault',      '2017-07-15 08:00:00'),
(41.89000000, 12.48500000, 'Online',     '2018-02-10 08:00:00'),
-- Napoli area
(40.85315400, 14.26812300, 'Online',     '2016-09-01 08:00:00'),
(40.86012300, 14.27543200, 'Online',     '2016-09-15 08:00:00'),
(40.84876500, 14.25987600, 'Online',     '2016-10-01 08:00:00'),
(40.85500000, 14.27000000, 'Offline',    NULL),
(40.86500000, 14.26200000, 'Online',     '2017-03-20 08:00:00'),
-- Torino area
(45.07049800, 7.68676200, 'Online',      '2019-05-10 08:00:00'),
(45.07654300, 7.69234500, 'Online',      '2019-05-12 08:00:00'),
(45.06543200, 7.67891000, 'Online',      '2019-06-01 08:00:00'),
(45.07200000, 7.68900000, 'Maintenance', '2019-06-15 08:00:00'),
(45.08123400, 7.70012300, 'Online',      '2020-01-10 08:00:00'),
-- Palermo area
(38.11568900, 13.36148000, 'Online',     '2020-03-01 08:00:00'),
(38.12012300, 13.37012300, 'Online',     '2020-03-15 08:00:00'),
(38.11234500, 13.35678900, 'Online',     '2020-04-01 08:00:00'),
(38.11800000, 13.36500000, 'Online',     '2020-04-20 08:00:00'),
(38.12500000, 13.35900000, 'Fault',      '2020-05-10 08:00:00'),
-- Bologna area
(44.49381000, 11.34259200, 'Online',     '2018-08-01 08:00:00'),
(44.50012300, 11.35123400, 'Online',     '2018-08-15 08:00:00'),
(44.48765400, 11.33456700, 'Online',     '2018-09-01 08:00:00'),
(44.49600000, 11.34800000, 'Online',     '2018-09-20 08:00:00'),
(44.50500000, 11.33900000, 'Online',     '2019-02-10 08:00:00'),
-- Firenze area
(43.77925200, 11.24626000, 'Online',     '2017-11-01 08:00:00'),
(43.78456700, 11.25345600, 'Online',     '2017-11-15 08:00:00'),
(43.77234500, 11.23987600, 'Online',     '2017-12-01 08:00:00'),
(43.78100000, 11.24900000, 'Maintenance','2018-01-10 08:00:00'),
(43.79012300, 11.24100000, 'Online',     '2018-02-01 08:00:00'),
-- Catania area
(37.50251100, 15.08719000, 'Online',     '2021-02-01 08:00:00'),
(37.50876500, 15.09456700, 'Online',     '2021-02-15 08:00:00'),
(37.49876500, 15.08012300, 'Online',     '2021-03-01 08:00:00'),
(37.50500000, 15.09000000, 'Online',     '2021-03-20 08:00:00'),
(37.51234500, 15.08300000, 'Offline',    NULL);


-- ============================================================================
-- PUMPS (5 rows)
-- ============================================================================
INSERT INTO Pumps (Model, SerialNumber, AttachedTo, PowerKw, MaxFlowRateLps, Status, InstallationDate) VALUES
('Grundfos CR10-8',    'GF-CR10-001', 1,  15.00, 28.50, 'Online',      '2018-03-15 10:00:00'),
('Grundfos CR15-4',    'GF-CR15-002', 6,  22.00, 42.00, 'Online',      '2017-06-10 10:00:00'),
('KSB Etanorm 32-200', 'KSB-ET-003',  11, 18.50, 35.00, 'Online',      '2016-09-05 10:00:00'),
('Lowara e-SV 4',      'LW-SV4-004',  16, 11.00, 20.00, 'Maintenance', '2019-05-15 10:00:00'),
('Wilo MVI 406',       'WL-MV-005',   21, 13.50, 25.00, 'Online',      '2020-03-05 10:00:00');


-- ============================================================================
-- PIPES (20 rows — connecting nearby nodes)
-- ============================================================================
INSERT INTO Pipes (NodeA, NodeB, CrossSection, Length, Status, InstallationDate) VALUES
-- Milano
(1, 2,   15.000, 320.50,  'Online', '2018-04-01 08:00:00'),
(2, 3,   12.500, 280.75,  'Online', '2018-04-05 08:00:00'),
(3, 5,   10.000, 195.30,  'Online', '2019-02-01 08:00:00'),
(1, 4,   14.000, 410.00,  'Online', '2018-05-10 08:00:00'),
-- Roma
(6, 7,   18.000, 350.00,  'Online', '2017-07-01 08:00:00'),
(7, 8,   16.500, 290.25,  'Online', '2017-07-10 08:00:00'),
(8, 10,  14.000, 180.00,  'Online', '2018-03-01 08:00:00'),
(6, 9,   12.000, 450.80,  'Online', '2017-08-01 08:00:00'),
-- Napoli
(11, 12, 16.000, 310.60,  'Online', '2016-10-01 08:00:00'),
(12, 13, 14.500, 265.40,  'Online', '2016-10-15 08:00:00'),
(13, 15, 12.000, 200.10,  'Online', '2017-04-01 08:00:00'),
-- Torino
(16, 17, 13.000, 295.75,  'Online', '2019-06-01 08:00:00'),
(17, 18, 11.500, 240.50,  'Online', '2019-06-15 08:00:00'),
(16, 20, 15.000, 380.20,  'Online', '2020-02-01 08:00:00'),
-- Palermo
(21, 22, 12.000, 270.30,  'Online', '2020-04-15 08:00:00'),
(22, 24, 10.500, 215.60,  'Online', '2020-05-01 08:00:00'),
-- Bologna
(26, 27, 14.000, 305.90,  'Online', '2018-09-01 08:00:00'),
(27, 29, 12.500, 255.40,  'Online', '2018-10-01 08:00:00'),
-- Firenze
(31, 32, 13.500, 285.70,  'Online', '2017-12-15 08:00:00'),
-- Catania
(36, 37, 11.000, 230.45,  'Online', '2021-03-15 08:00:00');


-- ============================================================================
-- CLIENTS (15 rows)
-- 7 Civil, 3 Industrial, 5 NonMetered
-- ============================================================================
INSERT INTO Clients (Name, ZIPCode, City, Address, Phone, Email) VALUES
-- Civil (7)
('Marco Ferretti',         20121, 'Milano',          'Via Torino 14',              '+39 02 1234567',   'marco.ferretti@email.it'),
('Lucia Esposito',         00185, 'Roma',             'Via Labicana 88',            '+39 06 9876543',   'lucia.esposito@email.it'),
('Giovanni Russo',         80132, 'Napoli',           'Corso Umberto 55',           '+39 081 3456789',  'giovanni.russo@email.it'),
('Francesca Marino',       10122, 'Torino',           'Via Po 23',                  '+39 011 4567890',  'francesca.marino@email.it'),
('Salvatore Conti',        90133, 'Palermo',          'Via Maqueda 102',            '+39 091 2345678',  'salvatore.conti@email.it'),
('Elena Ricci',            40121, 'Bologna',          'Via Indipendenza 67',        '+39 051 3456789',  'elena.ricci@email.it'),
('Andrea Lombardi',        50122, 'Firenze',          'Lungarno Corsini 8',         '+39 055 4567890',  'andrea.lombardi@email.it'),
-- Industrial (3)
('Acciaierie Nord S.p.A.', 20125, 'Milano',          'Via Padova 220',             '+39 02 8765432',   'info@acciaierie-nord.it'),
('Ceramiche Sud S.r.l.',   80040, 'Napoli',           'Via Argine 340',             '+39 081 6543210',  'info@ceramiche-sud.it'),
('Tessile Emilia S.p.A.',  40132, 'Bologna',          'Via della Repubblica 15',    '+39 051 8765432',  'info@tessile-emilia.it'),
-- NonMetered (5)
('Comune di Catania',      95100, 'Catania',          'Piazza del Duomo 3',         '+39 095 7420111',  'acqua@comune.catania.it'),
('Parco Regionale Etna',   95012, 'Nicolosi',         'Via Etna 1',                 '+39 095 7914588',  'info@parcoetna.it'),
('Comune di Palermo',      90133, 'Palermo',          'Piazza Pretoria 1',          '+39 091 7401111',  'acqua@comune.palermo.it'),
('Aeroporto di Torino',    10072, 'Caselle Torinese', 'Corso della Vischera 100',   '+39 011 5676361',  'tecnico@aeroporto.to.it'),
('Stazione FS Roma',       00185, 'Roma',             'Piazza dei Cinquecento 1',   '+39 06 47308098',  'impianti@rfi.it');


-- ============================================================================
-- METERS (25 rows — manually inserted, no trigger)
-- ============================================================================
INSERT INTO Meters (SerialNumber, MeterType, AttachedTo, Status, InstallationDate) VALUES
-- Civil meters (Smart) — pipes 1-7
('MTR-000000001', 'Smart', 1,  'Online', '2018-06-01 09:00:00'),
('MTR-000000002', 'Smart', 2,  'Online', '2018-06-05 09:00:00'),
('MTR-000000003', 'Smart', 5,  'Online', '2017-09-01 09:00:00'),
('MTR-000000004', 'Smart', 6,  'Online', '2017-09-10 09:00:00'),
('MTR-000000005', 'Smart', 9,  'Online', '2016-12-01 09:00:00'),
('MTR-000000006', 'Smart', 12, 'Online', '2019-08-01 09:00:00'),
('MTR-000000007', 'Smart', 19, 'Online', '2018-01-15 09:00:00'),
-- Industrial meters (Smart) — higher flow pipes
('MTR-IND-00001', 'Smart', 4,  'Online', '2018-07-01 09:00:00'),
('MTR-IND-00002', 'Smart', 8,  'Online', '2017-10-01 09:00:00'),
('MTR-IND-00003', 'Smart', 10, 'Online', '2017-01-15 09:00:00'),
-- NonMetered
('MTR-NMT-00001', 'NotPresent', 20, 'Online', '2021-04-01 09:00:00'),
('MTR-NMT-00002', 'NotPresent', 16, 'Online', '2020-07-01 09:00:00'),
('MTR-NMT-00003', 'NotPresent', 15, 'Online', '2020-09-01 09:00:00'),
('MTR-NMT-00004', 'NotPresent', 14, 'Online', '2020-02-01 09:00:00'),
('MTR-NMT-00005', 'NotPresent', 13, 'Online', '2017-06-01 09:00:00'),
-- Extra meters for spare contracts / future use
('MTR-000000008', 'Smart', 3,  'Online', '2019-03-01 09:00:00'),
('MTR-000000009', 'Smart', 7,  'Online', '2017-11-01 09:00:00'),
('MTR-000000010', 'Smart', 11, 'Online', '2017-02-01 09:00:00'),
('MTR-000000011', 'Smart', 17, 'Online', '2019-09-01 09:00:00'),
('MTR-000000012', 'Smart', 18, 'Online', '2019-10-01 09:00:00'),
('MTR-IND-00004', 'Smart', 9,  'Disconnected', '2022-01-01 09:00:00'),
('MTR-000000013', 'Manual', 1, 'Online', '2020-05-01 09:00:00'),
('MTR-000000014', 'Manual', 2, 'Online', '2020-06-01 09:00:00'),
('MTR-000000015', 'Smart', 5,  'Disconnected', '2021-11-01 09:00:00'),
('MTR-000000016', 'Smart', 6,  'Online', '2022-03-01 09:00:00');


-- ============================================================================
-- CONTRACTS (25 rows)
-- 7 Civil, 3 Industrial, 5 NonMetered + 10 ended/extra
-- ============================================================================
INSERT INTO Contracts (Client, PropertyZIPCode, PropertyCity, PropertyAddress, ClientType, Meter, EstablishedBillCost, BillingPeriod, AllocatedFlowrate, ContractIssueDate, ContractEndDate) VALUES
-- Active Civil contracts
(1, 20121, 'Milano',   'Via Torino 14',          'Civil',       1,  NULL,      INTERVAL '1 month', 0.80, '2018-06-01', NULL),
(2, 00185, 'Roma',     'Via Labicana 88',         'Civil',       3,  NULL,      INTERVAL '1 month', 0.60, '2017-09-01', NULL),
(3, 80132, 'Napoli',   'Corso Umberto 55',        'Civil',       5,  NULL,      INTERVAL '1 month', 0.70, '2016-12-01', NULL),
(4, 10122, 'Torino',   'Via Po 23',               'Civil',       6,  NULL,      INTERVAL '1 month', 0.55, '2019-08-01', NULL),
(5, 90133, 'Palermo',  'Via Maqueda 102',         'Civil',       7,  NULL,      INTERVAL '1 month', 0.65, '2018-01-15', NULL),
(6, 40121, 'Bologna',  'Via Indipendenza 67',     'Civil',       16, NULL,      INTERVAL '1 month', 0.75, '2019-03-01', NULL),
(7, 50122, 'Firenze',  'Lungarno Corsini 8',      'Civil',       17, NULL,      INTERVAL '1 month', 0.70, '2017-11-01', NULL),
-- Active Industrial contracts
(8,  20125, 'Milano',  'Via Padova 220',          'Industrial',  8,  NULL,      INTERVAL '1 month', 8.50, '2018-07-01', NULL),
(9,  80040, 'Napoli',  'Via Argine 340',          'Industrial',  9,  NULL,      INTERVAL '1 month', 6.20, '2017-10-01', NULL),
(10, 40132, 'Bologna', 'Via della Repubblica 15', 'Industrial',  10, NULL,      INTERVAL '1 month', 7.80, '2017-01-15', NULL),
-- Active NonMetered contracts
(11, 95100, 'Catania',          'Piazza del Duomo 3',       'NonMetered', 11, 1200.00, INTERVAL '3 months', NULL, '2021-04-01', NULL),
(12, 95012, 'Nicolosi',         'Via Etna 1',               'NonMetered', 12, 850.00,  INTERVAL '3 months', NULL, '2020-07-01', NULL),
(13, 90133, 'Palermo',          'Piazza Pretoria 1',        'NonMetered', 13, 1500.00, INTERVAL '3 months', NULL, '2020-09-01', NULL),
(14, 10072, 'Caselle Torinese', 'Corso della Vischera 100', 'NonMetered', 14, 950.00,  INTERVAL '3 months', NULL, '2020-02-01', NULL),
(15, 00185, 'Roma',             'Piazza dei Cinquecento 1', 'NonMetered', 15, 2000.00, INTERVAL '3 months', NULL, '2017-06-01', NULL),
-- Ended Civil contracts (for historical data)
(1, 20121, 'Milano',   'Via Brera 5',             'Civil',       18, NULL,      INTERVAL '1 month', 0.50, '2019-09-01', '2023-02-28'),
(2, 00185, 'Roma',     'Via Appia 200',           'Civil',       19, NULL,      INTERVAL '1 month', 0.60, '2019-10-01', '2022-12-31'),
(3, 80132, 'Napoli',   'Via Toledo 90',           'Civil',       20, NULL,      INTERVAL '1 month', 0.55, '2020-01-01', '2023-06-30'),
-- Ended Industrial
(8, 20125, 'Milano',   'Via Stephenson 40',       'Industrial',  21, NULL,      INTERVAL '1 month', 5.00, '2022-01-01', '2023-12-31'),
-- More active civil
(4, 10122, 'Torino',   'Corso Francia 88',        'Civil',       22, NULL,      INTERVAL '1 month', 0.80, '2020-05-01', NULL),
(5, 90133, 'Palermo',  'Via Roma 55',             'Civil',       23, NULL,      INTERVAL '1 month', 0.70, '2020-06-01', NULL),
(6, 40121, 'Bologna',  'Via Zamboni 10',          'Civil',       25, NULL,      INTERVAL '1 month', 0.65, '2022-03-01', NULL),
-- Disconnected meter contract (ended)
(7, 50122, 'Firenze',  'Via Ghibellina 120',      'Civil',       24, NULL,      INTERVAL '1 month', 0.60, '2021-11-01', '2024-01-31'),
-- Extra
(1, 20121, 'Milano',   'Viale Tunisia 3',         'Civil',       2,  NULL,      INTERVAL '1 month', 0.55, '2018-06-05', NULL),
(2, 00185, 'Roma',     'Via Nomentana 300',       'Civil',       4,  NULL,      INTERVAL '1 month', 0.50, '2017-09-10', NULL);


-- ============================================================================
-- TECHNICIANS (30 rows)
-- ============================================================================
INSERT INTO Technicians (FullName, FiscalCode, IBAN, Wage, EmploymentDate, ResignationDate) VALUES
('Luca Bianchi',        'BNCLCU80A01F205X', 'IT60X0542811101000000123456', 2100.00, '2015-01-10', NULL),
('Marco Neri',          'NREMRC78B02H501Y', 'IT40L0326822300052198650916', 2000.00, '2015-03-15', NULL),
('Giuseppe Verde',      'VRDGPP82C03G273Z', 'IT20U0760101600000011748061', 1950.00, '2016-01-20', NULL),
('Antonio Gialli',      'GLLNTN75D04A662W', 'IT57L0200801116000100440847', 2200.00, '2016-06-01', NULL),
('Roberto Rossi',       'RSSRRT70E05F839V', 'IT94S0306909606100000046985', 1900.00, '2017-02-14', NULL),
('Stefano Blu',         'BLUSTN85F06H294U', 'IT23A0200802420000400075372', 2050.00, '2017-05-20', NULL),
('Francesco Marrone',   'MRRFNC79G07L682T', 'IT56M0335901600100000125390', 2150.00, '2017-09-01', NULL),
('Davide Costa',        'CSTDVD88H08A944S', 'IT29P0569601600000010592260', 1980.00, '2018-01-08', NULL),
('Simone Ferrara',      'FRRSMN91I09B354R', 'IT76U0200811101000000528453', 2000.00, '2018-04-15', NULL),
('Matteo Bruno',        'BRNMTT86L10F205Q', 'IT55A0200801116000100337492', 1920.00, '2018-07-01', NULL),
('Andrea Fontana',      'FNTNDR83M11G273P', 'IT84B0200801116000100558834', 2080.00, '2018-10-20', NULL),
('Claudio Martini',     'MRTCLD77N12H501O', 'IT14C0200801116000100234562', 2250.00, '2019-01-07', NULL),
('Paolo Conti',         'CNTPLA80P13L219N', 'IT91D0200801116000100678923', 1970.00, '2019-03-18', NULL),
('Michele Ferrari',     'FRRMHL84Q14F839M', 'IT63E0200801116000100123789', 2100.00, '2019-06-01', NULL),
('Nicola Serra',        'SRRNCL82R15A662L', 'IT38F0200801116000100456012', 1950.00, '2019-09-10', NULL),
('Vincenzo Greco',      'GRCVCN76S16H294K', 'IT12G0200801116000100789345', 2000.00, '2020-01-15', NULL),
('Fabio Lombardo',      'LMBFBA79T17L682J', 'IT87H0200801116000100012678', 2150.00, '2020-04-01', NULL),
('Massimo Rizzo',       'RZZMSS85U18A944I', 'IT61I0200801116000100345901', 1980.00, '2020-07-20', NULL),
('Daniele Caruso',      'CRSDNL88V19B354H', 'IT36L0200801116000100678234', 2050.00, '2020-10-05', NULL),
('Alberto Fiore',       'FRALRT83W20F205G', 'IT11M0200801116000100901567', 1920.00, '2021-01-11', NULL),
('Emanuele Gallo',      'GLLMNL80X21G273F', 'IT85N0200801116000100234890', 2080.00, '2021-04-01', NULL),
('Cristian Monti',      'MNTCRS86Y22H501E', 'IT60P0200801116000100567123', 2250.00, '2021-07-15', NULL),
('Sergio Valentini',    'VLNSRG75Z23L219D', 'IT34Q0200801116000100890456', 1970.00, '2021-10-01', NULL),
('Luca Pellegrini',     'PLLLCU82A24F839C', 'IT09R0200801116000100123789', 2100.00, '2022-01-20', NULL),
('Gianluca Cattaneo',   'CTTGLC79B25A662B', 'IT83S0200801116000100456012', 1950.00, '2022-04-01', NULL),
('Alessandro Moretti',  'MRTLSS77C26H294A', 'IT58T0200801116000100789345', 2000.00, '2022-07-10', NULL),
('Federico Barbieri',   'BRBFRC84D27L682Z', 'IT32U0200801116000100012678', 2150.00, '2022-10-01', NULL),
('Enrico Silvestri',    'SLVNRC81E28A944Y', 'IT07V0200801116000100345901', 1980.00, '2023-01-15', NULL),
-- Resigned technicians
('Carlo Mancini',       'MNCCRL70F29B354X', 'IT81W0200801116000100678234', 1800.00, '2016-03-01', '2022-06-30'),
('Piero Santoro',       'SNTRPI68G30F205W', 'IT56X0200801116000100901567', 1750.00, '2015-06-01', '2021-12-31');


-- ============================================================================
-- OPERATIONS (manually, realistic mix)
-- ============================================================================
INSERT INTO Operations (Type, TargetType, TargetId, IssueDate, CompletionDate, Description, OperationCost, Priority, RequiredTechnicians) VALUES
-- Completed installs
('Install', 'Node',  1,  '2018-03-10', '2018-03-11', 'Node installation - Milano zona nord',         350.00, 'Important', 2),
('Install', 'Node',  6,  '2017-06-05', '2017-06-06', 'Node installation - Roma zona centro',          380.00, 'Important', 2),
('Install', 'Node',  11, '2016-09-01', '2016-09-02', 'Node installation - Napoli zona porto',         320.00, 'Important', 2),
('Install', 'Pump',  1,  '2018-03-15', '2018-03-16', 'Pump Grundfos CR10-8 installation',            1200.00, 'Urgent',    4),
('Install', 'Pump',  2,  '2017-06-10', '2017-06-11', 'Pump Grundfos CR15-4 installation',            1400.00, 'Urgent',    4),
('Install', 'Pump',  3,  '2016-09-05', '2016-09-06', 'Pump KSB Etanorm installation',                1100.00, 'Urgent',    4),
('Install', 'Meter', 1,  '2018-06-01', '2018-06-01', 'Smart meter installation - Milano',              150.00, 'Normal',    1),
('Install', 'Meter', 3,  '2017-09-01', '2017-09-01', 'Smart meter installation - Roma',                150.00, 'Normal',    1),
('Install', 'Meter', 5,  '2016-12-01', '2016-12-01', 'Smart meter installation - Napoli',              150.00, 'Normal',    1),
-- Completed repairs
('Repair',  'Pump',  3,  '2021-03-10', '2021-03-12', 'Seal replacement on KSB Etanorm',               480.00, 'Urgent',    4),
('Repair',  'Node',  4,  '2022-08-15', '2022-08-16', 'Node control board replacement - Milano',        220.00, 'Urgent',    2),
('Repair',  'Pipe',  5,  '2022-11-01', '2022-11-03', 'Pipe joint leak repair - Roma',                  310.00, 'Urgent',    2),
-- Completed checks
('Check',   'Pump',  1,  '2023-01-15', '2023-01-15', 'Annual pump inspection',                         80.00, 'Normal',    1),
('Check',   'Pump',  2,  '2023-01-20', '2023-01-20', 'Annual pump inspection',                         80.00, 'Normal',    1),
('Check',   'Node',  6,  '2023-02-10', '2023-02-10', 'Node telemetry check',                           60.00, 'Normal',    1),
-- Meter readings ops (completed)
('Reading', 'Meter', 1,  '2023-10-01', '2023-10-01', 'Monthly reading - MTR-000000001',                40.00, 'Normal',    1),
('Reading', 'Meter', 3,  '2023-10-01', '2023-10-01', 'Monthly reading - MTR-000000003',                40.00, 'Normal',    1),
('Reading', 'Meter', 5,  '2023-10-01', '2023-10-01', 'Monthly reading - MTR-000000005',                40.00, 'Normal',    1),
-- Open maintenance
('Check', 'Pump',  4, '2024-01-10', NULL, 'Scheduled maintenance - Lowara e-SV 4',              NULL,   'Normal',    1),
('Check', 'Node',  4, '2024-02-01', NULL, 'Node status check after fault',                      NULL,   'Normal',    1),
-- Open fault repair
('Repair',  'Node',  9,  '2024-03-01', NULL, 'Node fault - Roma, power supply issue',                 NULL,   'Urgent',    2),
('Repair',  'Node',  25, '2024-03-05', NULL, 'Node fault - Palermo, communication failure',           NULL,   'Urgent',    2),
-- Detach for ended contracts
('Detach',  'Meter', 18, '2023-02-28', '2023-03-05', 'Contract ended - meter removal Milano Brera',   90.00, 'Normal',    1),
('Detach',  'Meter', 19, '2022-12-31', '2023-01-10', 'Contract ended - meter removal Roma Appia',     90.00, 'Normal',    1),
('Detach',  'Meter', 21, '2024-01-01', '2024-01-08', 'Contract ended - industrial meter removal',    120.00, 'Normal',    1),
-- Open attach for disconnected meter
('Attach',  'Meter', 24, '2024-02-01', NULL, 'Contract ended - meter scheduled for removal',          NULL,  'Normal',    1);


-- ============================================================================
-- TECHNICIAN TASKS
-- ============================================================================
INSERT INTO TechnicianTasks (Operation, Technician, AssignmentDate, ReleaseDate) VALUES
-- Op 1: Install Node 1 (2 techs)
(1, 1, '2018-03-10', '2018-03-11'),
(1, 2, '2018-03-10', '2018-03-11'),
-- Op 2: Install Node 6 (2 techs)
(2, 3, '2017-06-05', '2017-06-06'),
(2, 4, '2017-06-05', '2017-06-06'),
-- Op 3: Install Node 11 (2 techs)
(3, 5, '2016-09-01', '2016-09-02'),
(3, 6, '2016-09-01', '2016-09-02'),
-- Op 4: Install Pump 1 (4 techs)
(4, 1, '2018-03-15', '2018-03-16'),
(4, 2, '2018-03-15', '2018-03-16'),
(4, 3, '2018-03-15', '2018-03-16'),
(4, 4, '2018-03-15', '2018-03-16'),
-- Op 5: Install Pump 2 (4 techs)
(5, 5, '2017-06-10', '2017-06-11'),
(5, 6, '2017-06-10', '2017-06-11'),
(5, 7, '2017-06-10', '2017-06-11'),
(5, 8, '2017-06-10', '2017-06-11'),
-- Op 6: Install Pump 3 (4 techs)
(6, 9,  '2016-09-05', '2016-09-06'),
(6, 10, '2016-09-05', '2016-09-06'),
(6, 11, '2016-09-05', '2016-09-06'),
(6, 12, '2016-09-05', '2016-09-06'),
-- Op 7,8,9: Meter installs (1 tech each)
(7,  13, '2018-06-01', '2018-06-01'),
(8,  14, '2017-09-01', '2017-09-01'),
(9,  15, '2016-12-01', '2016-12-01'),
-- Op 10: Repair Pump 3
(10, 9,  '2021-03-10', '2021-03-12'),
(10, 10, '2021-03-10', '2021-03-12'),
(10, 11, '2021-03-10', '2021-03-12'),
(10, 12, '2021-03-10', '2021-03-12'),
-- Op 11: Repair Node 4
(11, 1, '2022-08-15', '2022-08-16'),
(11, 2, '2022-08-15', '2022-08-16'),
-- Op 12: Repair Pipe 5
(12, 3, '2022-11-01', '2022-11-03'),
(12, 4, '2022-11-01', '2022-11-03'),
-- Op 13,14,15: Checks (1 tech each)
(13, 5, '2023-01-15', '2023-01-15'),
(14, 6, '2023-01-20', '2023-01-20'),
(15, 7, '2023-02-10', '2023-02-10'),
-- Op 16,17,18: Reading ops
(16, 16, '2023-10-01', '2023-10-01'),
(17, 17, '2023-10-01', '2023-10-01'),
(18, 18, '2023-10-01', '2023-10-01'),
-- Op 19,20: Open maintenance (still assigned)
(19, 8,  '2024-01-10', NULL),
(20, 9,  '2024-02-01', NULL),
-- Op 21,22: Open urgent repairs (still assigned)
(21, 1, '2024-03-01', NULL),
(21, 2, '2024-03-01', NULL),
(22, 3, '2024-03-05', NULL),
(22, 4, '2024-03-05', NULL),
-- Op 23,24,25: Detach ops
(23, 13, '2023-02-28', '2023-03-05'),
(24, 14, '2022-12-31', '2023-01-10'),
(25, 15, '2024-01-01', '2024-01-08'),
-- Op 26: Open attach
(26, 16, '2024-02-01', NULL);


-- ============================================================================
-- READINGS (enough to generate 80+ bills)
-- Smart meters → Technician NULL, Manual → Technician assigned
-- ============================================================================
INSERT INTO Readings (Meter, Volume, TimePeriod, Technician, Date) VALUES
-- Meter 1 (Civil, Milano) - monthly readings
(1,  12.50, INTERVAL '1 month', NULL, '2022-01-01'),
(1,  25.30, INTERVAL '1 month', NULL, '2022-02-01'),
(1,  38.80, INTERVAL '1 month', NULL, '2022-03-01'),
(1,  52.10, INTERVAL '1 month', NULL, '2022-04-01'),
(1,  64.90, INTERVAL '1 month', NULL, '2022-05-01'),
(1,  77.40, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 3 (Civil, Roma) - monthly readings
(3,  10.20, INTERVAL '1 month', NULL, '2022-01-01'),
(3,  21.80, INTERVAL '1 month', NULL, '2022-02-01'),
(3,  34.50, INTERVAL '1 month', NULL, '2022-03-01'),
(3,  47.30, INTERVAL '1 month', NULL, '2022-04-01'),
(3,  60.10, INTERVAL '1 month', NULL, '2022-05-01'),
(3,  73.40, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 5 (Civil, Napoli) - monthly readings
(5,  9.80,  INTERVAL '1 month', NULL, '2022-01-01'),
(5,  20.30, INTERVAL '1 month', NULL, '2022-02-01'),
(5,  31.90, INTERVAL '1 month', NULL, '2022-03-01'),
(5,  44.20, INTERVAL '1 month', NULL, '2022-04-01'),
(5,  56.80, INTERVAL '1 month', NULL, '2022-05-01'),
(5,  69.50, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 6 (Civil, Torino) - monthly readings
(6,  11.20, INTERVAL '1 month', NULL, '2022-01-01'),
(6,  23.40, INTERVAL '1 month', NULL, '2022-02-01'),
(6,  35.90, INTERVAL '1 month', NULL, '2022-03-01'),
(6,  49.10, INTERVAL '1 month', NULL, '2022-04-01'),
(6,  62.30, INTERVAL '1 month', NULL, '2022-05-01'),
(6,  75.80, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 7 (Civil, Palermo) - monthly readings
(7,  8.90,  INTERVAL '1 month', NULL, '2022-01-01'),
(7,  18.40, INTERVAL '1 month', NULL, '2022-02-01'),
(7,  29.10, INTERVAL '1 month', NULL, '2022-03-01'),
(7,  40.50, INTERVAL '1 month', NULL, '2022-04-01'),
(7,  52.20, INTERVAL '1 month', NULL, '2022-05-01'),
(7,  64.90, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 8 (Industrial, Milano) - monthly
(8,  145.00, INTERVAL '1 month', NULL, '2022-01-01'),
(8,  291.00, INTERVAL '1 month', NULL, '2022-02-01'),
(8,  438.50, INTERVAL '1 month', NULL, '2022-03-01'),
(8,  584.00, INTERVAL '1 month', NULL, '2022-04-01'),
(8,  731.20, INTERVAL '1 month', NULL, '2022-05-01'),
(8,  878.00, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 9 (Industrial, Napoli)
(9,  120.00, INTERVAL '1 month', NULL, '2022-01-01'),
(9,  241.50, INTERVAL '1 month', NULL, '2022-02-01'),
(9,  363.00, INTERVAL '1 month', NULL, '2022-03-01'),
(9,  485.00, INTERVAL '1 month', NULL, '2022-04-01'),
(9,  607.50, INTERVAL '1 month', NULL, '2022-05-01'),
(9,  729.00, INTERVAL '1 month', NULL, '2022-06-01'),
-- Meter 10 (Industrial, Bologna)
(10, 160.00, INTERVAL '1 month', NULL, '2022-01-01'),
(10, 321.00, INTERVAL '1 month', NULL, '2022-02-01'),
(10, 483.00, INTERVAL '1 month', NULL, '2022-03-01'),
(10, 645.00, INTERVAL '1 month', NULL, '2022-04-01'),
(10, 808.00, INTERVAL '1 month', NULL, '2022-05-01'),
(10, 970.00, INTERVAL '1 month', NULL, '2022-06-01'),
-- NonMetered meters → quarterly readings (volume stored but bill uses fixed cost)
(11, 0.00, INTERVAL '3 months', NULL, '2022-01-01'),
(11, 0.00, INTERVAL '3 months', NULL, '2022-04-01'),
(11, 0.00, INTERVAL '3 months', NULL, '2022-07-01'),
(11, 0.00, INTERVAL '3 months', NULL, '2022-10-01'),
(12, 0.00, INTERVAL '3 months', NULL, '2022-01-01'),
(12, 0.00, INTERVAL '3 months', NULL, '2022-04-01'),
(12, 0.00, INTERVAL '3 months', NULL, '2022-07-01'),
(12, 0.00, INTERVAL '3 months', NULL, '2022-10-01'),
(13, 0.00, INTERVAL '3 months', NULL, '2022-01-01'),
(13, 0.00, INTERVAL '3 months', NULL, '2022-04-01'),
(13, 0.00, INTERVAL '3 months', NULL, '2022-07-01'),
(13, 0.00, INTERVAL '3 months', NULL, '2022-10-01'),
(14, 0.00, INTERVAL '3 months', NULL, '2022-01-01'),
(14, 0.00, INTERVAL '3 months', NULL, '2022-04-01'),
(14, 0.00, INTERVAL '3 months', NULL, '2022-07-01'),
(14, 0.00, INTERVAL '3 months', NULL, '2022-10-01'),
(15, 0.00, INTERVAL '3 months', NULL, '2022-01-01'),
(15, 0.00, INTERVAL '3 months', NULL, '2022-04-01'),
(15, 0.00, INTERVAL '3 months', NULL, '2022-07-01'),
(15, 0.00, INTERVAL '3 months', NULL, '2022-10-01'),
-- Manual meter readings (with technician)
(22, 14.30, INTERVAL '1 month', 19, '2022-01-01'),
(22, 28.90, INTERVAL '1 month', 19, '2022-02-01'),
(23, 11.50, INTERVAL '1 month', 20, '2022-01-01'),
(23, 23.20, INTERVAL '1 month', 20, '2022-02-01');


-- ============================================================================
-- BILLS (manually, 80+ rows matching readings above)
-- Amounts calculated consistently with ProgressiveTaxation
-- ============================================================================
INSERT INTO Bills (Reading, Contract, BillAmount, IssuingDate, DueDate, PaymentDate) VALUES
-- Meter 1 / Contract 1 (Civil Milano, Smart)
(1,  1,   7.50,   '2022-01-01', '2022-02-01', '2022-01-25'),
(2,  1,   7.68,   '2022-02-01', '2022-03-01', '2022-02-22'),
(3,  1,   8.10,   '2022-03-01', '2022-04-01', '2022-03-28'),
(4,  1,   8.75,   '2022-04-01', '2022-05-01', '2022-04-20'),
(5,  1,   8.16,   '2022-05-01', '2022-06-01', '2022-05-26'),
(6,  1,   7.88,   '2022-06-01', '2022-07-01', '2022-06-29'),
-- Meter 3 / Contract 2 (Civil Roma)
(7,  2,   6.12,   '2022-01-01', '2022-02-01', '2022-01-28'),
(8,  2,   6.96,   '2022-02-01', '2022-03-01', '2022-02-25'),
(9,  2,   7.62,   '2022-03-01', '2022-04-01', '2022-04-05'), -- overdue
(10, 2,   7.68,   '2022-04-01', '2022-05-01', '2022-04-29'),
(11, 2,   7.68,   '2022-05-01', '2022-06-01', '2022-05-30'),
(12, 2,   7.38,   '2022-06-01', '2022-07-01', '2022-06-28'),
-- Meter 5 / Contract 3 (Civil Napoli)
(13, 3,   5.88,   '2022-01-01', '2022-02-01', '2022-01-30'),
(14, 3,   6.30,   '2022-02-01', '2022-03-01', '2022-02-28'),
(15, 3,   6.96,   '2022-03-01', '2022-04-01', '2022-03-31'),
(16, 3,   7.38,   '2022-04-01', '2022-05-01', '2022-04-28'),
(17, 3,   7.56,   '2022-05-01', '2022-06-01', '2022-05-29'),
(18, 3,   7.65,   '2022-06-01', '2022-07-01', '2022-07-10'), -- overdue
-- Meter 6 / Contract 4 (Civil Torino)
(19, 4,   6.72,   '2022-01-01', '2022-02-01', '2022-01-27'),
(20, 4,   7.32,   '2022-02-01', '2022-03-01', '2022-02-24'),
(21, 4,   7.50,   '2022-03-01', '2022-04-01', '2022-03-30'),
(22, 4,   7.68,   '2022-04-01', '2022-05-01', '2022-04-27'),
(23, 4,   7.56,   '2022-05-01', '2022-06-01', '2022-05-28'),
(24, 4,   8.00,   '2022-06-01', '2022-07-01', '2022-06-30'),
-- Meter 7 / Contract 5 (Civil Palermo)
(25, 5,   5.34,   '2022-01-01', '2022-02-01', '2022-01-29'),
(26, 5,   5.70,   '2022-02-01', '2022-03-01', '2022-02-26'),
(27, 5,   6.42,   '2022-03-01', '2022-04-01', '2022-03-29'),
(28, 5,   6.84,   '2022-04-01', '2022-05-01', '2022-04-26'),
(29, 5,   7.02,   '2022-05-01', '2022-06-01', '2022-05-27'),
(30, 5,   7.62,   '2022-06-01', '2022-07-01', '2022-06-27'),
-- Meter 8 / Contract 8 (Industrial Milano) — higher volumes → higher band
(31, 8,   193.88, '2022-01-01', '2022-02-01', '2022-01-31'),
(32, 8,   197.10, '2022-02-01', '2022-03-01', '2022-02-28'),
(33, 8,   200.03, '2022-03-01', '2022-04-01', '2022-04-10'), -- overdue
(34, 8,   191.75, '2022-04-01', '2022-05-01', '2022-04-30'),
(35, 8,   388.32, '2022-05-01', '2022-06-01', '2022-05-31'),
(36, 8,   388.92, '2022-06-01', '2022-07-01', '2022-06-30'),
-- Meter 9 / Contract 9 (Industrial Napoli)
(37, 9,   156.00, '2022-01-01', '2022-02-01', '2022-01-28'),
(38, 9,   159.38, '2022-02-01', '2022-03-01', '2022-02-27'),
(39, 9,   161.70, '2022-03-01', '2022-04-01', '2022-03-30'),
(40, 9,   162.92, '2022-04-01', '2022-05-01', '2022-04-29'),
(41, 9,   323.75, '2022-05-01', '2022-06-01', '2022-05-28'),
(42, 9,   161.69, '2022-06-01', '2022-07-01', '2022-06-27'),
-- Meter 10 / Contract 10 (Industrial Bologna)
(43, 10,  225.60, '2022-01-01', '2022-02-01', '2022-01-30'),
(44, 10,  228.71, '2022-02-01', '2022-03-01', '2022-02-28'),
(45, 10,  231.60, '2022-03-01', '2022-04-01', '2022-03-29'),
(46, 10,  419.34, '2022-04-01', '2022-05-01', '2022-04-28'),
(47, 10,  428.23, '2022-05-01', '2022-06-01', '2022-05-27'),
(48, 10,  416.30, '2022-06-01', '2022-07-01', '2022-06-26'),
-- NonMetered / fixed cost (Contracts 11-15)
(49, 11,  1200.00, '2022-01-01', '2022-02-01', '2022-01-31'),
(50, 11,  1200.00, '2022-04-01', '2022-05-01', '2022-04-30'),
(51, 11,  1200.00, '2022-07-01', '2022-08-01', '2022-07-31'),
(52, 11,  1200.00, '2022-10-01', '2022-11-01', '2022-10-31'),
(53, 12,  850.00,  '2022-01-01', '2022-02-01', '2022-01-28'),
(54, 12,  850.00,  '2022-04-01', '2022-05-01', '2022-04-29'),
(55, 12,  850.00,  '2022-07-01', '2022-08-01', '2022-07-28'),
(56, 12,  850.00,  '2022-10-01', '2022-11-01', '2022-10-28'),
(57, 13,  1500.00, '2022-01-01', '2022-02-01', '2022-01-29'),
(58, 13,  1500.00, '2022-04-01', '2022-05-01', '2022-04-28'),
(59, 13,  1500.00, '2022-07-01', '2022-08-01', '2022-07-29'),
(60, 13,  1500.00, '2022-10-01', '2022-11-01', '2022-11-15'), -- overdue
(61, 14,  950.00,  '2022-01-01', '2022-02-01', '2022-01-31'),
(62, 14,  950.00,  '2022-04-01', '2022-05-01', '2022-04-30'),
(63, 14,  950.00,  '2022-07-01', '2022-08-01', '2022-07-31'),
(64, 14,  950.00,  '2022-10-01', '2022-11-01', '2022-10-31'),
(65, 15,  2000.00, '2022-01-01', '2022-02-01', '2022-01-31'),
(66, 15,  2000.00, '2022-04-01', '2022-05-01', '2022-04-30'),
(67, 15,  2000.00, '2022-07-01', '2022-08-01', '2022-07-30'),
(68, 15,  2000.00, '2022-10-01', '2022-11-01', '2022-10-30'),
-- Manual meters (contracts 20,21)
(69, 20,  8.58,   '2022-01-01', '2022-02-01', '2022-01-26'),
(70, 20,  8.74,   '2022-02-01', '2022-03-01', '2022-02-23'),
(71, 21,  6.90,   '2022-01-01', '2022-02-01', '2022-01-27'),
(72, 21,  7.02,   '2022-02-01', '2022-03-01', '2022-02-24'),
-- Extra bills for contracts 6 and 7 (Bologna, Firenze)
(1,  6,   7.50,   '2022-07-01', '2022-08-01', '2022-07-28'),
(1,  7,   7.50,   '2022-07-01', '2022-08-01', '2022-07-29'),
(7,  6,   6.12,   '2022-08-01', '2022-09-01', '2022-08-28'),
(7,  7,   6.12,   '2022-08-01', '2022-09-01', '2022-08-27'),
-- Unpaid bill (still open)
(6,  1,   7.88,   '2023-06-01', '2023-07-01', NULL),
(12, 2,   7.38,   '2023-06-01', '2023-07-01', NULL),
(18, 3,   7.65,   '2023-07-01', '2023-08-01', NULL),
(24, 4,   8.00,   '2023-07-01', '2023-08-01', NULL),
(30, 5,   7.62,   '2023-07-01', '2023-08-01', NULL),
(36, 8,   388.92, '2023-07-01', '2023-08-01', NULL),
(42, 9,   161.69, '2023-07-01', '2023-08-01', NULL),
(48, 10,  416.30, '2023-07-01', '2023-08-01', NULL);


-- ============================================================================
-- SALARIES
-- ============================================================================
INSERT INTO Salaries (Technician, WageAmount, PaymentDate) VALUES
(1,  2100.00, '2024-01-31'),
(2,  2000.00, '2024-01-31'),
(3,  1950.00, '2024-01-31'),
(4,  2200.00, '2024-01-31'),
(5,  1900.00, '2024-01-31'),
(6,  2050.00, '2024-01-31'),
(7,  2150.00, '2024-01-31'),
(8,  1980.00, '2024-01-31'),
(9,  2000.00, '2024-01-31'),
(10, 1920.00, '2024-01-31'),
(11, 2080.00, '2024-01-31'),
(12, 2250.00, '2024-01-31'),
(13, 1970.00, '2024-01-31'),
(14, 2100.00, '2024-01-31'),
(15, 1950.00, '2024-01-31'),
(16, 2000.00, '2024-01-31'),
(17, 2150.00, '2024-01-31'),
(18, 1980.00, '2024-01-31'),
(19, 2050.00, '2024-01-31'),
(20, 1920.00, '2024-01-31'),
(21, 2080.00, '2024-01-31'),
(22, 2250.00, '2024-01-31'),
(23, 1970.00, '2024-01-31'),
(24, 2100.00, '2024-01-31'),
(25, 1950.00, '2024-01-31'),
(26, 2000.00, '2024-01-31'),
(27, 2150.00, '2024-01-31'),
(28, 1980.00, '2024-01-31'),
-- February salaries for active techs
(1,  2100.00, '2024-02-29'),
(5,  1900.00, '2024-02-29'),
(9,  2000.00, '2024-02-29'),
(13, 1970.00, '2024-02-29'),
(17, 2150.00, '2024-02-29'),
(21, 2080.00, '2024-02-29');


-- Re-enable triggers
SET session_replication_role = DEFAULT;