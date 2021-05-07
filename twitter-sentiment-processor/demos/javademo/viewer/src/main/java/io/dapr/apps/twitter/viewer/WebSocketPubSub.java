/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */

package io.dapr.apps.twitter.viewer;

import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

public class WebSocketPubSub {

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(WebSocketPubSub.class);

	private final Map<String, WebSocketSession> sessions = Collections.synchronizedMap(new HashMap<>());

	public static final WebSocketPubSub INSTANCE = new WebSocketPubSub();

	private WebSocketPubSub() {}

	public void registerSession(WebSocketSession session) {
		log.info("Registering new websocketsession: " + session.getId());
		sessions.put(session.getId(), session);
	}

	public void unregisterSession(WebSocketSession session) {
		log.info("unregistering new websocketsession: " + session.getId());
		sessions.remove(session.getId());
	}

	public void send(String content) {
		sessions.values().forEach(socket -> {
			try {
				socket.sendMessage(new TextMessage(content));
			} catch (IOException e) {
				log.error("Could not send message to websocket.", e);
			}
		});
	}
}
