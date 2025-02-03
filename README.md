# ETL Proces datasetu IMDB v Snowflake

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z datasetu IMDB. Projekt sa zameriava na preskúmanie informácií o filmoch, hercoch, žánroch a hodnoteniach. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrík.

## 1. Úvod a popis zdrojových dát

Cieľom projektu je analyzovať dáta týkajúce sa filmov a ich hodnotenia, ako aj informácie o hercoch a réžiséroch. Táto analýza umožňuje identifikovať najpopulárnejšie filmy, najčastejšie žánre a réžisérov s najväčším počtom režírovaných filmov.

Zdrojové dáta obsahujú tieto tabuľky:

- **movie** – obsahuje informácie o filmoch (názov, rok vydania, krajina, jazyk, produkčná spoločnosť).
- **names** – obsahuje informácie o hercoch a réžiséroch (meno, dátum narodenia, známe filmy).
- **director_mapping** – spája filmy s réžisérmi.
- **role_mapping** – spája filmy s hercami.
- **ratings** – obsahuje hodnotenia filmov (priemerné hodnotenie, počet hlasov).
- **genre** – obsahuje žánre jednotlivých filmov.

## 1.1 Dátová architektúra

**ERD diagram**  

![Chinook_ERD](https://github.com/sofa229/IMDb/blob/main/IMDB_ERD.png)

---

## 2. Dimenzionálny model

Dimenzionálny model bol navrhnutý tak, aby umožňoval efektívnu analytiku filmových dát. Použitá je hviezdicová schéma (Star Schema), kde faktová tabuľka obsahuje metriky o hodnoteniach filmov a dimenzie poskytujú kontext pre analýzu.

## Faktová tabuľka: `fact_ratings`

| Stĺpec          | Typ         | Popis |
|----------------|------------|------------------------------|
| avg_rating   | DECIMAL(3,1) | Priemerné hodnotenie filmu |
| total_votes  | INT        | Celkový počet hlasov |
| median_rating| INT        | Mediánové hodnotenie filmu |
| Actor_id     | VARCHAR(10) | Identifikátor herca |
| Director_id  | VARCHAR(10) | Identifikátor režiséra |
| dim_id_movies | VARCHAR(10) | Identifikátor filmu |
| dim_datesid  | INT        | Identifikátor dátumu hodnotenia |

## Dimenzie

#### dim_movies

| Stĺpec          | Typ          | Popis |
|----------------|-------------|---------------------------|
| dim_id_movies | VARCHAR(10) | Identifikátor filmu |
| movie_title  | VARCHAR(200) | Názov filmu |
| movie_year   | INT         | Rok vydania |
| date_published | DATE        | Dátum vydania |
| movie_country | VARCHAR(250) | Krajina |
| income       | VARCHAR(30)  | Príjmy z filmu |
| languages    | VARCHAR(200) | Jazyky vo filme |
| company      | VARCHAR(200) | Produkčná spoločnosť |
| genre        | VARCHAR(20)  | Žáner filmu |


#### dim_dates

| Stĺpec        | Typ  | Popis |
|--------------|------|----------------------|
| dim_datesID | INT  | Identifikátor dátumu |
| date       | DATE | Dátum vydania filmu |
| day        | INT  | Deň v mesiaci |
| dayOfWeek  | INT  | Deň v týždni |
| DayOfWeek_String | VARCHAR(10) | Názov dňa |
| week       | INT  | Číslo týždňa |
| month      | INT  | Číslo mesiaca |
| month_String | VARCHAR(10) | Názov mesiaca |
| year       | INT  | Rok |

#### dim_names_actor

| Stĺpec          | Typ          | Popis |
|----------------|-------------|---------------------------|
| name_id      | VARCHAR(10) | Identifikátor herca |
| name        | VARCHAR(100) | Meno herca |
| date_of_birth | DATE        | Dátum narodenia |
| known_for_movies | VARCHAR(100) | Najznámejšie filmy |
| category      | VARCHAR(10)  | Kategória roly |



#### dim_names_director

| Stĺpec         | Typ          | Popis |
|---------------|-------------|---------------------------|
| name_id     | VARCHAR(10) | Identifikátor režiséra |
| name       | VARCHAR(100) | Meno režiséra |
| date_of_birth | DATE        | Dátum narodenia |
| known_for_movies | VARCHAR(100) | Najznámejšie filmy |

![Star Schema](https://github.com/sofa229/IMDb/blob/4c2ce4cabd7c96cc1035950396f297daf9d50874/hviezdicovyimdb.png?raw=true)

---

## 3. ETL proces v Snowflake

ETL proces pozostával z troch hlavných fáz: **extrahovanie (Extract)**, **transformácia (Transform)** a **načítanie (Load)**. Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta zo staging vrstvy do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

## **3.1 Extract (Extrahovanie dát)**

Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do **Snowflake** prostredníctvom interného stage úložiska s názvom `HEDGEHOG_stage`.  
Stage v **Snowflake** slúži ako dočasné úložisko na import alebo export dát.  
Vytvorenie stage bolo zabezpečené príkazom:

```sql
CREATE OR REPLACE STAGE HEDGEHOG_stage;
```
---
Do stage boli následne nahraté súbory obsahujúce údaje o filmoch, žánroch, réžiách, rolách, menách a hodnoteniach. Dáta boli importované do staging tabuliek pomocou príkazu COPY INTO. Pre každú tabuľku sa použil podobný príkaz:
---
```sql
COPY INTO movie_staging
FROM @HEDGEHOG_stage/movie.csv  
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```
---
## 3.2 Transformácia dát (Transform)
Transformácie zahŕňali vytvorenie dimenzií a faktovej tabuľky.

#### Dimenzia dim_movies
Obsahuje informácie o filmoch vrátane názvu, roku vydania, krajiny, jazyka a produkčnej spoločnosti.
Táto dimenzia je typu SCD 1, pretože aktualizácie údajov prepíšu pôvodné hodnoty bez uchovania histórie.

```sql
CREATE OR REPLACE TABLE dim_movies AS
SELECT DISTINCT
    m.movie_id,
    m.movie_title,
    m.movie_year,
    m.date_published,
    m.movie_country,
    m.income,
    m.languages,
    m.company,
    g.genre
FROM movie_staging m
LEFT JOIN genre_staging g ON m.movie_id = g.movie_id;
```
#### Dimenzia dim_dates
Obsahuje informácie o dňoch, mesiacoch a rokoch vydania filmov. Keďže údaje o žánroch sa menia veľmi zriedkavo, použili sme typ SCD 1, ktorý prepíše staré hodnoty bez uchovávania historických zmien.

```sql
CREATE OR REPLACE TABLE dim_dates AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CAST(date_published AS DATE)) AS dim_datesID,
    CAST(date_published AS DATE) AS date,
    DATE_PART(day, date_published) AS day,
    DATE_PART(month, date_published) AS month,
    DATE_PART(year, date_published) AS year
FROM movie_staging
WHERE date_published IS NOT NULL;
```
#### Dimenzia dim_names_actor
Obsahuje informácie o hercoch a ich známych filmoch.
Táto dimenzia je typu SCD 1, pretože akékoľvek zmeny údajov budú prepísané bez sledovania histórie.

```sql
CREATE OR REPLACE TABLE dim_names_actor AS
SELECT DISTINCT
    n.name_id,
    n.name,
    n.date_of_birth,
    COALESCE(m.movie_title, n.known_for_movies) AS known_for_movies,
    r.category
FROM name_staging n
INNER JOIN role_mapping_staging r ON n.name_id = r.name_id
INNER JOIN movie_staging m ON r.movie_id = m.movie_id;
```
#### Dimenzia dim_names_director
Obsahuje informácie o réžíroch a ich známych filmoch. Vzhľadom na to, že údaje o hercoch sa môžu občas meniť, ale bez nutnosti sledovania historických zmien, bola zvolená stratégia SCD 1, kde nové údaje nahrádzajú pôvodné.

```sql
CREATE OR REPLACE TABLE dim_names_director AS
SELECT DISTINCT
    n.name_id,
    n.name,
    n.date_of_birth,
    COALESCE(m.movie_title, n.known_for_movies) AS known_for_movies
FROM name_staging n
INNER JOIN director_mapping_staging d ON n.name_id = d.name_id
INNER JOIN movie_staging m ON d.movie_id = m.movie_id;
```
---
Vytvorenie faktovej tabuľky:
Príklad vytvorenia faktovej tabuľky fact_ratings:

```sql
CREATE OR REPLACE TABLE fact_ratings AS
SELECT DISTINCT
    r.avg_rating,
    r.total_votes,
    r.median_rating,
    na.name_id AS Actor_id,
    nd.name_id AS Director_id,
    m.movie_id,
    d.dim_datesid
FROM ratings_staging r
LEFT JOIN dim_movies m ON r.movie_id = m.movie_id
LEFT JOIN dim_dates d ON m.date_published = d.date
LEFT JOIN role_mapping_staging ro ON m.movie_id = ro.movie_id
LEFT JOIN dim_names_actor na ON ro.name_id = na.name_id
LEFT JOIN director_mapping_staging ma ON m.movie_id = ma.movie_id
LEFT JOIN dim_names_director nd ON ma.name_id = nd.name_id;
```
### **3.3 Load (Načítanie dát)**

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta nahraté do finálnej štruktúry. Na záver boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:

```sql
DROP TABLE IF EXISTS movie_staging;
DROP TABLE IF EXISTS genre_staging;
DROP TABLE IF EXISTS director_mapping_staging;
DROP TABLE IF EXISTS role_mapping_staging;
DROP TABLE IF EXISTS name_staging;
DROP TABLE IF EXISTS ratings_staging;
```
## **4. Vizualizácia dát**
Navrhnutých bolo 5 vizualizácií, ktoré poskytujú prehľad o dôležitých metrikách:
---
### 1. Priemerné hodnotenia filmov podľa roku vydania:

```sql 
SELECT 
    d.year, 
    ROUND(AVG(f.avg_rating), 2) AS avg_rating
FROM fact_ratings f
JOIN dim_dates d ON f.dim_datesid = d.dim_datesid
GROUP BY d.year
ORDER BY d.year;
```
![Snímka obrazovky (342)](graf_podla_r_vydania.JPG)  

### 2. Počet filmov podľa žánru:
Dotaz analyzuje počet filmov priradených ku každému žánru. Z grafu vyplýva, že najviac filmov patrí do žánru Drama, nasledujú žánre Thriller, Comedy a Action.

```sql
SELECT 
    g.genre,
    COUNT(g.movie_id) AS num_movies
FROM genre g
GROUP BY g.genre
ORDER BY num_movies DESC;
```
![Snímka obrazovky (344)](https://github.com/sofa229/IMDb/blob/main/pocet_filmov_pre_zaner.JPG) 

### 3. Počet vydaných filmov podľa rokov:
Dotaz zobrazuje počet vydaných filmov pre každý rok. Graf ukazuje, že najviac filmov bolo vydaných v roku 2017, mierne menej v roku 2018 a najmenej v roku 2019.

```sql
CREATE OR REPLACE VIEW view_num_movies_by_year AS
SELECT 
    DATE_PART('year', m.date_published) AS year,
    COUNT(m.id) AS num_movies
FROM movie m
WHERE m.date_published IS NOT NULL
GROUP BY DATE_PART('year', m.date_published)
ORDER BY year;
```
![Snímka obrazovky (349)](https://github.com/sofa229/IMDb/blob/main/pocet_vydanych_filmov_podla_rokov.JPG)

### 4. Priemerné hodnotenie filmov podľa žánru:
Dotaz analyzuje priemerné hodnotenie filmov pre každý žáner. Z výsledkov vyplýva, že žáner Others má najvyššie priemerné hodnotenie, nasledujú žánre Drama, Romance a Family.

```sql
CREATE OR REPLACE VIEW view_avg_rating_by_genre AS
SELECT 
    g.genre,
    AVG(r.avg_rating) AS avg_rating,
    COUNT(g.movie_id) AS num_movies
FROM genre g
JOIN ratings r ON g.movie_id = r.movie_id
GROUP BY g.genre
ORDER BY avg_rating DESC;
```
![Snímka obrazovky (346)](https://github.com/sofa229/IMDb/blob/main/priemerne_recenzie.JPG) 

### 5. Top 10 najlepšie hodnotených filmov:
Dotaz identifikuje filmy s najvyšším priemerným hodnotením. Z tohto grafu vyplýva, že film Vaikai is Amerikos viesbucio má najvyššie hodnotenie, nasledujú filmy ako A Matter of Life and Death a Der müde Tod.

```sql
SELECT 
    m.title AS movie_title,
    DATE_PART('year', m.date_published) AS release_year,
    r.avg_rating AS average_rating,
    r.total_votes AS total_votes
FROM movie m
JOIN ratings r ON m.id = r.movie_id
ORDER BY r.avg_rating DESC
LIMIT 10;
```
![Snímka obrazovky (347)](https://github.com/sofa229/IMDb/blob/main/top_10.JPG)

```sql
Autor: Sofia Kučerová
```



