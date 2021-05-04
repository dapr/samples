package io.dapr.apps.twitter.processor.twitterprocessor.model;

// This class makes building the JSON payload for sending to cognitive services
// easier. The JSON is an array of documents. In our case we only ever have one
// document in each call
public class Payload {
   public Text[] documents = new Text[1];
}
