import json
import logging
import os
import base64
from typing import Optional, Any, List, Dict
from dapr.clients import DaprClient

logger = logging.getLogger(__name__)


class DaprStateStore:
    def __init__(self, store_name: Optional[str] = None):
        self.store_name = store_name or os.getenv("DAPR_STORE_NAME", "catalogue-store")
        self.client = DaprClient()
        logger.info(f"Initialized Dapr state store client for store: {self.store_name}")

    async def get_item(self, key: str) -> Optional[dict]:
        """Get an item from the state store."""
        try:
            response = self.client.get_state(
                store_name=self.store_name,
                key=key
            )
            
            if response.data:
                data = json.loads(response.data)
                logger.debug(f"Retrieved item with key '{key}': {data}")
                return data
            else:
                logger.debug(f"No item found with key '{key}'")
                return None
                
        except Exception as e:
            logger.error(f"Error getting item with key '{key}': {str(e)}")
            raise

    async def save_item(self, key: str, data: dict) -> None:
        """Save an item to the state store."""
        try:
            self.client.save_state(
                store_name=self.store_name,
                key=key,
                value=json.dumps(data)
            )
            logger.debug(f"Saved item with key '{key}': {data}")
            
        except Exception as e:
            logger.error(f"Error saving item with key '{key}': {str(e)}")
            raise

    async def delete_item(self, key: str) -> None:
        """Delete an item from the state store."""
        try:
            self.client.delete_state(
                store_name=self.store_name,
                key=key
            )
            logger.debug(f"Deleted item with key '{key}'")
            
        except Exception as e:
            logger.error(f"Error deleting item with key '{key}': {str(e)}")
            raise

    async def query_items(self, query: Dict[str, Any]) -> tuple[List[Dict[str, Any]], Optional[str]]:
        """
        Query items from the state store using Dapr state query API.
        
        Args:
            query: Query dictionary with filter, sort, and page options
            
        Returns:
            Tuple of (results list, pagination token)
        """
        try:
            query_json = json.dumps(query)
            logger.info(f"Executing state query with: {query_json}")
            response = self.client.query_state(
                store_name=self.store_name,
                query=query_json
            )
            
            logger.info(f"Query response type: {type(response)}, has {len(response.results)} results")
            
            results = []
            for item in response.results:
                logger.info(f"Processing item - key: {item.key}, value type: {type(item.value)}")
                try:
                    # The value might already be a string (JSON), not bytes
                    if hasattr(item.value, 'decode'):
                        # It's bytes, decode it
                        value_str = item.value.decode('UTF-8')
                        logger.info(f"Decoded bytes to string for key {item.key}")
                    else:
                        # It's already a string
                        value_str = item.value
                        logger.info(f"Value already string for key {item.key}")
                    
                    logger.info(f"Value string for key {item.key}: {value_str[:200]}...")  # First 200 chars
                    
                    # Parse the JSON string
                    value = json.loads(value_str)
                    logger.info(f"First JSON parse result type for key {item.key}: {type(value)}")
                    
                    # If the value is a string, it might be base64 encoded JSON
                    if isinstance(value, str):
                        logger.info(f"Value is a string, checking if it's base64 encoded for key {item.key}")
                        try:
                            # Try base64 decoding
                            decoded_bytes = base64.b64decode(value)
                            decoded_str = decoded_bytes.decode('utf-8')
                            logger.info(f"Base64 decoded string for key {item.key}: {decoded_str[:200]}...")
                            value = json.loads(decoded_str)
                            logger.info(f"Successfully parsed base64-decoded JSON for key {item.key}")
                        except Exception as e:
                            logger.warning(f"Failed to base64 decode for key {item.key}: {e}")
                            # Keep the original string value
                    
                    logger.info(f"Final value type for key {item.key}: {type(value)}")
                    
                    results.append({
                        'key': item.key,
                        'value': value
                    })
                except Exception as e:
                    logger.error(f"Failed to parse item with key {item.key}: {e}")
                    logger.error(f"Raw value type: {type(item.value)}, content: {item.value}")
            
            logger.info(f"Query completed - returned {len(results)} valid items, token: {response.token}")
            return results, response.token
            
        except Exception as e:
            logger.error(f"Error querying state store: {str(e)}")
            raise