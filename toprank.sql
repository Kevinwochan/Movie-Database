explain select title, year, content_rating,
imdb_score, num_voted_users,
genres
from
(
    select title, year, content_rating, genres, movie.id, imdb_score, num_voted_users,
    from
    (
        select id, title, year, content_rating
        from   movie
        join   rating on (movie.id=rating.movie_id)
        where  year <= 2005 and year >= 2005 and year is not null
    ) as movie
    join (
    select movie_id as id, array_agg(genre::text) as genres
    from   genre
    group  by movie_id
    ) as genre on (movie.id = genre.id)
    where genres @> '{Sci-Fi, Action, Adventure}'
) as movie
order  by imdb_score desc, title


--select id, title, year, content_rating, imdb_score, num_voted_users
--from   movie
--join   rating on (movie.id=rating.movie_id)
--where  year <= 2019 and year >= 1920 and year is not null
--order by imdb_score desc, num_voted_users desc
--limit 20

