import os
import json
import logging

from dapr.clients import DaprClient
from dapr.ext.grpc import App, BindingRequest


APP_PORT = os.getenv("APP_PORT", "3001")
PUBSUB_NAME = os.getenv("PUBSUB_NAME", "processed")
TOPIC_NAME = os.getenv("TOPIC_NAME", "processed-tweets")
STORE_NAME = os.getenv("STORE_NAME", "tweet-store")


app = App()

@app.binding('tweets')
def binding(request: BindingRequest):
    payload = request.text()
    m = extract_tweets(json.loads(payload))

    logging.info(m)

    with DaprClient() as d:
        tweet_data = json.dumps(m)
        d.save_state(STORE_NAME, m['id'], tweet_data)

        resp = d.invoke_method(
                'tweet-processor',
                'sentiment-score',
                data=tweet_data)

        m['sentiment'] = json.loads(resp.data)

        d.publish_event(PUBSUB_NAME, TOPIC_NAME, json.dumps(m))


def extract_tweets(payload):
    content = payload['text']
    ext_text = payload.get('extended_tweet')
    if ext_text:
        content = ext_text['full_text']
    user_info = payload['user']

    return {
        'id': payload['id_str'],
        'author': user_info['screen_name'] or user_info['name'],
        'author_pic': user_info['profile_image_url_https'],
        'content': content,
        'lang': payload['lang'],
        'published': payload['created_at'],
    }


def main():
    app.run(APP_PORT)


if __name__ == "__main__":
    logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)

    main()
