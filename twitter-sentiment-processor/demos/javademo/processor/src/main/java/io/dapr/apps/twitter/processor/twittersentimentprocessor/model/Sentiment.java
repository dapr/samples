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
public class Sentiment {
   @JsonProperty("sentiment")
   String sentiment;

   @JsonProperty("confidence")
   float confidence;
}