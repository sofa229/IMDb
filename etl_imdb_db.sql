CREATE DATABASE IF NOT EXISTS HEDGEHOG_imdb;
USE HEDGEHOG_imdb;
--- Vytvorenie a použitie schémy
CREATE SCHEMA HEDGEHOG_imdb.staging;
USE SCHEMA HEDGEHOG_imdb.staging;
--- Vytvorenie stagu 
CREATE OR REPLACE STAGE HEDGEHOG_stage;

CREATE TABLE movie_staging(
    movie_id VARCHAR(10) PRIMARY KEY, 
    movie_title VARCHAR(200),
    movie_year INT,
    date_published DATE,
    duration INT,
    movie_country VARCHAR(250),
    income VARCHAR(30),
    languages VARCHAR(200),
    company VARCHAR(200)   
);

CREATE TABLE name_staging(
    name_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    height INT NULL,
    date_of_birth DATE,
    known_for_movies VARCHAR(100)
);

CREATE TABLE director_mapping_staging(
    movie_id VARCHAR(10),
    name_id VARCHAR(10),
    FOREIGN KEY (movie_id) REFERENCES movie_staging(movie_id),
    FOREIGN KEY (name_id) REFERENCES name_staging(name_id)

);

CREATE TABLE role_mapping_staging(
    movie_id VARCHAR(10),
    name_id VARCHAR(10),
    category VARCHAR(10),
    FOREIGN KEY (movie_id) REFERENCES movie_staging(movie_id),
    FOREIGN KEY (name_id) REFERENCES name_staging(name_id)

);

CREATE TABLE ratings_staging(
    movie_id VARCHAR(10),
    avg_rating DECIMAL(3,1),
    total_votes INT,
    median_rating INT,
    FOREIGN KEY (movie_id) REFERENCES movie_staging(movie_id)
   
);

CREATE TABLE genre_staging(
    movie_id VARCHAR(10),
    genre VARCHAR(20) PRIMARY KEY,
    FOREIGN KEY (movie_id) REFERENCES movie_staging(movie_id)
   
);

CREATE TABLE dim_movies AS SELECT DISTINCT
    m.movie_id AS dim_id_movies, 
    m.movie_title,
    m.movie_year,
    m.date_published,
    m.movie_country,
    m.income,
    m.languages,
    m.company,
    g.genre AS Genre,
FROM movie_staging m
LEFT JOIN genre_staging g ON m.movie_id = g.movie_id;


CREATE TABLE dim_dates AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CAST(date_published AS DATE)) AS dim_datesID, 
    CAST(date_published AS DATE) AS date,
    DATE_PART(day,date_published) AS day,
    DATE_PART(dayofweek,date_published) + 1 AS dayOfWeek,
    CASE DATE_PART(dayofweek, date_published) + 1
        WHEN 1 THEN 'Pondelok'
        WHEN 2 THEN 'Utorok'
        WHEN 3 THEN 'Streda'
        WHEN 4 THEN 'Štvrtok'
        WHEN 5 THEN 'Piatok'
        WHEN 6 THEN 'Sobota'
        WHEN 7 THEN 'Nedeľa'
    END AS DayOfWeek_String,
    DATE_PART(week, date_published) AS week,
    DATE_PART(month, date_published) AS month,
    CASE DATE_PART(month, date_published)
        WHEN 1 THEN 'Január'
        WHEN 2 THEN 'Február'
        WHEN 3 THEN 'Marec'
        WHEN 4 THEN 'Apríl'
        WHEN 5 THEN 'Máj'
        WHEN 6 THEN 'Jún'
        WHEN 7 THEN 'Júl'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'Október'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS month_String,
    DATE_PART(year, date_published) AS year,
FROM MOVIE_STAGING
GROUP BY CAST(date_published AS DATE), 
         DATE_PART(day, date_published), 
         DATE_PART(dayofweek, date_published),
         DATE_PART(week, date_published),
         DATE_PART(month, date_published), 
         DATE_PART(year, date_published);

         
CREATE OR REPLACE TABLE dim_NAMES_ACTOR AS SELECT DISTINCT
    n.name_id,
    n.name,
    n.date_of_birth,
    CASE 
    WHEN n.known_for_movies IS NOT NULL AND m.movie_title IS NOT NULL THEN m.movie_title ELSE n.known_for_movies
    END AS known_for_movies,
    r.category,
FROM name_staging n
INNER JOIN role_mapping_staging r ON n.name_id = r.name_id
INNER JOIN movie_staging m ON r.movie_id = m.movie_id;


CREATE OR REPLACE TABLE dim_NAMES_director AS SELECT DISTINCT
    n.name_id,
    n.name,
    n.date_of_birth,
    CASE 
    WHEN n.known_for_movies IS NOT NULL AND m.movie_title IS NOT NULL THEN m.movie_title ELSE n.known_for_movies
    END AS known_for_movies,
FROM name_staging n
INNER JOIN director_mapping_staging d ON n.name_id = d.name_id
INNER JOIN movie_staging m ON d.movie_id = m.movie_id;


CREATE OR REPLACE TABLE fact_ratings AS SELECT DISTINCT
    r.avg_rating,
    r.total_votes,
    r.median_rating,
    na.name_id AS Actor_id,
    nd.name_id AS Director_id,
    m.dim_id_movies,
    d.dim_datesid,
FROM ratings_staging r
LEFT JOIN dim_movies m ON r.movie_id = m.dim_id_movies
LEFT JOIN dim_dates d ON m.date_published = d.date
LEFT JOIN role_mapping_staging ro ON m.dim_id_movies = ro.movie_id
LEFT JOIN dim_names_actor na ON ro.name_id = na.name_id
LEFT JOIN DIRECTOR_MAPPING_STAGING ma ON m.dim_id_movies = ma.movie_id
LEFT JOIN dim_names_director nd ON ma.name_id = nd.name_id;
