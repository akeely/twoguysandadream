#!/usr/bin/perl

print "Cache-Control: no-cache\n";
print "Content-type: text/html\n\n";

print <<EOM;

<HTML>
   <HEAD>
      <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
      <META HTTP-EQUIV="Expires" CONTENT="-1">
      <TITLE>Player Addition Page</TITLE>

<script language="JavaScript">
<!--
function add_checker(list_size)
{
  var radio_choice = false;
  // Loop from zero to the one minus the number of radio button selections
  for (counter = 0; counter < self.user_section.document.add_form.player_name.length; counter++)
  {
    // If a radio button has been selected it will return true
    // (If not it will return false)
    if (self.user_section.document.add_form.player_name[counter].checked)
      radio_choice = true; 
  }

  if (!radio_choice)
  {
    // If there were no selections made display an alert box 
    alert("Please select a player to be added")
    return (false);
  }

  return (true);
}
-->
</script>


<script language="JavaScript">
<!--
function check_commish(num_adds)
{
  // if the commissioner add option is checked, make sure the add button is enabled
  if (self.user_section.document.add_form.commish_flag.checked == true)
    self.user_section.document.add_form.player_add.disabled = false;

  // else if the commissioner add option is not checked, if the commish has no legal
  //  adds to make then disable the add button
  else if (num_adds == 0)
    self.user_section.document.add_form.player_add.disabled = true;
  
  return (true);
}

-->
</script>

   </HEAD>
   <frameset rows="45%,*">
      <FRAME NAME="main_window" SRC="/cgi-bin/fantasy/getPlayer.pl">
      <frame name="user_section" src="/cgi-bin/fantasy/listAdditions.pl">
   </frameset>
</HTML>

EOM
