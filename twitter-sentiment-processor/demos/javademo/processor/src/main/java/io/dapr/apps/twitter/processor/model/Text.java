/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */
package io.dapr.apps.twitter.processor.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Text {

    @JsonProperty("text")
    private String text;

    @JsonProperty("lang")
    private String language;

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
        return "Text [language=" + language + ", text=" + text + "]";
    }


}
