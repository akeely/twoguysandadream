<?php

#########
# NOTE: Error messages commented out. Move to mySQL. (search for open())
#########
#variables that will be used later.
$return = 'http://www.zwermp.com/cgi-bin/fantasy/php/getTeam.php';
$bid_errors = "./error_logs/bid_errors.txt";
$errors = "./error_logs/team_errors.txt";
$errorflag = 0;


#open (FILE, ">$errors");
# flock(FILE,2);
# print FILE "\n";
#close(FILE);

## Input stuff
$user = $_POST['TEAMS'];
$passwd = $_POST['TEAM_PASSWORD'];
$expire = time() + 60*60*24*7;
$id = '';

## Make sure that the owner has selected a team name
if (strcmp($user,"Select Your Team") == 0)
{
  #open (FILE,">>$errors");
  #flock(FILE,2);
  #print FILE "<b>Please Select a Team Name!</b>\n";
  #close(FILE);
  #$errorflag = 1;
}

## CHECK PASSWORD ## 
else #if($errorflag != 1)
{
 if(strcmp($passwd,'') == 0) # if ($passwd =~ /^$/)
 {
    #open (FILE, ">>$errors");
    #flock(FILE,2);
    #print FILE "<b>The password field must be filled out to properly submit this form!</b>\n";
    #close(FILE);
    #$errorflag = 1;
 }
 else
 {
   $dbh = mysql_connect ("localhost","doncote_draft","draft")
                  or die ('I cannot connect to the database because: ' . mysql_error());
   mysql_select_db ("doncote_draft");
   ## Connect to password database
   $table = "passwd";
   $sth = mysql_query("SELECT passwd FROM $table WHERE name = '$user'");
   $row = mysql_fetch_array($sth);

   if(strcmp($row['passwd'],$passwd) != 0)
   {
     #$errorflag=1;
     #open (FILE,">>$errors");
     #flock(FILE,2);
     #print FILE "<b>Your Password is Incorrect!</b>\n";
     #close(FILE);
   }
   else
   {
     $userAddr = $ENV{REMOTE_ADDR};

     while(!$id)
     {
       $id = rand();
       $sth = mysql_query("SELECT owner, IP FROM sessions WHERE sess_id = '$id'");
       $row = mysql_fetch_array($sth);
       if($row['owner']) {
           $id = '';
       }
     }
     $ip = $_SERVER['REMOTE_ADDR'];
     $sth = mysql_query("INSERT INTO sessions (IP,password,owner,sess_id) VALUES ('$ip','$passwd','$user','$id')");

     setcookie("SESS_ID", $id, $expire);

     $return = 'http://www.zwermp.com/cgi-bin/fantasy/php/fantasy_main_index.htm';
   }
   mysql_close($dbh);
 }
}

header("Location: $return");
?>