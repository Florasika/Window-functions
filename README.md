# 🪟 Jour 5 / 10 — SQL : Window Functions

> **Série : 10 Days of SQL** · Jour 5/10  
> Concepts : ROW_NUMBER · RANK · DENSE_RANK · LAG · LEAD · PARTITION BY · Moyenne mobile

---

## 📁 Structure du projet

```
day-05-window-functions/
│
├── 01_setup.sql               ← CREATE TABLE sales + 25 lignes (5 vendeurs × 5 mois)
├── 02_window_functions.sql    ← 13 requêtes commentées
├── ventes_window.db            ← Base SQLite prête à l'emploi
└── README.md
```

---

## 🚀 Installation & Lancement

```bash
# Cloner le repo
git clone https://github.com/ton-pseudo/10-days-sql.git
cd 10-days-sql/day-05-window-functions

# Ouvrir la base directement (déjà créée)
sqlite3 ventes_window.db

# OU recréer la base depuis zéro
sqlite3 ventes_window.db < 01_setup.sql

# Exécuter toutes les requêtes
sqlite3 ventes_window.db < 02_window_functions.sql
```

⚠️ Les window functions nécessitent **SQLite ≥ 3.25** (2018), PostgreSQL, MySQL ≥ 8.0, ou SQL Server. Vérifie ta version si une requête échoue.

---

## 📊 Le schéma — table `sales`

| Colonne | Type | Description |
|---------|------|--------------|
| `id` | INTEGER | Clé primaire |
| `vendeur` | TEXT | 5 vendeurs : Alice, Karim, Lucie, Thomas, Nadia |
| `region` | TEXT | Région du vendeur |
| `mois` | TEXT | Format 'YYYY-MM' |
| `montant` | INTEGER | CA du mois en euros |

25 lignes = 5 vendeurs × 5 mois (janvier à mai 2024) — un cas d'usage classique de suivi de performance commerciale.

---

## 🧠 GROUP BY vs Window Function — la différence fondamentale

| | GROUP BY | Window Function |
|---|---|---|
| **Effet** | Fusionne les lignes en 1 résultat par groupe | Garde toutes les lignes + ajoute une colonne calculée |
| **Exemple** | 5 vendeurs → 5 lignes | 25 ventes → 25 lignes enrichies |

```sql
-- GROUP BY : 5 lignes
SELECT vendeur, SUM(montant) FROM sales GROUP BY vendeur;

-- Window function : 25 lignes, chacune avec son rang
SELECT vendeur, mois, montant,
       RANK() OVER (ORDER BY montant DESC) AS rang
FROM sales;
```

---

## 🔑 1. ROW_NUMBER() + PARTITION BY

```sql
SELECT vendeur, mois, montant,
    ROW_NUMBER() OVER (
        PARTITION BY vendeur
        ORDER BY montant DESC
    ) AS rang_dans_vendeur
FROM sales;
```
`PARTITION BY vendeur` redémarre la numérotation à **chaque changement de vendeur**. C'est l'équivalent d'un `GROUP BY` qui ne fusionnerait pas les lignes.

**Pattern Top N par groupe** (très utilisé) :
```sql
WITH classement AS (
    SELECT vendeur, mois, montant,
        ROW_NUMBER() OVER (PARTITION BY vendeur ORDER BY montant DESC) AS rang
    FROM sales
)
SELECT vendeur, mois, montant
FROM classement
WHERE rang = 1;   -- le meilleur mois de chaque vendeur
```

---

## 🔑 2. RANK() vs DENSE_RANK() — gérer les égalités

```sql
SELECT vendeur, montant,
    RANK()       OVER (ORDER BY montant DESC) AS rk,
    DENSE_RANK() OVER (ORDER BY montant DESC) AS d_rk
FROM sales;
```

| montant | RANK | DENSE_RANK |
|---|---|---|
| 31200 | 1 | 1 |
| 21600 | 2 | 2 |
| 19200 | 3 | 3 |
| **19200** | **3** | **3** |
| 18600 | **5** | **4** |

Après une égalité : `RANK` **saute** un numéro (3, 3, 5), `DENSE_RANK` **ne saute pas** (3, 3, 4).

---

## 🔑 3. LAG() / LEAD() — comparer aux lignes voisines

```sql
SELECT vendeur, mois, montant,
    LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS mois_precedent,
    montant - LAG(montant) OVER (PARTITION BY vendeur ORDER BY mois) AS variation
FROM sales;
```
- `LAG(colonne)` → valeur de la **ligne précédente**
- `LEAD(colonne)` → valeur de la **ligne suivante**

⚠️ Le premier mois de chaque vendeur aura `mois_precedent = NULL` — il n'y a logiquement pas de mois avant.

---

## 🔑 4. Moyenne mobile (Rolling Average)

```sql
SELECT vendeur, mois, montant,
    ROUND(AVG(montant) OVER (
        PARTITION BY vendeur
        ORDER BY mois
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0) AS moyenne_mobile_3mois
FROM sales;
```
`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` définit une fenêtre glissante : la ligne actuelle + les 2 précédentes = 3 lignes.

---

## 🔑 5. Cumul progressif (Running Total)

```sql
SELECT vendeur, mois, montant,
    SUM(montant) OVER (
        PARTITION BY vendeur
        ORDER BY mois
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumul_ca
FROM sales;
```
`UNBOUNDED PRECEDING` = depuis le tout début de la partition. Résultat : le CA cumulé mois après mois pour chaque vendeur.

---

## 🔑 Bonus — NTILE() : répartir en groupes égaux

```sql
SELECT vendeur, montant,
    NTILE(4) OVER (ORDER BY montant) AS quartile
FROM sales;
```
Répartit toutes les lignes en 4 groupes de taille égale (quartiles) — utile pour identifier les 25% de ventes les plus faibles ou les plus fortes.

---

## 🧠 La syntaxe universelle

```sql
fonction() OVER (
    PARTITION BY colonne   -- optionnel : groupe de calcul
    ORDER BY colonne       -- ordre dans la fenêtre
    ROWS BETWEEN ...       -- optionnel : taille de la fenêtre
)
```

---

## 💡 Quand utiliser quoi ?

| Besoin | Fonction |
|---|---|
| Numéroter les lignes sans égalité | `ROW_NUMBER()` |
| Classer avec égalités (saute des rangs) | `RANK()` |
| Classer avec égalités (ne saute pas) | `DENSE_RANK()` |
| Comparer au mois/jour précédent | `LAG()` |
| Anticiper la valeur suivante | `LEAD()` |
| Lisser une tendance (moyenne glissante) | `AVG() OVER (ROWS BETWEEN...)` |
| Calculer un cumul progressif | `SUM() OVER (ROWS BETWEEN UNBOUNDED...)` |
| Répartir en groupes égaux | `NTILE(n)` |

---


---

⭐ **Si ce projet t'aide, mets une étoile !**
