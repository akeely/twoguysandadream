function addPlayer(playerId) {

    var token = $("meta[name='_csrf']").attr("content");
    var header = $("meta[name='_csrf_header']").attr("content");

    var leagueId = $("meta[name='_league_id'").attr("content");

    $.ajax({
            'url': '/api/league/' + leagueId + '/bid',
            'data': JSON.stringify({ playerId: playerId }),
            'type': 'POST',
            'processData': false,
            'contentType': 'application/json',
            'headers': {
                [header]: token
            }
        })
        .done(function() {
            window.location.reload(true);
        })
        .fail(function() {
            alert('Player addition failed!');
        });
}
