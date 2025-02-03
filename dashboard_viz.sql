--1. Priemerné hodnotenia filmov podľa roku vydania:
SELECT 
    d.year, 
    ROUND(AVG(f.avg_rating), 2) AS avg_rating
FROM fact_ratings f
JOIN dim_dates d ON f.dim_datesid = d.dim_datesid
GROUP BY d.year
ORDER BY d.year;

--2. Najobľúbenejšie filmové žánre podľa hodnotení:
SELECT 
    dm.genre, 
    ROUND(AVG(fr.avg_rating), 2) AS avg_rating
FROM fact_ratings fr
JOIN dim_movies dm ON fr.dim_id_movies = dm.dim_id_movies
GROUP BY dm.genre
ORDER BY avg_rating DESC
LIMIT 10;

--3. Najlepšie hodnotení režiséri:
SELECT 
    nd.name AS director_name, 
    COUNT(fr.dim_id_movies) AS movie_count,
    ROUND(AVG(fr.avg_rating), 2) AS avg_rating
FROM fact_ratings fr
JOIN dim_names_director nd ON fr.director_id = nd.name_id
GROUP BY nd.name
HAVING COUNT(fr.dim_id_movies) > 5
ORDER BY avg_rating DESC
LIMIT 10;


--4. Najviac obsadzovaní herci:
SELECT 
    na.name AS actor_name, 
    COUNT(fr.dim_id_movies) AS movie_count
FROM fact_ratings fr
JOIN dim_names_actor na ON fr.actor_id = na.name_id
GROUP BY na.name
ORDER BY movie_count DESC
LIMIT 10;

--5. Počet filmov podľa roku vydania:
SELECT 
    movie_year, 
    COUNT(*) AS movie_count
FROM dim_movies
GROUP BY movie_year
ORDER BY movie_year;
