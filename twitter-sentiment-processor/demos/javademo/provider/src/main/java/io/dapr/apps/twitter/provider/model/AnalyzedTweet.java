/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */
package io.dapr.apps.twitter.provider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class AnalyzedTweet {

    public AnalyzedTweet() {
    }

    public AnalyzedTweet(Tweet tweet, Sentiment sentiment) {
        setId(tweet.getId());
        setSentiment(sentiment);
        setTweet(tweet);
    }

    @JsonProperty("id")
    private String id;

    @JsonProperty("tweet")
    private Tweet tweet;

    @JsonProperty("sentiment")
    private Sentiment sentiment;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Tweet getTweet() {
        return tweet;
    }

    public void setTweet(Tweet tweet) {
        this.tweet = tweet;
    }

    public Sentiment getSentiment() {
        return sentiment;
    }

    public void setSentiment(Sentiment sentiment) {
        this.sentiment = sentiment;
    }

    @Override
    public String toString() {
        return "AnalyzedTweet [id=" + id + ", sentiment=" + sentiment + ", tweet=" + tweet + "]";
    }

}
