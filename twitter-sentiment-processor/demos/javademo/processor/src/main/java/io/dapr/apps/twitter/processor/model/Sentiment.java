/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */
package io.dapr.apps.twitter.processor.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Sentiment {

    @JsonProperty("sentiment")
    private String sentiment;

    @JsonProperty("confidence")
    private float confidence;

    public Sentiment() {
    }

    public Sentiment(String sentiment, float confidence) {
        this.sentiment = sentiment;
        this.confidence = confidence;
    }

    public String getSentiment() {
        return sentiment;
    }

    public void setSentiment(String sentiment) {
        this.sentiment = sentiment;
    }

    public float getConfidence() {
        return confidence;
    }

    public void setConfidence(float confidence) {
        this.confidence = confidence;
    }

    @Override
    public String toString() {
        return "Sentiment [confidence=" + confidence + ", sentiment=" + sentiment + "]";
    }

}
