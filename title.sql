select id, title, year, content_rating, imdb_score
      from   movie
      join   rating on (movie.id=rating.movie_id)
      where  title ilike '%'star war'%'
      order by year, imdb_score desc, title;
