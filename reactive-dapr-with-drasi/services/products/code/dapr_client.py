import json
import logging
import os
import base64
from typing import Optional, Any, List, Dict
from dapr.clients import DaprClient

logger = logging.getLogger(__name__)


class DaprStateStore:
    def __init__(self, store_name: Optional[str] = None):
        self.store_name = store_name or os.getenv("DAPR_STORE_NAME", "products-store")
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
            logger.debug(f"Executing state query with: {query_json}")
            response = self.client.query_state(
                store_name=self.store_name,
                query=query_json
            )
            
            results = []
            for item in response.results:
                try:
                    # The value might already be a string (JSON), not bytes
                    if hasattr(item.value, 'decode'):
                        # It's bytes, decode it
                        value_str = item.value.decode('UTF-8')
                    else:
                        # It's already a string
                        value_str = item.value
                    
                    # Parse the JSON string
                    value = json.loads(value_str)
                    
                    # If the value is a string, it might be base64 encoded JSON
                    if isinstance(value, str):
                        try:
                            # Try base64 decoding
                            decoded_bytes = base64.b64decode(value)
                            decoded_str = decoded_bytes.decode('utf-8')
                            value = json.loads(decoded_str)
                        except Exception:
                            # Keep the original string value if base64 decode fails
                            pass
                    
                    results.append({
                        'key': item.key,
                        'value': value
                    })
                except Exception as e:
                    logger.error(f"Failed to parse item with key {item.key}: {e}")
            
            logger.debug(f"Query completed - returned {len(results)} items")
            return results, response.token
            
        except Exception as e:
            logger.error(f"Error querying state store: {str(e)}")
            raise