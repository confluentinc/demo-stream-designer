from ensurepip import bootstrap
import os
from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.

# Define Kafka Configurations
KAFKA_CONFIG: 'dict[str,str]' = {
    # Kafka cluster
    "bootstrap.servers": os.environ["CCLOUD_BOOTSTRAP_ENDPOINT"],
    "sasl.username": os.environ["CCLOUD_API_KEY"],
    "sasl.password": os.environ["CCLOUD_API_SECRET"],
    "security.protocol": "SASL_SSL",
    "sasl.mechanisms": "PLAIN"
    }

if __name__ == "__main__":
    for item in KAFKA_CONFIG.items() :
        print(item)