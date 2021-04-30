package io.dapr.apps.twitter.provider.twitterprovider.model;

import lombok.Data;
import lombok.Builder;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.experimental.FieldDefaults;

import com.fasterxml.jackson.annotation.JsonProperty;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class TwitterUser {
   @JsonProperty("name")
   String name;

   @JsonProperty("screen_name")
   String screenName;

   @JsonProperty("profile_image_url_https")
   String picture;
}