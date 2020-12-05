import os
import json
import logging

from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential
from dapr.clients import DaprClient
from dapr.ext.grpc import App, InvokeServiceRequest, InvokeServiceResponse

LANG_DEFAULT = 'en'
SECRET_STORE_NAME = 'pipeline-secrets'
SECRET_STORE_ENDPOINT = 'Azure:CognitiveAPIEndpoint'
SECRET_STORE_KEY = 'Azure:CognitiveAPIKey'

APP_PORT = os.getenv('APP_PORT', '3002')
COGNITIVE_SERVICE_API_KEY = os.getenv('COGNITIVE_API_KEY', '')
COGNITIVE_SERVICE_API_ENDPOINT = os.getenv('COGNITIVE_API_ENDPOINT', '')

analytics_endpoint = ''
analytics_key = ''


app = App()

@app.method(name='sentiment-score')
def sentiment(request: InvokeServiceRequest) -> InvokeServiceResponse:
    req = json.loads(request.data)
    logging.info(req)
    lang = req.get('lang') or LANG_DEFAULT
    analytics_client = get_analytics_client(analytics_endpoint, analytics_key)
    score = get_sentiment(analytics_client, lang, req['content'])

    logging.info(score)

    return InvokeServiceResponse(json.dumps(score), 'application/json')


def get_analytics_client(endpoint: str, key: str):
    ta_credential = AzureKeyCredential(key)
    return TextAnalyticsClient(endpoint, ta_credential)


def get_sentiment(client: TextAnalyticsClient, lang: str, text: str):
    sentiment = {
        'sentiment': 'unknown',
        'confidence': 0.0,
    }

    try:
        response = client.analyze_sentiment(documents=[text], language=lang)[0]
        sentiment = {
            'sentiment': response.sentiment,
            'confidence': response.confidence_scores.get(response.sentiment, 0.0),
        }
    except Exception as ex:
        pass

    return sentiment



def main():
    global analytics_key, analytics_endpoint

    if COGNITIVE_SERVICE_API_KEY == '':
        with DaprClient() as d:
            resp = d.get_secret(SECRET_STORE_NAME, SECRET_STORE_KEY)
            analytics_key = resp.secret[SECRET_STORE_KEY]
    else:
        analytics_key = COGNITIVE_SERVICE_API_KEY


    if COGNITIVE_SERVICE_API_ENDPOINT == '':
        with DaprClient() as d:
            resp = d.get_secret(SECRET_STORE_NAME, SECRET_STORE_ENDPOINT)
            analytics_endpoint = resp.secret[SECRET_STORE_ENDPOINT]
    else:
        analytics_endpoint = COGNITIVE_SERVICE_API_ENDPOINT

    app.run(APP_PORT)


if __name__ == "__main__":
    logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)
    main()
