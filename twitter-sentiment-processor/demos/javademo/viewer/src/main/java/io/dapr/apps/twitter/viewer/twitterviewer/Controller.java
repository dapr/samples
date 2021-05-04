package io.dapr.apps.twitter.viewer.twitterviewer;

import java.io.IOException;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Controller {
   private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

   @ResponseBody
   @ResponseStatus(HttpStatus.OK)
   @PostMapping(value = "/tweets")
   public void tweet(@RequestBody byte[] payload) throws IOException {
      var node = OBJECT_MAPPER.readValue(payload, JsonNode.class);
      var data = node.get("data").toString();
      System.out.println("Received cloud event: " + data);
      WebSocketPubSub.INSTANCE.send(data);
   }
}
