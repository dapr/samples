package io.dapr.apps.twitter.provider.twitterprovider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Tweet {
   @JsonProperty("id_str")
   String id;

   public String getId() {
      return this.id;
   }

   @JsonProperty("user")
   TwitterUser author;

   @JsonProperty("full_text")
   String fullText;

   @JsonProperty("text")
   String text;

   public String getText() {
      return this.text;
   }

   @JsonProperty("lang")
   String language;

   public String getLanguage() {
      return this.language;
   }
}