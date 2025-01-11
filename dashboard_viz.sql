--1. Top 10 najlepšie hodnotených filmov:
SELECT 
    m.title AS movie_title,
    DATE_PART('year', m.date_published) AS release_year,
    r.avg_rating AS average_rating,
    r.total_votes AS total_votes
FROM movie m
JOIN ratings r ON m.id = r.movie_id
ORDER BY r.avg_rating DESC
LIMIT 10;

--2. Počet filmov podľa žánru:
SELECT 
    g.genre,
    COUNT(g.movie_id) AS num_movies
FROM genre g
GROUP BY g.genre
ORDER BY num_movies DESC;

--3. Celkové tržby filmov podľa rokov:
SELECT 
    DATE_PART('year', m.date_published) AS year,
    SUM(TRY_TO_NUMBER(REPLACE(m.worlwide_gross_income, '$', ''))) AS total_gross
FROM movie m
WHERE m.worlwide_gross_income IS NOT NULL
GROUP BY DATE_PART('year', m.date_published)
ORDER BY year;

--4. Počet vydaných filmov podľa rokov:
SELECT 
    DATE_PART('year', m.date_published) AS year,
    COUNT(m.id) AS num_movies
FROM movie m
WHERE m.date_published IS NOT NULL
GROUP BY DATE_PART('year', m.date_published)
ORDER BY year;

--5. Priemerné hodnotenie filmov podľa žánru:
SELECT 
    g.genre,
    AVG(r.avg_rating) AS avg_rating,
    COUNT(g.movie_id) AS num_movies
FROM genre g
JOIN ratings r ON g.movie_id = r.movie_id
GROUP BY g.genre
ORDER BY avg_rating DESC;
