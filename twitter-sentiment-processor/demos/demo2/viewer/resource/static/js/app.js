window.onload = function () {

    console.log("Protocol: " + location.protocol);
    var wsURL = "ws://" + document.location.host + "/ws"
    if (location.protocol == 'https:') {
        wsURL = "wss://" + document.location.host + "/ws"
    }
    console.log("WS URL: " + wsURL);

    var log = document.getElementById("tweets");

    function appendLog(item) {
        var doScroll = log.scrollTop > log.scrollHeight - log.clientHeight - 1;
        log.appendChild(item);
        if (doScroll) {
            log.scrollTop = log.scrollHeight - log.clientHeight;
        }

    }

    if (log) {

        sock = new WebSocket(wsURL);

        var connDiv = document.getElementById("connection-status");
        connDiv.innerText = "closed";

        sock.onopen = function () {
            console.log("connected to " + wsURL);
            connDiv.innerText = "open";
        };

        sock.onclose = function (e) {
            console.log("connection closed (" + e.code + ")");
            connDiv.innerText = "closed";
        };

        sock.onmessage = function (e) {
            console.log(e);
            var t = JSON.parse(e.data);
            console.log(t);

            var scoreStr = ""
            var score = parseFloat(t.sentiment)
            if (score <= parseFloat(0.3)) {
                scoreStr = "negative"
            } else if (score >= parseFloat(0.6)) {
                scoreStr = "positive"
            }else {
                scoreStr = "neutral"
            }
            

            var item = document.createElement("div");
            item.className = "item";
            // TODO: template this
            var tmsg = "<img src='" + t.author_pic + "' class='profile-pic' />" +
                "<div class='item-text'><b><img src='static/img/" + scoreStr +
                ".svg' alt='sentiment' class='sentiment' />" + t.author +
                "<a href='https://twitter.com/" + t.author + "/status/" + t.id +
                "' target='_blank'><img src='static/img/tw.svg' class='tweet-link' /></a></b>" +
                "<br /><i>" + t.content + "</i><br /><i class='small'>Query: " +
                t.query + "</i></div>";
            item.innerHTML = tmsg
            appendLog(item);
        };

    } // if log


};