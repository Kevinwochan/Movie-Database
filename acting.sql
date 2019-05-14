select title, director.name, year, content_rating, imdb_score
      from   movie
      join   director on (movie.director_id=director.id)
      join   rating on (movie.id=rating.movie_id)
      where  movie.id in (
           select   movie_id
           from     acting
           where    actor_id = (
                select id
                from   actor
                where  name = 'James Franco'
           )
      )
      order by year, title;
