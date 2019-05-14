-- COMP3311 19s1 Assignment 2
--
-- updates.sql
--
-- Written by Kevin Chan (z5113136), Apr 2019

--  This script takes a "vanilla" imdb database (a2.db) and
--  make all of the changes necessary to make the databas
--  work correctly with your PHP scripts.
--  
--  Such changes might involve adding new views,
--  PLpgSQL functions, triggers, etc. Other changes might
--  involve dropping or redefining existing
--  views and functions (if any and if applicable).
--  You are not allowed to create new tables for this assignment.
--  
--  Make sure that this script does EVERYTHING necessary to
--  upgrade a vanilla database; if we need to chase you up
--  because you forgot to include some of the changes, and
--  your system will not work correctly because of this, you
--  will lose half of your assignment 2 final mark as penalty.
--

--  This is to ensure that there is no trailing spaces in movie titles,
--  as some tasks need to perform full title search.
UPDATE movie SET title = TRIM (title);

--  Add your code below
DROP FUNCTION findSimilarMovies(integer, text[], text[], integer);
CREATE OR REPLACE FUNCTION findSimilarMovies (
    originalMovie integer,
    genres text[],
    keywords text[],
    max integer
)
RETURNS TABLE (
    movie_id integer,
    common_genres integer,
    common_keywords integer,
    imdb_score numeric(3,1),
    num_voted_users positiveint
) AS $$
BEGIN
    return query (
        select genre.movie_id as movie_id,
               coalesce(cardinality(genre.genres), 0) as common_genres,
               coalesce(cardinality(keyword.keywords), 0) as common_keywords,
               rating.imdb_score as imdb_score,
               rating.num_voted_users as num_voted_users

        from   (
            select genre.movie_id, array_agg(genre::text) as genres
            from   genre
            where  genre = ANY(genres)
                   and genre.movie_id != originalMovie
            group  by genre.movie_id
        ) as genre

        left join   (
            select keyword.movie_id, array_agg(keyword.keyword::text) as keywords
            from   keyword
            where  keyword = ANY(keywords)
                   and keyword.movie_id != originalMovie
            group  by keyword.movie_id
        ) as keyword on (genre.movie_id = keyword.movie_id)
        left join rating on (genre.movie_id = rating.movie_id)
         order by common_genres desc,
                  common_keywords desc,
                  rating.imdb_score desc,
                  rating.num_voted_users desc
        limit max
    );
END; $$
LANGUAGE plpgsql;


DROP FUNCTION findMovie(varchar);
CREATE OR REPLACE FUNCTION findMovie(movieTitle varchar)
RETURNS setof movie AS $$
DECLARE
BEGIN
    return query (
            select *
            from   movie
            where  movie.title ilike movieTitle
            order  by year desc
            limit  1
        );
END; $$
LANGUAGE plpgsql;

DROP FUNCTION findMovie(integer);
CREATE OR REPLACE FUNCTION findMovie(movieID integer)
RETURNS setof movie AS $$
DECLARE
BEGIN
    return query (
            select *
            from   movie
            where  movie.id = movieID
            order  by year desc
            limit  1
            );
END; $$
LANGUAGE plpgsql;


-- accepts an actor name
DROP FUNCTION findActor(varchar);
CREATE OR REPLACE FUNCTION findActor(actorName varchar)
RETURNS setof actor AS $$
DECLARE
BEGIN
        return query (
                select *
                from   actor
                where  actor.name ilike actorName
                order  by actor.name
                limit  1
            );
END; $$
LANGUAGE plpgsql;

-- accepts an actor id
DROP FUNCTION findActor(integer);
CREATE OR REPLACE FUNCTION findActor(actorID integer)
RETURNS setof actor AS $$
DECLARE
BEGIN
        return query (
                select *
                from   actor
                where  actor.id = actorID
                limit  1
            );
END; $$
LANGUAGE plpgsql;

DROP FUNCTION listActedMovies(actorName varchar);
CREATE OR REPLACE FUNCTION listActedMovies(actorName varchar)
RETURNS TABLE (
    title varchar,
    director_name varchar,
    year yeartype,
    content_rating contentRatingType,
    imdb_score numeric(3,1)
) AS $$
DECLARE
    actorID integer;
    movieIDs integer[];
BEGIN
    actorID := (select id
                from   actor
                where  name = actorName
                order by name
                limit 1);

    movieIDs := listActedMovies(actorID);

    return query (
        select m.title,
               d.name as director_name,
               m.year,
               m.content_rating,
               r.imdb_score
        from   movie m
        join   director d on (m.director_id = d.id)
        join   rating r   on (m.id = r.movie_id)
        where  m.id = ANY (movieIDs)
    );

END; $$
LANGUAGE plpgsql;

DROP FUNCTION listActedMovies(integer);
CREATE OR REPLACE FUNCTION listActedMovies(actorID integer)
RETURNS integer[] AS $$
DECLARE
BEGIN
        return (
            select array_agg(distinct movie_id)
            from   acting
            where  actor_id = actorID
        );
END; $$
LANGUAGE plpgsql;




-- Returns rows of acting relations, related to the actorID
-- DROP FUNCTION listRelations(integer);
--CREATE OR REPLACE FUNCTION listRelations(actorID integer)
--RETURNS setof acting AS $$
--DECLARE
--    movies integer[];
--    r acting;
--BEGIN
--        movies := listActedMovies(actorID);
--        RETURN query (
--            SELECT a.movie_id,
--                   a.actor_id
--            FROM   acting a
--            WHERE  a.movie_id = ANY(movies)
--                   and a.actor_id != actorID
--        );
--        RETURN;
--END; $$
--LANGUAGE plpgsql;
--
-- DROP FUNCTION shortestPath (integer, integer);
--CREATE OR REPLACE FUNCTION shortestPath (
--    srcActor integer,
--    dstActor integer
--)
--RETURNS TABLE (
--    src integer,
--    dst integer,
--    rel integer,
--    depth integer,
--    visitedMovies integer[],
--    visitedActors integer[]
--) AS $$
--DECLARE
--    relatedActors acting[];
--    actor acting;
--BEGIN
--    FOR actor IN  SELECT * FROM listRelations(srcActor)
--    LOOP
--        IF (actor.actor_id = dstActor)
--        THEN
--            RETURN QUERY (
--                select srcActor as src,
--                       actor.actor_id as dst,
--                       actor.movie_id as rel,
--                       1 as depth,
--                       ARRAY[actor.movie_id],
--                       ARRAY[srcActor, actor.actor_id]
--            );
--        ELSE
--            RETURN QUERY (
--                select *
--                from   shortestPath (
--                       actor.actor_id,
--                       dstActor,
--                       ARRAY[actor.movie_id],
--                       ARRAY[srcActor, actor.actor_id],
--                       2) sp
--            );
--        END IF;
--    END LOOP;
--    RETURN;
--END; $$
--LANGUAGE plpgsql;
--
--
-- DROP FUNCTION shortestPath (integer, integer, integer[], integer[], integer);
--CREATE OR REPLACE FUNCTION shortestPath (
--    srcActor integer,
--    dstActor integer,
--    visitedM  integer[],
--    visitedA integer[],
--    currDepth integer
--)
--RETURNS TABLE (
--    src integer,
--    dst integer,
--    rel integer,
--    depth integer,
--    visitedMovies integer[],
--    visitedActors integer[]
--) AS $$
--DECLARE
--    relatedActors acting[];
--    actor acting;
--BEGIN
--    raise warning 'currently at depth: %', currDepth;
--    FOR actor IN SELECT * FROM listRelations(srcActor)
--    LOOP
--        -- if actor is found
--        IF (actor.actor_id = dstActor)
--        THEN
--            RETURN QUERY (
--                select srcActor as src,
--                       actor.actor_id as dst,
--                       actor.movie_id as rel,
--                       currDepth as depth,
--                       array_append(visitedM, actor.movie_id),
--                       array_append(visitedA, actor.actor_id)
--            );
--        -- if node is unvisited
--        ELSIF (actor.movie_id != ALL(visitedM))
--        THEN
--            IF (currDepth+1 > 6)
--            THEN
--                RETURN;
--            END IF;
--
--        --ELSE
--            RETURN QUERY (
--                select *
--                from   shortestPath (
--                           actor.actor_id,
--                           dstActor,
--                           array_append(visitedM, actor.movie_id),
--                           array_append(visitedA, actor.actor_id),
--                           currDepth + 1
--                        ) sp
--            );
--        END IF;
--    END LOOP;
--    RETURN;
--END; $$
--LANGUAGE plpgsql;

--
--
--
--with recursive shortestPath (
--    src,
--    rel,
--    dst,
--    depth,
--    path
--)
--AS (
--    (SELECT
--           539               as src,
--           nextEdge.movie_id as rel,
--           nextEdge.actor_id as dst,
--           1                 as depth,
--           ARRAY[539, nextEdge.actor_id] as path
--    FROM
--           acting prevEdge
--           LEFT JOIN acting nextEdge on (prevEdge.movie_id = nextEdge.movie_id)
--    WHERE
--           prevEdge.actor_id = 539 and
--           nextEdge.actor_id != 539
--    )
--
--    UNION  ALL
--
--    (SELECT
--           prevEdge.dst as src,
--           nextEdge.movie_id as rel,
--           nextEdge.actor_id as dst,
--           prevEdge.depth+1  as depth,
--           array_append(prevEdge.path, nextEdge.actor_id) as path
--    FROM
--           acting nextEdge
--           JOIN shortestPath prevEdge on (prevEdge.rel = nextEdge.movie_id)
--    WHERE
--           prevEdge.depth < 5
--           and prevEdge.dst != nextEdge.actor_id
--           and nextEdge.actor_id != prevEdge.src
--           and nextEdge.actor_id != ALL(prevEdge.path)
--    )
--)
--select *
--from   shortestPath
--order by src asc, depth desc
--;
