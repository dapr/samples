/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */
package io.dapr.apps.twitter.processor;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URL;
import java.util.Optional;

import javax.net.ssl.HttpsURLConnection;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import io.dapr.apps.twitter.processor.model.Sentiment;
import io.dapr.apps.twitter.processor.model.Text;
import reactor.core.publisher.Mono;

@RestController
public class ApplicationController {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(ApplicationController.class);

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private static final JsonFactory JSON_FACTORY = new JsonFactory();

    private static final String PATH = "/text/analytics/v3.0/sentiment";

    public ApplicationController(String endpoint, String subscriptionKey) {
      this.endpoint = endpoint;
      this.subscriptionKey = subscriptionKey;
    }

    @Autowired
    @Qualifier("endpoint")
    private final String endpoint;

    @Qualifier("subscriptionKey")
    private final String subscriptionKey;

    @PostMapping(value = "/sentiment")
    @ResponseStatus(HttpStatus.OK)
    @ResponseBody
    public Sentiment tweet(@RequestBody Text text) throws IOException {
        log.info(String.format("Text received in %s: %s", text.getLanguage(), text.getText()));

        assert(endpoint != null);
        assert(subscriptionKey != null);

        var url = new URL(endpoint+PATH);
        var connection = (HttpsURLConnection) url.openConnection();
        connection.setRequestMethod("POST");
        connection.setRequestProperty("Content-Type", "text/json");
        connection.setRequestProperty("Ocp-Apim-Subscription-Key", subscriptionKey);
        connection.setDoOutput(true);

        writeRequest(text, connection.getOutputStream());

        var node = OBJECT_MAPPER.readTree(connection.getInputStream());
        var sentiment = Optional.ofNullable(node)
          .map(n -> n.get("documents"))
          .map(n -> n.get(0))
          .map(n -> n.get("sentiment"))
          .map(n -> n.asText())
          .orElse("unknown");
        float score = Optional.ofNullable(node)
          .map(n -> n.get("documents"))
          .map(n -> n.get(0))
          .map(n -> n.get("confidenceScores"))
          .map(n -> n.get(sentiment))
          .map(n -> n.floatValue())
          .orElse((float) 0);
          
        return new Sentiment(sentiment, score);
    }

    private static void writeRequest(Text text, OutputStream output) throws IOException {
        try (var bos = new BufferedOutputStream(output)) {
            try (var generator = JSON_FACTORY.createGenerator(bos)) {
                generator.writeStartObject();
                generator.writeArrayFieldStart("documents");
                generator.writeStartObject();
                generator.writeStringField("id", "1");
                generator.writeStringField("language", text.getLanguage());
                generator.writeStringField("text", text.getText());
                generator.writeEndObject();
                generator.writeEndArray();
                generator.writeEndObject();
                bos.flush();
            }
          }
    }

    @GetMapping(path = "/health")
    public Mono<Void> health() {
        return Mono.empty();
    }
}
