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

            
            var scoreStr = "neutral";
            var scoreAlt = "neutral: 0"
            if (t.hasOwnProperty("sentiment")) { 
                console.log(t.sentiment);
                if (t.sentiment.sentiment.length > 0) {
                    scoreStr = t.sentiment.sentiment;
                    scoreAlt = scoreStr + ": " + t.sentiment.confidence;
                }
            } 

            var tweetText = t.tweet.text;
            if(t.tweet.fullText != null) {
                tweetText = t.tweet.full_text;
            }

            var item = document.createElement("div");
            item.className = "item";
            var postURL = t.tweet.user.name;
            if (t.tweet.user.screen_name) {
                postURL = t.tweet.user.screen_name +
                "<a href='https://twitter.com/" + t.tweet.user.screen_name + "/status/" + t.tweet.id_str +
                "' target='_blank'><img src='img/tw.svg' class='tweet-link' /></a></b>";
            }
            var tmsg = "<img src='" + t.tweet.user.profile_image_url_https + "' class='profile-pic' />" +
               "<div class='item-text'><b><img src='img/" + scoreStr +
               ".svg' title='" + scoreAlt + "' class='sentiment' />" + postURL +
               "<br /><i>" + tweetText + "</i></div>";
            item.innerHTML = tmsg
            appendLog(item);
        };

    }

};