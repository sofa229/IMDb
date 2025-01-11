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

Navrhnutý bol **hviezdicový model (star schema)** pre efektívnu analýzu, kde centrálny bod predstavuje faktová tabuľka `fact_movies`, ktorá je prepojená s nasledujúcimi dimenziami:

- **dim_movies** – obsahuje podrobné informácie o filmoch (názov, rok vydania, dĺžka trvania).
- **dim_directors** – obsahuje informácie o réžiséroch (meno, dátum narodenia).
- **dim_actors** – obsahuje informácie o hercoch (meno, dátum narodenia, výška).
- **dim_genres** – obsahuje žánre jednotlivých filmov.
- **dim_dates** – obsahuje informácie o dátumoch hodnotenia (rok, mesiac, deň).

## Faktová tabuľka: `fact_ratings`

| Stĺpec           | Popis                                     |
|------------------|-------------------------------------------|
| `fact_ratingId`  | Primárny kľúč.                            |
| `movie_id`       | ID filmu.                                 |
| `user_id`        | ID používateľa.                           |
| `rating`         | Hodnotenie filmu.                         |
| `timestamp`      | Časové označenie hodnotenia.              |
| `date_id`        | ID dátumu hodnotenia (prepojené s dim_date). |
| `time_id`        | ID času hodnotenia (prepojené s dim_time). |

## Dimenzie

- **`dim_movie`**: Obsahuje detaily o filmoch.  
  **Atribúty**: `movie_id`, `title`, `year`, `duration`, `country`, `languages`, `production_company`.

- **`dim_director`**: Informácie o režiséroch.  
  **Atribúty**: `director_id`, `name`, `date_of_birth`, `known_for_movies`.

- **`dim_actor`**: Informácie o hercoch.  
  **Atribúty**: `actor_id`, `name`, `category`, `known_for_movies`.

- **`dim_genre`**: Obsahuje detaily o žánroch.  
  **Atribúty**: `genre_id`, `name`.

- **`dim_date`**: Informácie o dátume hodnotenia.  
  **Atribúty**: `date_id`, `day`, `month`, `year`, `quarter`.

- **`dim_time`**: Podrobné časové údaje.  
  **Atribúty**: `time_id`, `hour`, `minute`, `ampm`.

---

![Star_schema](https://github.com/sofa229/IMDb/blob/main/star_diagram.png)

---

## 3. ETL proces v Snowflake

ETL proces pozostával z troch hlavných fáz: **extrahovanie (Extract)**, **transformácia (Transform)** a **načítanie (Load)**. Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta zo staging vrstvy do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

## **3.1 Extract (Extrahovanie dát)**

Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do **Snowflake** prostredníctvom interného stage úložiska s názvom `my_stage`.  
Stage v **Snowflake** slúži ako dočasné úložisko na import alebo export dát.  
Vytvorenie stage bolo zabezpečené príkazom:

```sql
CREATE OR REPLACE STAGE my_stage;
```
---
Do stage boli následne nahraté súbory obsahujúce údaje o knihách, používateľoch, hodnoteniach, zamestnaniach a úrovniach vzdelania.
Dáta boli importované do staging tabuliek pomocou príkazu COPY INTO.
Pre každú tabuľku sa použil podobný príkaz:
---
```sql
COPY INTO occupations_staging
FROM @my_stage/occupations.csv
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';
```
Parameter ON_ERROR = 'CONTINUE' zabezpečil pokračovanie procesu bez prerušenia pri výskyte nekonzistentných záznamov.


---
## 3.2 Transformácia dát (Transform)
Transformácie zahŕňali vytvorenie dimenzií a faktovej tabuľky.

Vytvorenie dimenzií:
Príklad vytvorenia dimenzií dim_artist a dim_album:

```sql
CREATE OR REPLACE TABLE dim_artist AS
SELECT `ArtistId`, `Name`
FROM `artist`;
```
```sql
Kopírovať kód
CREATE OR REPLACE TABLE dim_album AS
SELECT `AlbumId`, `Title`, `ArtistId`
FROM `album`;
```
---
Vytvorenie faktovej tabuľky:
Príklad vytvorenia faktovej tabuľky fact_invoice_line:

```sql
CREATE OR REPLACE TABLE fact_invoice_line AS
SELECT 
  il.`InvoiceLineId`, 
  il.`InvoiceId`, 
  il.`TrackId`, 
  il.`UnitPrice`, 
  il.`Quantity`, 
  il.`UnitPrice` * il.`Quantity` AS TotalAmount,
  i.`InvoiceDate`, 
  i.`CustomerId`
FROM `invoiceline` il
JOIN `invoice` i ON il.`InvoiceId` = i.`InvoiceId`;
```
### **3.3 Load (Načítanie dát)**

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta nahraté do finálnej štruktúry. Na záver boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:

```sql
DROP TABLE IF EXISTS artist_staging;
DROP TABLE IF EXISTS album_staging;
DROP TABLE IF EXISTS invoiceline_staging;
DROP TABLE IF EXISTS invoice_staging;
DROP TABLE IF EXISTS customer_staging;
DROP TABLE IF EXISTS track_staging;
```
## **4. Vizualizácia dát**
Navrhnutých bolo 5 vizualizácií, ktoré poskytujú prehľad o dôležitých metrikách:
---
### 1. Celkové tržby filmov podľa rokov:
Dotaz sumarizuje celkové tržby za filmy podľa rokov. Z výsledkov vidieť, že najvyššie tržby boli dosiahnuté v roku 2017, nasleduje rok 2018. Rok 2019 vykazuje nižšie tržby, pravdepodobne kvôli menšiemu počtu vydaných filmov v tomto roku.

```sql
CREATE OR REPLACE VIEW view_total_gross_by_year AS
SELECT 
    DATE_PART('year', m.date_published) AS year,
    SUM(TRY_TO_NUMBER(REPLACE(m.worlwide_gross_income, '$', ''))) AS total_gross
FROM movie m
WHERE m.worlwide_gross_income IS NOT NULL
GROUP BY DATE_PART('year', m.date_published)
ORDER BY year;
```
![Snímka obrazovky (342)](https://github.com/sofa229/IMDb/blob/main/celkove_trzby.JPG)  

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



