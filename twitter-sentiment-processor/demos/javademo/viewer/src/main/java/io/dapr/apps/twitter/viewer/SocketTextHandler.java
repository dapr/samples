/*
 * Copyright (c) Microsoft Corporation.
 * Licensed under the MIT License.
 */

package io.dapr.apps.twitter.viewer;

import java.io.IOException;

import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

public class SocketTextHandler extends TextWebSocketHandler {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(SocketTextHandler.class);

    @Override
	public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        WebSocketPubSub.INSTANCE.registerSession(session);
    }

	@Override
	public void handleTextMessage(WebSocketSession session, TextMessage message) throws IOException {
        log.info("Sending message: " + message.getPayload());
		session.sendMessage(message);
    }

    @Override
	public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        WebSocketPubSub.INSTANCE.unregisterSession(session);
    }

}
