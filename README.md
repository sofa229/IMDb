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

### 1.1 Dátová architektúra

**ERD diagram**  
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame (ERD):

![Chinook_ERD](https://github.com/sofa229/IMDb/blob/main/IMDB_ERD.png)

---

## 2. Dimenzionálny model

Navrhnutý bol **hviezdicový model (star schema)** pre efektívnu analýzu, kde centrálny bod predstavuje faktová tabuľka `fact_movies`, ktorá je prepojená s nasledujúcimi dimenziami:

- **dim_movies** – obsahuje podrobné informácie o filmoch (názov, rok vydania, dĺžka trvania).
- **dim_directors** – obsahuje informácie o réžiséroch (meno, dátum narodenia).
- **dim_actors** – obsahuje informácie o hercoch (meno, dátum narodenia, výška).
- **dim_genres** – obsahuje žánre jednotlivých filmov.
- **dim_dates** – obsahuje informácie o dátumoch hodnotenia (rok, mesiac, deň).

### Faktová tabuľka: `fact_ratings`

| Stĺpec           | Popis                                     |
|------------------|-------------------------------------------|
| `fact_ratingId`  | Primárny kľúč.                            |
| `movie_id`       | ID filmu.                                 |
| `user_id`        | ID používateľa.                           |
| `rating`         | Hodnotenie filmu.                         |
| `timestamp`      | Časové označenie hodnotenia.              |
| `date_id`        | ID dátumu hodnotenia (prepojené s dim_date). |
| `time_id`        | ID času hodnotenia (prepojené s dim_time). |

### Dimenzie

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

![Star_schema](https://github.com/sofa229/IMDb/blob/main/hviezdicovy_diagram.JPG)

---

## 3. ETL proces v Snowflake

ETL proces pozostával z troch hlavných fáz: **extrahovanie (Extract)**, **transformácia (Transform)** a **načítanie (Load)**. Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta zo staging vrstvy do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

### 3.1 Extract (Extrahovanie dát)

Dáta zo zdrojovej databázy boli najprv nahraté do Snowflake. Tento krok zahŕňal import dát z MySQL dumpu do staging tabuliek v Snowflake.



---

### 3.2 Transform (Transformácia dát)

V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

Príklad vytvorenia dimenzie `dim_movies`:

```sql
CREATE OR REPLACE TABLE dim_movies AS
SELECT 
    id AS movie_id,
    title,
    year,
    duration,
    country,
    languages,
    production_company
FROM movie;
