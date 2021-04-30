package io.dapr.apps.twitter.viewer.twitterviewer;

import java.util.Optional;
import java.io.IOException;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@RestController
@SpringBootApplication
public class TwitterViewerApplication {
   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

   public static void main(String[] args) {
      SpringApplication.run(TwitterViewerApplication.class, args);
   }

   @ResponseBody
   @ResponseStatus(HttpStatus.OK)
   @PostMapping(value = "/tweets")
   public void tweet(@RequestBody byte[] payload) throws IOException {
      var node = OBJECT_MAPPER.readValue(payload, JsonNode.class);
      var data = Optional.ofNullable(node).map(n -> n.get("data")).map(n -> n.toString()).orElse("unknown");
      System.out.println("Received cloud event: " + data);
      WebSocketPubSub.INSTANCE.send(data);
   }
}
