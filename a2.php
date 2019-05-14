<?php

// If you want to use the COMP3311 DB Access Library, include the following two lines
//
define("LIB_DIR","/import/adams/1/cs3311/public_html/19s1/assignments/a2");
require_once(LIB_DIR."/db.php");

// Your DB connection parameters, e.g., database name
//
define("DB_CONNECTION","dbname=a2");
$db = dbConnect(DB_CONNECTION);

//
// Include your other common PHP code below
// E.g., common constants, functions, etc.
//

// returns an actor record set
// accepts an actorName, actorID, array of actorIDs
function getActor($actor){
    if (is_array($actor)){
        $actors = join(',',$actor);
        $query = 'select name from actor where id = ANY(ARRAY[%L]::int[])';
        return dbAllTuples($GLOBALS['db'], mkSQL($query, $actors));
    } else if (is_numeric($actor)){
        $query = 'select * from findActor(%d);';
    }else{
        $query = 'select * from findActor(%s);';
    }
    return dbOneTuple($GLOBALS['db'], mkSQL($query, $actor));
}

// returns a movie record set
// accepts a movieID or a case insensitive movie title
function getMovie($movie){
    if (is_numeric($movie)){
        $query = 'select title, year from findMovie(%d);';
    }else{
        $query = 'select id, title, year from findMovie(%s);';
    }
    return dbOneTuple($GLOBALS['db'], mkSQL($query, $movie));
}


?>
