/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */
package io.dapr.apps.twitter.provider.model;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@FieldDefaults(level = AccessLevel.PRIVATE)
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyzedTweet {

    @JsonProperty("id")
    String id;

    @JsonProperty("tweet")
    Tweet tweet;

    @JsonProperty("sentiment")
    Sentiment sentiment;
}