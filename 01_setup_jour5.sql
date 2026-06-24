-- ============================================================
--  JOUR 5 / 10 DAYS OF SQL — Setup : Window Functions
--  Table : sales (ventes mensuelles par vendeur)
-- ============================================================

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    id              INTEGER PRIMARY KEY,
    vendeur         TEXT NOT NULL,
    region          TEXT NOT NULL,
    mois            TEXT NOT NULL,    -- format 'YYYY-MM'
    montant         INTEGER NOT NULL
);

INSERT INTO sales (id, vendeur, region, mois, montant) VALUES
-- Alice — Île-de-France
(1,  'Alice', 'Île-de-France', '2024-01', 18600),
(2,  'Alice', 'Île-de-France', '2024-02', 21600),
(3,  'Alice', 'Île-de-France', '2024-03', 26400),
(4,  'Alice', 'Île-de-France', '2024-04', 19200),
(5,  'Alice', 'Île-de-France', '2024-05', 31200),
-- Karim — PACA
(6,  'Karim', 'PACA', '2024-01', 12350),
(7,  'Karim', 'PACA', '2024-02', 15600),
(8,  'Karim', 'PACA', '2024-03', 11050),
(9,  'Karim', 'PACA', '2024-04', 18200),
(10, 'Karim', 'PACA', '2024-05', 21450),
-- Lucie — Grand Est
(11, 'Lucie', 'Grand Est', '2024-01', 4500),
(12, 'Lucie', 'Grand Est', '2024-02', 8100),
(13, 'Lucie', 'Grand Est', '2024-03', 7650),
(14, 'Lucie', 'Grand Est', '2024-04', 6300),
(15, 'Lucie', 'Grand Est', '2024-05', 9450),
-- Thomas — Île-de-France
(16, 'Thomas', 'Île-de-France', '2024-01', 3600),
(17, 'Thomas', 'Île-de-France', '2024-02', 4800),
(18, 'Thomas', 'Île-de-France', '2024-03', 5160),
(19, 'Thomas', 'Île-de-France', '2024-04', 3960),
(20, 'Thomas', 'Île-de-France', '2024-05', 6240),
-- Nadia — PACA
(21, 'Nadia', 'PACA', '2024-01', 9600),
(22, 'Nadia', 'PACA', '2024-02', 14400),
(23, 'Nadia', 'PACA', '2024-03', 19200),
(24, 'Nadia', 'PACA', '2024-04', 12000),
(25, 'Nadia', 'PACA', '2024-05', 16800);
