--select
--    movie.title,
--    coalesce(cardinality(genres), 0) as genres,
--    coalesce(cardinality(keywords), 0) as keywords,
--    rating.imdb_score, rating.num_voted_users
--from   movie
--join   (
--    select movie_id, array_agg(genre::text) as genres
--    from   genre
--    where  genre = ANY('{Animation,Comedy,Family,Music,Romance}')
--    group  by movie_id
--    ) as genre on (movie.id = genre.movie_id)
--left join   (
--    select movie_id, array_agg(keyword::text) as keywords
--    from   keyword
--    where  keyword = ANY('{dance,"emperor penguin",friend,penguin,song,dance,"emperor penguin",friend,penguin,song}')
--    group  by movie_id
--    ) as keyword on (movie.id = keyword.movie_id)
--    join rating on movie.id = rating.movie_id
--order by genres desc, keywords desc, rating.imdb_score desc, rating.num_voted_users desc
--limit 30
--offset 1
--
    explain select genres, keywords
    from   movie
    join   (
        select movie_id, array_agg(genre::text) as genres
        from   genre
        where  movie_id = 398
        group  by movie_id
        ) as genre on (movie.id = genre.movie_id)
    join   (
        select movie_id, array_agg(keyword::text) as keywords
        from   keyword
        where  movie_id = 398
        group  by movie_id
        ) as keyword on (movie.id = keyword.movie_id)
    order  by movie.year
    limit 1

