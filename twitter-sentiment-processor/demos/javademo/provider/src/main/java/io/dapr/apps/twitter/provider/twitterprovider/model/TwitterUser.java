package io.dapr.apps.twitter.provider.twitterprovider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TwitterUser {
   @JsonProperty("name")
   String name;

   @JsonProperty("screen_name")
   String screenName;

   @JsonProperty("profile_image_url_https")
   String picture;
}