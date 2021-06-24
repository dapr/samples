/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */
package io.dapr.apps.twitter.provider.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Tweet {

    @JsonProperty("id_str")
    private String id;

    @JsonProperty("user")
    private TwitterUser author;

    @JsonProperty("full_text")
    private String fullText;

    @JsonProperty("text")
    private String text;

    @JsonProperty("lang")
    private String language;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public TwitterUser getAuthor() {
        return author;
    }

    public void setAuthor(TwitterUser author) {
        this.author = author;
    }

    public String getFullText() {
        return fullText;
    }

    public void setFullText(String fullText) {
        this.fullText = fullText;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    @Override
    public String toString() {
        return "Tweet [author=" + author + ", fullText=" + fullText + ", id=" + id + ", language=" + language
                + ", text=" + text + "]";
    }

}
