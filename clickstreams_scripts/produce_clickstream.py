#!/usr/bin/env python

from distutils.command.config import config
import sys
from random import choice
from argparse import ArgumentParser, FileType
# from configparser import ConfigParser
from cc_config import KAFKA_CONFIG
from confluent_kafka import Producer
from datetime import datetime
from time import sleep

import csv
import math
import random
import json

num_users = 5
num_products = 5
num_clicks = 10
url_pattern = "https://www.acme.com/product/"

user_ids = []
product_ids = []
view_times = []
urls = []
ip_addresses = []
click_streams = []
click_streams_header =["user_id", "product_id", "view_time", "page_url", "ip_address"]

# Create Producer instance
producer = Producer(KAFKA_CONFIG)

# Optional per-message delivery callback (triggered by poll() or flush())
# when a message has been successfully delivered or permanently
# failed delivery (after retries).
def delivery_callback(err, msg):
    if err:
        print('ERROR: Message failed delivery: {}'.format(err))
    else:
        # print("Produced event to topic {topic}: key = {key:12} value = {value:12}".format(
        #     topic=msg.topic(), key=msg.key().decode('utf-8'), value=msg.value().decode('utf-8')))
        print("Produced event to topic {topic}: value = {value:12}".format(
            topic=msg.topic(), value=msg.value().decode('utf-8')))

def read_userid():
    i = 0
    with open("../data/customers.csv", "r") as users_file:
        users_file.seek(0)
        rows = csv.reader(users_file)
        # skip first line
        next(rows, None) 
        for row in rows:
            if(i < num_users):
                user_ids.append(row[0])
                i += 1

def read_productid():
    i = 0
    with open("../data/products.csv", "r") as products_file:
        rows = csv.reader(products_file)
        # skip the first line
        next(rows, None)
        for row in rows:
            if(i < num_products):
                product_ids.append(row[0])
                i += 1

def generate_viewtime():
    for i in range(0, num_clicks):
        random.seed(None)
        view_time = random.random()
        view_time = math.floor(view_time * 100)
        view_times.append(view_time)

def generate_url():
    for i in range(0, num_clicks):
        random.seed(None)
        rand = random.random()
        curr_id = int(rand * num_products)
        urls.append(url_pattern + product_ids[curr_id])

def generate_ip_address():
    # Creating a list of ip addresses
    for i in range (0, num_clicks):
        ip = '.'.join('%s'%random.randint(0, 255) for i in range(4))
        ip_addresses.append(ip)
        

def generate_click_streams():
    topic = "click_stream"
    for i in range(0, num_clicks):
        random.seed(None)
        rand = random.random()
        curr_user = int(rand * num_users)
        curr_product = int(rand * num_products)

        new_click ={} 
        new_key = str(user_ids[curr_user])
        new_click['user_id']= str(user_ids[curr_user]) 
        new_click['product_id']= str(product_ids[curr_product])
        new_click['view_time']= view_times[i] 
        new_click['page_url']= str(urls[i]) 
        new_click['ip_address']= ip_addresses[i]
        # print(new_click) 

        # Trigger any available delivery report callbacks from previous produce() calls
        producer.poll(0)

        # Asynchronously produce a message, the delivery report callback
        # will be triggered from poll() above, or flush() below, when the message has
        # been successfully delivered or failed permanently.
        # producer.produce(topic, key=new_key, value=json.dumps(new_click), on_delivery=delivery_callback)
        producer.produce(topic, value=json.dumps(new_click), on_delivery=delivery_callback)
        sleep(0.2)
        
        # Wait for any outstanding messages to be delivered and delivery report
        # callbacks to be triggered.

        producer.flush()
        # write the click stream data to a csv file

    

if __name__ == '__main__':

    read_userid()
    read_productid()
    generate_viewtime()
    generate_url()
    generate_ip_address()

    # create the clickstream list from randomized values
    generate_click_streams()

