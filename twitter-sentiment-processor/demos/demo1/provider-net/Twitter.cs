using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Provider
{
        // SearchResult is the metadata from executed search
    public class TwitterTweet  {
        // ID is tweet's id_str
        [JsonPropertyName("id_str")]
        public string ID {get; set; }
        // Author is tweet's user
        [JsonPropertyName("user")]
        public TwitterUser Author {get; set; }
        
        // Text is tweet's full_text 
        [JsonPropertyName("full_text")]
        public string FullText {get; set; }
        // Text is tweet's text (used only if full_text not set)
        [JsonPropertyName("text")]
        public string Text {get; set; }

        //Published is tweet's created_at time
        // [JsonPropertyName("created_at")]
        // public DateTimeOffset Published {get; set; }
    }

    public class TwitterUser  {
        // Name is tweet author's name 
        [JsonPropertyName("name")]
        public string Name {get; set; }
        
        // Pic is tweet author's profile pic URL
        [JsonPropertyName("profile_image_url_https")]
        public string Pic {get; set; }
    }


    //SimpleTweet represents the Twiter query result item
    public class SimpleTweet  {
        // ID is the string representation of the tweet ID
        [JsonPropertyName("id")]
        public string ID {get; set; }
        // Query is the text of the original query
        [JsonPropertyName("query")]
        public string Query {get; set; }
        // Author is the name of the tweet user
        [JsonPropertyName("author")]
        public string Author {get; set; }
        // AuthorPic is the url to author profile pic
        [JsonPropertyName("author_pic")]
        public string AuthorPic {get; set; }
        // Content is the full text body of the tweet
        [JsonPropertyName("content")]
        public string Content {get; set; }
        // Published is the parsed tweet create timestamp	
        [JsonPropertyName("published")]
        public DateTime Published {get; set; }
        //Score is Content's sentiment score
        [JsonPropertyName("sentiment")]
        public float Score {get; set; }
    }
}