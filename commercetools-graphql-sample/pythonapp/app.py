# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------------------------------

import time
import requests
import os
import json

dapr_port = os.getenv("DAPR_HTTP_PORT", 3500)

dapr_url = "http://localhost:{}/v1.0/bindings/sample-project".format(dapr_port)
n = 0
while True:
    n += 1

    queryProductProjectionSearch = ''\
        'query { '\
        'productProjectionSearch(text: "bag", locale: "en", limit: 25) {'\
        'total '\
        'count '\
        'results { '\
        'id '\
        'name (locale: "en") '\
        'slug (locale: "en") '\
        '}'\
        '}'\
        '}'
    queryProduct = ''\
        'query { '\
        'products { '\
        'count '\
        'results { '\
        'id '\
        'productType { '\
        'id '\
                   '} '\
        '} '\
        '} '\
        '} '
    print("query: "+queryProduct, flush=True)

    query = queryProduct
    graphQLPayload = {"data": {
        "commercetoolsAPI": "GraphQLQuery", "query": query}, "operation": "create"}

    try:
        # GraphQl query
        response = requests.post(dapr_url, json=graphQLPayload)
        dict = response.json()

        if 'products' in query:
            print('products found: ' +
                  str(dict['products']['count']), flush=True)
            for key in dict['products']['results']:
                print("- product name: "+key["id"], flush=True)

    except Exception as e:
        print(e, flush=True)

    time.sleep(1)
