package io.dapr.apps.twitter.processor.twittersentimentprocessor.model;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.Data;
import lombok.Builder;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Text {
   @JsonProperty("id")
   String id;

   @JsonProperty("text")
   String text;

   @JsonProperty("language")
   String language;
}