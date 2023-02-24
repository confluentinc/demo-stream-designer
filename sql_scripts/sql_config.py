import os
from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.

username = os.environ.get("SQL_USERNAME")
password = os.environ.get("SQL_PASSWORD")
server = os.environ.get("SQL_SERVER")
port = int(os.environ.get("SQL_PORT","1433"))

if __name__=="__main__":
    for i in [username, password, server, port]:
        # print(type(i))
        print(i)