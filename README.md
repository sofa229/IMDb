ETL Proces datasetu IMDB v Snowflake

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z datasetu IMDB. Projekt sa zameriava na preskúmanie informácií o filmoch, hercoch, žánroch a hodnoteniach. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrík.

1. Úvod a popis zdrojových dát

Cieľom projektu je analyzovať dáta týkajúce sa filmov a ich hodnotenia, ako aj informácie o hercoch a réžiséroch. Táto analýza umožňuje identifikovať najpopulárnejšie filmy, najčastejšie žánre a réžisérov s najväčším počtom režírovaných filmov.

Zdrojové dáta obsahujú tieto tabuľky:

movie – obsahuje informácie o filmoch (názov, rok vydania, krajina, jazyk, produkčná spoločnosť).

names – obsahuje informácie o hercoch a réžiséroch (meno, dátum narodenia, známe filmy).

director_mapping – spája filmy s réžisérmi.

role_mapping – spája filmy s hercami.

ratings – obsahuje hodnotenia filmov (priemerné hodnotenie, počet hlasov).

genre – obsahuje žánre jednotlivých filmov.

1.1 Dátová architektúra

ERD diagram

Surové dáta sú usporiadané v relačnom modeli, ktorý je znázorníený na entitno-relačnom diagrame (ERD):

(Vlož sem ERD diagram ako obrázok z priečinka DOCS)

2. Dimenzionálny model

Navrhnutý bol hviezdicový model (star schema), pre efektívnu analýzu, kde centrálny bod predstavuje faktová tabuľka fact_movies, ktorá je prepojená s nasledujúcimi dimenziami:

dim_movies – obsahuje podrobné informácie o filmoch (názov, rok vydania, dĺžka trvania).

dim_directors – obsahuje informácie o réžiséroch (meno, dátum narodenia).

dim_actors – obsahuje informácie o hercoch (meno, dátum narodenia, výška).

dim_genres – obsahuje žánre jednotlivých filmov.

dim_dates – obsahuje informácie o dátumoch hodnotenia (rok, mesiac, deň).
Faktová tabuľka: fact_ratings
Táto tabuľka bude obsahovať informácie o hodnoteniach filmov.

Stĺpec	Popis
fact_ratingId	Primárny kľúč.
movie_id	ID filmu.
user_id	ID používateľa.
rating	Hodnotenie filmu.
timestamp	Časové označenie hodnotenia.
date_id	ID dátumu hodnotenia (prepojené s dim_date).
time_id	ID času hodnotenia (prepojené s dim_time).
Dimenzie
dim_movie: Obsahuje detaily o filmoch.
Atribúty: movie_id, title, year, duration, country, languages, production_company.

dim_director: Informácie o režiséroch.
Atribúty: director_id, name, date_of_birth, known_for_movies.

dim_actor: Informácie o hercoch.
Atribúty: actor_id, name, category, known_for_movies.

dim_genre: Obsahuje detaily o žánroch.
Atribúty: genre_id, name.

dim_date: Informácie o dátume hodnotenia.
Atribúty: date_id, day, month, year, quarter.

dim_time: Podrobné časové údaje.
Atribúty: time_id, hour, minute, ampm.


Štruktúra hviezdicového modelu je znázorníená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami, čo zjednodušuje pochopenie a implementáciu modelu.

(Vlož sem diagram hviezdicového modelu ako obrázok z priečinka DOCS)

3. ETL proces v Snowflake

ETL proces pozostával z troch hlavných fáz: extrahovanie (Extract), transformácia (Transform) a načítanie (Load). Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta zo staging vrstvy do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

3.1 Extract (Extrahovanie dát)

Dáta zo zdrojovej databázy boli najprv nahraté do Snowflake. Tento krok zahŕňal import dát z MySQL dumpu do staging tabuliek v Snowflake.

(Tu vlož príkaz alebo postup, ktorý bol použitý na extrakciu dát)

3.2 Transform (Transformácia dát)

V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

Príklad vytvorenia dimenzie dim_movies

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

(Podobne sem vlož príklady na vytvorenie ostatných dimenzií)

3.3 Load (Načítanie dát)

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta nahraté do finálnej štruktúry. Na záver boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:

DROP TABLE IF EXISTS movie_staging;
DROP TABLE IF EXISTS names_staging;
DROP TABLE IF EXISTS director_mapping_staging;
DROP TABLE IF EXISTS role_mapping_staging;
DROP TABLE IF EXISTS ratings_staging;
DROP TABLE IF EXISTS genre_staging;

4. Vizualizácia dát

Dashboard obsahuje 5 vizualizácií, ktoré poskytujú základný prehľad o kľúčových metríkach a trendoch týkajúcich sa filmov a hodnotenia. Tieto vizualizácie odpovedajú na dôležité otázky a umožňujú lepšie pochopiť správanie užívateľov a ich preferencie.

Graf 1: Top 10 najlepšie hodnotených filmov

Táto vizualizácia zobrazuje 10 filmov s najvyšším priemerným hodnotením.

SELECT 
    m.title AS movie_title,
    f.avg_rating
FROM fact_movies f
JOIN dim_movies m ON f.movie_id = m.movie_id
ORDER BY f.avg_rating DESC
LIMIT 10;

(Podobne sem vlož SQL dotazy a popisy pre ostatné grafy)

5. Záver

ETL proces v Snowflake umožnil spracovanie surových dát do viacdimenzionálneho modelu typu hviezda. Tento proces zahŕňal čistenie, obohacovanie a reorganizáciu dát. Výsledný model umožňuje analýzu filmov, ich hodnotenia a správania užívateľov, čo poskytuje základ pre vizualizácie a reporty.

Meno a priezvisko: (dopľň svoje meno)

Snowflake meno: HEDGEHOG

