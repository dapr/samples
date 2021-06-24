/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */

package io.dapr.apps.twitter.viewer;

import java.io.IOException;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import io.dapr.Topic;
import io.dapr.client.domain.CloudEvent;
import reactor.core.publisher.Mono;

@RestController
public class ApplicationController {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(ApplicationController.class);

    private static final String PUBSUB = "messagebus";
  
    @Topic(name = "tweets", pubsubName = PUBSUB)
    @PostMapping(value = "/tweets")
    @ResponseStatus(HttpStatus.OK)
    @ResponseBody
    public void tweet(@RequestBody byte[] payload) throws IOException {
        var event = CloudEvent.deserialize(payload);
        log.info("Received cloud event: " + event.getData());
        WebSocketPubSub.INSTANCE.send(event.getData());
    }

    @GetMapping(path = "/health")
    public Mono<Void> health() {
        return Mono.empty();
    }
}
