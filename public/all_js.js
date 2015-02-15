function sendBids(ev) 
{
  ev.preventDefault();

  $.ajax({
           type: "POST",
           url: "/cgi-bin/fantasy/putBids.pl",
           dataType: "json",
           data: $("#bid_form").serialize(), // serializes the form's elements.
           success: function(response)
           {
             $("#PLAYER_TABLE_1").find("[id*= 7]").removeClass('errorBorder');

             $("#global_errors").empty();
             $("#global_errors").hide();
             $("#global_errors").append('<ul>');
             $("#global_errors").append('<li><b>********************************</b></li>');
             $("#global_errors").append('<li><b>ERRORS</b></li>');
             if (response.global_error !== undefined) {
               $("#global_errors").append('<li>' + response.global_error + '<\li>');
               $("#global_errors").show();
             }
             if (response.player_errors !== undefined) {
               $.each(response.player_errors, function(playerid, error) {
                   $("#global_errors").append('<li>' + error + '<\li>');
                   $("#global_errors").show();
                   $("#PLAYER_ROW_" + playerid).find("[id*= 7]").addClass('errorBorder');
               });
             }
             $("#global_errors").append('<li><b>********************************</b></li>');
             $("#global_errors").append('</ul>');

             if (response.player_success !== undefined) {
               $.each(response.player_success, function(playerid, junk) {
                   $("#PLAYER_ROW_" + playerid).find("[id*= 7]").removeClass('errorBorder');
                   $("#PLAYER_ROW_" + playerid).find("[id*=NEW_BID_]").val(0);
               });

               // kick off a table update - may be necessary depending on our checkBids call rate
               table_loop($('#OWNER').val());
             }
           },
           error: function(a,b,c) {
             alert("Well shit");
           }
  });
}


function createRequestObject() {

    var ro;
    try
    {
        // Firefox, Opera 8.0+, Safari
        ro = new XMLHttpRequest();
    }
    catch (e)
    {
       // Internet Explorer
       try
       {
          ro = new ActiveXObject("Msxml2.XMLHTTP");
       }
       catch (e)
       {
          try
          {
             ro = new ActiveXObject("Microsoft.XMLHTTP");
          }
          catch (e)
          {
             alert("ERROR: Your browser does not support AJAX!");
             return false;
          }
       }
    }
    return ro;
}



function pswd_checker(hinge)
{
  if (hinge == 0)
  {
    if (document.bid_form.TEAM_PASSWORD.value == '')
    {
      alert("Please enter a password")
      return (false);
    }

    if (document.bid_form.TEAMS.value == 'Select A Team')
    {
      alert("Please select a Team")
      return (false)
    }
  }

  // Check to make sure at least one new bid was made
  //  and that bid entries are numbers
  var my_table = document.getElementById('PLAYER_TABLE_1')
  var bid_made = false
  var bids_ok = true;
  var check = '0123456789.'
  for (var counter = 1; counter < my_table.rows.length; counter++)
  {
    var counter2 = counter - 1

    var text = "document.getElementById('NEW_BID_" + counter2 + "').value"
    var text2 = my_table.rows[counter].cells[0].firstChild.nodeValue
    var player_element = eval(text)
    for (var i = 0; i < player_element.length; i++)
    {
      var chr = player_element.charAt(i);

      for (var j = 0; j < check.length; j++) 
      {
        if (chr == check.charAt(j))
        {
          break
        }

        // Should only reach here is a non-numeric entry is used
        if (j == (check.length - 1))
        {
          bids_ok = false
        }
      }

       if (bids_ok == false) break;
    }

    if ((player_element != 0) && (player_element != ''))
    {
      bid_made = true
    }
  }

  if (bid_made == false)
  {
    alert("You must make at least one new bid to submit this form!")
    return(false)
  }

  if (bids_ok == false)
  {
    alert("Your bids must only contain numbers!")
    return(false)
  }

  return(true)
}

function confirmRfaDraft(league_name, action)
{
  var status = confirm(action + " the RFA draft for league '" + league_name + "'?")
  if (status != false)
  {
    http.open('GET',encodeURI('startRfaDraft.pl?league_name=' + league_name + ';' + action))
    http.send(null)
  }

  return false;
}

function table_loop(user)
{
  var player_ids = ""
  var my_table = document.getElementById('PLAYER_TABLE_1')

  var temp;
  var id_element;
  for (var i = 1; i < my_table.rows.length; i++)
  {
    temp = 'PLAYER_ID_'+(i-1);
    id_element=document.getElementById(temp);
    player_ids = player_ids + id_element.value + ";";
  }

  $.ajax({
           type: "GET",
           url: "/legacy/auction/league/" + document.getElementById('league').value,
           dataType: "json",
           async: true,
           timeout:1000,
           data: { user : user, league : document.getElementById('league').value, ids : player_ids },//+ "," + document.getElementById('league').value + "," + player_ids +","+ new Date().getTime(),
           success: function(response)
           {
             handleResponse(response);
           },
           error: function(a,b,c) {
             // likely a timeout. DO nothing for now
             //alert("Well shit. Error in processing auction data, please contact Erik or Andrew");
           }
  });
  
}

// Handle pause requests from the commish
function pause_utility(msg)
{
  if (msg == 'Pause Draft!')
  {
    http.open('GET','pause.pl?action=pause')
  }
  else
  {
    http.open('GET','pause.pl?action=unpause')
  }
  http.onreadystatechange = update_pause_button
  http.send(null)
}

function update_pause_button()
{
  if(http.readyState == 4)
  {
    var pause_val = document.getElementById('pause_button').value
    if (pause_val == 'Pause Draft')
    {
      pause_val = 'Continue Draft'
    }
    else
    {
      pause_val = 'Pause Draft'
    }
  }
}

// Handle the response from the perl code
//  Writes new bids/bidders to the table
function handleResponse(response) 
{
        var my_table = document.getElementById('PLAYER_TABLE_1');

        var count = 0
        for (var i = 1; i < my_table.rows.length; i++)
        { 
          // gross!
          var player_name = my_table.rows[i].cells[0].firstChild.nodeValue
          var player_id = my_table.rows[i].cells[7].children[1].value

          // Look for this player in the PLAYERS object
          if ((response.PLAYERS) && (response.PLAYERS[player_id]))
          {
              var update_player = response.PLAYERS[player_id]
              update_player.FOUND = 1;

              //If player has been won already, make his row red
              if (update_player.TIME === "NA")
              {
                my_table.rows[i].style.backgroundColor = "red"
                my_table.rows[i].cells[5].style.backgroundColor = "red"
                if ((update_player.BID !== '') && (update_player.BIDDER !== ''))
                {
                  my_table.rows[i].cells[2].firstChild.nodeValue = update_player.TEAM
                  my_table.rows[i].cells[3].firstChild.nodeValue = update_player.BID
                  my_table.rows[i].cells[4].firstChild.nodeValue = update_player.BIDDER

                  if (update_player.BIDDER === document.getElementById('TEAMS').value)
                  {
                    my_table.rows[i].cells[4].innerHTML = '<font color="#FFFFFF"><b>' + update_player.BIDDER + '</b></font>'
                  }
                }
                else
                {
                  my_table.rows[i].cells[4].style.display='none'
                  my_table.rows[i].cells[3].colSpan ="2"
                  my_table.rows[i].cells[3].vAlign="middle"
                  my_table.rows[i].cells[3].innerHTML = '<b>NOT CLAIMED</b>'
                }
                my_table.rows[i].cells[5].innerHTML = '<a href="javascript:removePlayer('+ i + ')"><font color="#FFFFFF"><b> Remove This Player<b></font></a>'
                my_table.rows[i].cells[5].colSpan ="3"
                my_table.rows[i].cells[5].vAlign="middle"
                my_table.rows[i].cells[6].style.display='none'
                my_table.rows[i].cells[7].style.display='none'
              }
  
              // If still active, update the countdown
              else
              {
                if (update_player.TIME === 'PAUSED')
                {
                  my_table.rows[i].cells[5].firstChild.nodeValue = update_player.TIME
                }
                else if (update_player.TIME == 'WAIT')
                {
                  my_table.rows[i].cells[5].innerHTML = 'WAIT FOR RFA'
                  my_table.rows[i].cells[5].colSpan ="3"
                  my_table.rows[i].cells[5].vAlign="middle"
                  my_table.rows[i].cells[6].style.display='none'
                  my_table.rows[i].cells[7].style.display='none'
                }
                else
                {
                  var total_secs_left = (update_player.TIME - response.TIME.CURRENT_SECONDS)

                  var hours_left = Math.floor(total_secs_left / 3600);
                  var mins_left  = Math.floor((total_secs_left - (hours_left * 3600)) / 60);
                  var secs_left  = (total_secs_left - (hours_left * 3600) - (mins_left * 60))
    
                  if (hours_left < 10)
                  {
                    hours_left = '0' + hours_left
                  }
                  if (mins_left < 10)
                  {
                    mins_left = '0' + mins_left
                  }
                  if (secs_left < 10)
                  {
                    secs_left = '0' + secs_left
                  }

                  my_table.rows[i].cells[5].firstChild.nodeValue = hours_left + ":" + mins_left + ":" + secs_left
                }
              
                
                //If the bid has changed since last update
                if (update_player.BID != my_table.rows[i].cells[3].firstChild.nodeValue)
                {
                  my_table.rows[i].style.backgroundColor = "yellow"
                  my_table.rows[i].cells[3].firstChild.nodeValue = update_player.BID
                  my_table.rows[i].cells[4].innerHTML = update_player.BIDDER
                }
                //If the leading bidder is this owner
                else if (update_player.BIDDER == document.getElementById('TEAMS').value)
                {
                  my_table.rows[i].style.backgroundColor = "98FB98"
                }
                else 
                {
                  my_table.rows[i].style.backgroundColor = "#EEEEEE"
                }

                //If there is less than 30 seconds remaining on this player
                if (total_secs_left < 30)
                {
                  my_table.rows[i].cells[5].style.backgroundColor = "#FFA500"
                }
                else
                {
                  my_table.rows[i].cells[5].style.backgroundColor = my_table.rows[i].style.backgroundColor
                }
              }
          }
          count++
        } // end for loop

        // add new rows, when needed
        if (response.PLAYERS) {
          $.each(response.PLAYERS, function(id, player) {
            if (!player.FOUND)
            {
              if ((player.TIME === 'PAUSED') || (player.TIME === 'WAIT'))
              {
                addRowToTable(player.NAME,id,player.POS,player.TEAM,player.BID,player.BIDDER,player.TIME,player.TARGET)
              }
              else
              {
                var secs_left = (player.TIME - response.TIME.CURRENT_SECONDS)
                var hours_left = Math.floor(secs_left / 3600);
                var mins_left  = Math.floor((secs_left - (hours_left * 3600)) / 60);
                secs_left  = (secs_left - (hours_left * 3600) - (mins_left * 60))

                if (hours_left < 10)
                {
                  hours_left = '0' + hours_left
                }
                if (mins_left < 10)
                {
                  mins_left = '0' + mins_left
                }
                if (secs_left < 10)
                {
                  secs_left = '0' + secs_left
                }
                addRowToTable(player.NAME,id,player.POS,player.TEAM,player.BID,player.BIDDER,hours_left + ":" + mins_left + ":" + secs_left,player.TARGET)
              }
            }
          });
        }

        var my_stat_table = document.getElementById('stat_table');

        //update total players input
        document.getElementById('total_players').value = $('#PLAYER_TABLE_1').find('tr').length - 1;

        // update clock
        var current_time_string = response.TIME.MONTH + '/' + response.TIME.DAY + ' - ' + response.TIME.HOUR + ':' + response.TIME.MINUTE + ':' + response.TIME.SECOND;
        my_stat_table.rows[0].cells[0].innerHTML = "<b>Current Time</b><br>"+current_time_string;

        // update stats on side
        if (response.hasOwnProperty('TEAMS'))
        {
          var row = 3;
          $.each(response.TEAMS, function(name, data) {
            my_stat_table.rows[row].cells[0].innerHTML = "<a href=javascript:refresh_roster_window('"+encodeURI(name)+"')>"+name+"</a>";
            my_stat_table.rows[row].cells[1].innerHTML = data.MONEY;
            my_stat_table.rows[row].cells[2].innerHTML = data.MAX_BID;
            my_stat_table.rows[row].cells[3].innerHTML = data.SPOTS;
            my_stat_table.rows[row].cells[4].innerHTML = data.ADDS;
            row++;
          });
        }

        // Persist roster data to pagedata
        if (response.hasOwnProperty('ROSTERS'))
        {
          $.each(response.ROSTERS, function(team, roster) {
            rosters[team] = roster;
          });
        }

        // Load roster for current user
        refresh_roster_window(encodeURI(current_display_team));


        // update rfa table if it exists & data provided
        try
        {
          if (response.RFA)
          {
            $('#rfa_table').find("tr:gt(1)").remove();
            $.each(response.RFA, function(name, data) {
              $('#rfa_table tr:last').after('<tr><td>' + name + '</td><td>' + data.TEAM + '</td><td>' + data.OVERRIDE + '</td><td>' + data.PRICE + '</td></tr>');
            });
          }
        }
        catch (e)
        {
          alert("SHOULDN'T BE GETTING RFA DATA IF TABLE DOESNT EXIST ?" + e)
        }


        // Check for RFA players with 'WAIT' status here - if this team if the previous owner, prompt them for override
        if (response.PLAYERS) {
          $.each(response.PLAYERS, function(id, player) {
            if ((player.TIME === 'WAIT') && (player.RFA_PREV_OWNER === document.getElementById('OWNER').value))
            {
              var override = confirm("Your former contract player '" + player.NAME + "' has been won for a price of $" + player.BID + ".\n\nWould you like retain this player at that price?")
            
              // Send the true/false override value to the server so that we can update the auction_table
              http.open('GET',encodeURI('updateRfaPlayer.pl?data=' + id + ';' + document.getElementById('league').value + ';' + player.RFA_PREV_OWNER + ';' + override))
              http.send(null)
            }
          });
        }
}


function addRowToTable(name,id,position,team,bid,bidder,time,target)
{
  var my_table = document.getElementById('PLAYER_TABLE_1');
  var lastRow = my_table.rows.length;
  // if there's no header row in the table, then iteration = lastRow + 1
  var row = my_table.insertRow(lastRow);
  var cell1 = row.insertCell(0);
  var textNode1 = document.createTextNode(name);
  cell1.appendChild(textNode1);
  var cell2 = row.insertCell(1);
  var textNode2 = document.createTextNode(position);
  cell2.appendChild(textNode2);
  var cell3 = row.insertCell(2);
  var textNode3 = document.createTextNode(team);
  cell3.appendChild(textNode3);
  var cell4 = row.insertCell(3);
  var textNode4 = document.createTextNode(bid);
  cell4.appendChild(textNode4);
  var cell5 = row.insertCell(4);
  cell5.innerHTML = bidder;  // innerHTML to accomodate <b> tags when unclaimed
  var cell6 = row.insertCell(5);
  var textNode6 = document.createTextNode(time);
  cell6.appendChild(textNode6);

  // new cell 7 - target price
  var cell7 = row.insertCell(6);
  var textNode7 = document.createTextNode(target);
  cell7.appendChild(textNode7);

  var cell8 = row.insertCell(7);
  var el  = document.createElement('input')
  var el2 = document.createElement('input')
  el.type = 'text'
  el.name = 'NEW_BID_' + (lastRow - 1)
  el.id = 'NEW_BID_' + (lastRow - 1)
  el.size = 4
  el.value = '0'
  el2.type = 'hidden'
  el2.name = 'PLAYER_ID_' + (lastRow - 1)
  el2.id = 'PLAYER_ID_' + (lastRow - 1)
  el2.value = id 
  cell8.appendChild(el);
  cell8.appendChild(el2);

  cell1.id= (lastRow-1) + ' 0'
  cell1.rowspan=1
  cell1.style.verticalAlign="middle"
  cell2.id= (lastRow-1) + ' 1'
  cell2.rowspan=1
  cell2.style.verticalAlign="middle"
  cell3.id= (lastRow-1) + ' 2'
  cell3.rowspan=1
  cell3.style.verticalAlign="middle"
  cell4.id= (lastRow-1) + ' 3'
  cell4.rowspan=1
  cell4.style.verticalAlign="middle"
  cell5.id= (lastRow-1) + ' 4'
  cell5.rowspan=1
  cell5.style.verticalAlign="middle"
  cell6.id= (lastRow-1) + ' 5'
  cell6.rowspan=1
  cell6.style.verticalAlign="middle"
  cell7.id= (lastRow-1) + ' 6'
  cell7.rowspan=1
  cell7.style.verticalAlign="middle"
  cell8.id= (lastRow-1) + ' 7'
  cell8.rowspan=1
  cell8.style.verticalAlign="middle"

  row.bgColor = "#FFFF00";
  row.id = 'PLAYER_ROW_' + id;

  $("#NEW_BID_" + lastRow-1).focus(function() {
    if ($("#NEW_BID_" + lastRow-1).val() === '0') {
      $("#NEW_BID_" + lastRow-1).val('');
    }
  });
  $("#NEW_BID_" + lastRow-1).blur(function() {
    if ($("#NEW_BID_" + lastRow-1).val() === '') {
      $("#NEW_BID_" + lastRow-1).val(0);
    }
  });

}

function refresh_roster_window(team)
{
  team = decodeURI(team);
  var roster_table = document.getElementById('teamRoster_table')
  var roster_header = document.getElementById('roster_team_header')
  var current_roster_size = (roster_table.rows.length - 2)
  var roster = rosters[team]

  if (!roster) {
    roster = new Array();
  }

  roster_header.innerHTML = '<b>'+team+'</b>'
  $.each(roster, function(index, player) {
    if ($("#teamRoster_row_" + index).length) {
      $("#teamRoster_row_" + index).html('<td>' + player.NAME + '</td><td>' + player.PRICE + '</td><td>' + player.POS + '</td>');
    } else {
      $('#teamRoster_table tr:last').after('<tr id="teamRoster_row_' + index + '"><td>' + player.NAME + '</td><td>' + player.PRICE + '</td><td>' + player.POS + '</td></tr>');
    }
  });

  // if we have any extra rows, blank them out
  for (var j=(roster.length); j < (current_roster_size); j++)
  {
    roster_table.rows[j+2].cells[0].innerHTML = ''
    roster_table.rows[j+2].cells[1].innerHTML = ''
    roster_table.rows[j+2].cells[2].innerHTML = ''
  }

  //reset display team for refreshing
  current_display_team = team;
}


function removePlayer(row)
{
  var my_table = document.getElementById('PLAYER_TABLE_1');
  my_table.rows[row].style.display='none'
}
