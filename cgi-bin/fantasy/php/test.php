<pre>
<?php
$dbh=mysql_connect ("localhost", "doncote_draft", "draft") or die ('I cannot connect to the database because: ' . mysql_error());
mysql_select_db ("doncote_draft");
$count = 0;
  $auctionfile = "auction_players";
  $sth = mysql_query("SELECT * FROM $auctionfile WHERE team = 'test2' AND league = 'test' ORDER BY price");
 
  while ($row = mysql_fetch_array($sth))
  {
     $name = $row['name'];
     $bid = $row['price'];
     $players2[] = array(name => $name, price => $bid );
    $count++;
  }   
#  mysql_close($dbh);
  echo "Players2:\n";
  print_r($players2);
  echo "End Players2\n";
  $total_spent2 = 0;
  ###########################
  # Print the current team
  ###########################
  if($players2){
  foreach($players2 as $member)
  {
    $name = $member['name'];
    $bid = $member['price'];
    echo "$name,$bid";
    $total_spent2 += $bid;
  }
  }

?>
</pre>