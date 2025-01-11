CREATE DATABASE IF NOT EXISTS imdb;
USE imdb;

-- Tabuľka movie
CREATE TABLE movie (
    id VARCHAR(10) NOT NULL,
    title NVARCHAR(200) NOT NULL,
    year INT,
    date_published DATE,
    duration INT,
    country NVARCHAR(250),
    worlwide_gross_income NVARCHAR(30),
    languages NVARCHAR(200),
    production_company NVARCHAR(200),
    CONSTRAINT PK_movie PRIMARY KEY (id)
);

-- Tabuľka genre
CREATE TABLE genre (
    movie_id VARCHAR(10) NOT NULL,
    genre NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_genre PRIMARY KEY (movie_id, genre)
);

-- Tabuľka ratings
CREATE TABLE ratings (
    movie_id VARCHAR(10) NOT NULL,
    avg_rating DECIMAL(3, 1),
    total_votes INT,
    median_rating INT,
    CONSTRAINT PK_ratings PRIMARY KEY (movie_id)
);

-- Tabuľka names
CREATE TABLE names (
    id VARCHAR(10) NOT NULL,
    name NVARCHAR(100),
    height INT,
    date_of_birth DATE,
    known_for_movies NVARCHAR(100),
    CONSTRAINT PK_names PRIMARY KEY (id)
);

-- Tabuľka director_mapping
CREATE TABLE director_mapping (
    movie_id VARCHAR(10) NOT NULL,
    name_id VARCHAR(10) NOT NULL,
    CONSTRAINT PK_director_mapping PRIMARY KEY (movie_id, name_id)
);

-- Tabuľka role_mapping
CREATE TABLE role_mapping (
    movie_id VARCHAR(10) NOT NULL,
    name_id VARCHAR(10) NOT NULL,
    category NVARCHAR(20),
    CONSTRAINT PK_role_mapping PRIMARY KEY (movie_id, name_id)
);

-- Dimenzia filmov
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

-- Dimenzia žánrov
CREATE OR REPLACE TABLE dim_genres AS
SELECT DISTINCT 
    movie_id,
    genre
FROM genre;

-- Dimenzia režisérov
CREATE OR REPLACE TABLE dim_directors AS
SELECT 
    dm.movie_id,
    n.name AS director_name,
    n.date_of_birth
FROM director_mapping dm
JOIN names n ON dm.name_id = n.id;

-- Dimenzia hercov
CREATE OR REPLACE TABLE dim_actors AS
SELECT 
    rm.movie_id,
    n.name AS actor_name,
    n.height,
    n.date_of_birth
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
WHERE rm.category = 'actor';

-- Dimenzia dátumov
CREATE OR REPLACE TABLE dim_dates AS
SELECT 
    DISTINCT DATE_PART('year', date_published) AS year,
    DATE_PART('month', date_published) AS month,
    DATE_PART('day', date_published) AS day,
    date_published AS full_date
FROM movie
WHERE date_published IS NOT NULL;

CREATE OR REPLACE TABLE fact_movies AS
SELECT 
    m.id AS movie_id,
    r.avg_rating,
    r.total_votes,
    r.median_rating,
    m.worlwide_gross_income
FROM movie m
LEFT JOIN ratings r ON m.id = r.movie_id;

