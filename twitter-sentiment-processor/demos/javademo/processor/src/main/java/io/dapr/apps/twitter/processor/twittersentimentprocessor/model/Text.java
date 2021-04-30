package io.dapr.apps.twitter.processor.twittersentimentprocessor.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Text {
   public Text() {
   }

   public Text(String text, String language) {
      this.text = text;
      this.language = language;
   }

   @JsonProperty("id")
   String id;

   public void setId(String id) {
      this.id = id;
   }

   @JsonProperty("text")
   String text;

   @JsonProperty("language")
   String language;
}