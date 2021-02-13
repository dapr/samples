window.onload = function () {

    console.log("Protocol: " + location.protocol);
    var wsURL = location.protocol + "//" + document.location.host

    var log = document.getElementById("tweets");

    function appendLog(item) {
        var doScroll = log.scrollTop > log.scrollHeight - log.clientHeight - 1;
        log.appendChild(item);
        if (doScroll) {
            log.scrollTop = log.scrollHeight - log.clientHeight;
        }
    }

    if (log) {
        var sock = io.connect(wsURL);
        var connDiv = document.getElementById("connection-status");
        connDiv.innerText = "closed";

        sock.on('connect', function () {
            console.log("connected to " + wsURL);
            connDiv.innerText = "open";
        });

        sock.on('disconnect', function (e) {
            console.log("connection closed (" + e.code + ")");
            connDiv.innerText = "closed";
        });

        sock.on('message', function (t) {
            var scoreStr = "neutral";
            var scoreAlt = "neutral: 0"

            if (t.hasOwnProperty("sentiment")) { 
                console.log(t.sentiment);
                if (t.sentiment.sentiment.length > 0) {
                    scoreStr = t.sentiment.sentiment;
                    scoreAlt = scoreStr + ": " + t.sentiment.confidence;
                }
            }

            var item = document.createElement("div");
            item.className = "item";
            // TODO: template this
            var tmsg = "<img src='" + t.author_pic + "' class='profile-pic' />" +
                "<div class='item-text'><b><img src='static/img/" + scoreStr +
                ".svg' title='" + scoreAlt + "' class='sentiment' />" + t.author +
                "<a href='https://twitter.com/" + t.author + "/status/" + t.id +
                "' target='_blank'><img src='static/img/tw.svg' class='tweet-link' /></a></b>" +
                "<br /><i>" + t.content + "</i></div>";
            item.innerHTML = tmsg
            appendLog(item);
        });

    } // if log
};