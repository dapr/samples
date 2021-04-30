package io.dapr.apps.twitter.viewer.twitterviewer;

import java.util.Map;
import java.util.HashMap;
import java.io.IOException;
import java.util.Collections;

import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

public class WebSocketPubSub {
   private final Map<String, WebSocketSession> sessions = Collections.synchronizedMap(new HashMap<>());

   public static final WebSocketPubSub INSTANCE = new WebSocketPubSub();

   private WebSocketPubSub() {
   }

   public void registerSession(WebSocketSession session) {
      System.out.println("Registering new websocket session: " + session.getId());
      sessions.put(session.getId(), session);
   }

   public void unregisterSession(WebSocketSession session) {
      System.out.println("un-registering new websocket session: " + session.getId());
      sessions.remove(session.getId());
   }

   public void send(String content) {
      sessions.values().forEach(socket -> {
         try {
            socket.sendMessage(new TextMessage(content));
         } catch (IOException e) {
            System.out.printf("Could not send message to websocket.", e);
         }
      });
   }
}
