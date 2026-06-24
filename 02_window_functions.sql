-- ============================================================
--  JOUR 5 / 10 DAYS OF SQL — Window Functions
--  Concepts : ROW_NUMBER · RANK · DENSE_RANK · LAG · LEAD
--             PARTITION BY · OVER · Moyenne mobile
-- ============================================================

-- ── 1. ROW_NUMBER() : numéroter chaque ligne ─────────────────
-- Numéroter toutes les ventes par montant décroissant
SELECT
    vendeur,
    mois,
    montant,
    ROW_NUMBER() OVER (ORDER BY montant DESC) AS numero_ligne
FROM sales;


-- ── 2. RANK() : classement avec égalités ─────────────────────
-- Classer les vendeurs par CA total (avec égalités possibles)
SELECT
    vendeur,
    SUM(montant) AS ca_total,
    RANK() OVER (ORDER BY SUM(montant) DESC) AS classement
FROM sales
GROUP BY vendeur;

-- RANK() saute des numéros après une égalité : 1, 2, 2, 4...
-- DENSE_RANK() ne saute pas : 1, 2, 2, 3...


-- ── 3. DENSE_RANK() vs RANK() — la différence concrète ──────
SELECT
    vendeur,
    mois,
    montant,
    RANK()       OVER (ORDER BY montant DESC) AS rank_normal,
    DENSE_RANK() OVER (ORDER BY montant DESC) AS dense_rank
FROM sales
ORDER BY montant DESC
LIMIT 10;


-- ── 4. PARTITION BY : recommencer le calcul par groupe ──────
-- Numéroter les ventes de CHAQUE vendeur séparément (1,2,3... par vendeur)
SELECT
    vendeur,
    mois,
    montant,
    ROW_NUMBER() OVER (PARTITION BY vendeur ORDER BY montant DESC) AS rang_dans_vendeur
FROM sales
ORDER BY vendeur, rang_dans_vendeur;

-- PARTITION BY = "GROUP BY qui ne fusionne pas les lignes"
-- Chaque vendeur a sa propre numérotation 1, 2, 3...


-- ── 5. TOP N PAR GROUPE — pattern très utilisé ──────────────
-- Le mois le PLUS PERFORMANT de chaque vendeur
WITH classement AS (
    SELECT
        vendeur,
        mois,
        montant,
        ROW_NUMBER() OVER (PARTITION BY vendeur ORDER BY montant DESC) AS rang
    FROM sales
)
SELECT vendeur, mois, montant
FROM classement
WHERE rang = 1;


-- ── 6. LAG() : valeur de la ligne PRÉCÉDENTE ─────────────────
-- Comparer chaque mois au mois précédent (par vendeur)
SELECT
    vendeur,
    mois,
    montant,
    LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS montant_mois_precedent
FROM sales
ORDER BY vendeur, mois;


-- ── 7. LAG() avec calcul de variation ────────────────────────
-- Évolution du CA mois par mois (en valeur et en %)
SELECT
    vendeur,
    mois,
    montant,
    LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS mois_precedent,
    montant - LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS variation,
    ROUND(
        100.0 * (montant - LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois))
        / LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois), 1
    ) AS variation_pct
FROM sales
ORDER BY vendeur, mois;


-- ── 8. LEAD() : valeur de la ligne SUIVANTE ──────────────────
-- Voir le montant du mois prochain à côté du mois actuel
SELECT
    vendeur,
    mois,
    montant,
    LEAD(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS montant_mois_suivant
FROM sales
ORDER BY vendeur, mois;


-- ── 9. Moyenne mobile sur 3 mois (rolling average) ──────────
SELECT
    vendeur,
    mois,
    montant,
    ROUND(AVG(montant) OVER (
        PARTITION BY vendeur
        ORDER BY mois
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0) AS moyenne_mobile_3mois
FROM sales
ORDER BY vendeur, mois;

-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
-- = la ligne actuelle + les 2 précédentes = fenêtre de 3 lignes


-- ── 10. SUM() OVER : cumul progressif (running total) ───────
SELECT
    vendeur,
    mois,
    montant,
    SUM(montant) OVER (
        PARTITION BY vendeur
        ORDER BY mois
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumul_ca
FROM sales
ORDER BY vendeur, mois;

-- UNBOUNDED PRECEDING = depuis le tout début de la partition
-- Résultat : le CA cumulé mois après mois pour chaque vendeur


-- ── 11. NTILE() : répartir en groupes égaux (quartiles) ─────
-- Répartir toutes les ventes en 4 groupes (quartiles) par montant
SELECT
    vendeur,
    mois,
    montant,
    NTILE(4) OVER (ORDER BY montant) AS quartile
FROM sales
ORDER BY montant;


-- ── 12. Comparer chaque vente à la moyenne de SON vendeur ───
SELECT
    vendeur,
    mois,
    montant,
    ROUND(AVG(montant) OVER (PARTITION BY vendeur), 0) AS moyenne_vendeur,
    montant - ROUND(AVG(montant) OVER (PARTITION BY vendeur), 0) AS ecart_a_la_moyenne
FROM sales
ORDER BY vendeur, mois;


-- ── 13. REQUÊTE COMPLÈTE — Rapport de performance ───────────
-- Combine classement, évolution et moyenne mobile en une vue
WITH performance AS (
    SELECT
        vendeur,
        mois,
        montant,
        RANK() OVER (PARTITION BY mois ORDER BY montant DESC) AS rang_du_mois,
        LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS mois_precedent,
        ROUND(AVG(montant) OVER (
            PARTITION BY vendeur ORDER BY mois
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 0) AS moyenne_mobile_3mois
    FROM sales
)
SELECT
    vendeur,
    mois,
    montant,
    rang_du_mois,
    montant - mois_precedent AS variation_vs_mois_precedent,
    moyenne_mobile_3mois
FROM performance
ORDER BY mois, rang_du_mois;
