package io.dapr.apps.twitter.processor.twitterprocessor.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Secrets {
   @JsonProperty("token")
   String token;

   public String getToken() {
      return this.token;
   }

   @JsonProperty("endpoint")
   String endpoint;

   public String getEndpoint() {
      return this.endpoint;
   }
}
