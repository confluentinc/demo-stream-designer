from datetime import datetime
from pathlib import Path
from time import sleep
import sql_config
import csv
import os
import pyodbc 

server = sql_config.server
database = 'public' 
username = sql_config.username
password = sql_config.password 
purchase_count = 5

# --replace your-database-name with the name of the database you want to drop
# EXECUTE msdb.dbo.rds_drop_database  N'public'


def create_database():
    database = 'master' 
    connection = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password+';TrustServerCertificate=yes;', autocommit=True)

    try:
        cursor = connection.cursor()
        sql_query = """CREATE DATABASE [public]""" 
        cursor.execute(sql_query)
        connection.commit()
        print("Successfully created the database")
    except pyodbc.Error as error:
        print("Failed {}".format(error))
    
    close_db_connection(connection)

def enable_cdc_database():
    connection = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password+';TrustServerCertificate=yes;', autocommit=True)

    try:
        cursor = connection.cursor()
        sql_query = """exec msdb.dbo.rds_cdc_enable_db @db_name=?"""
        cursor.execute(sql_query, database)
        print("Successfully enabled CDC on the database.")
    except pyodbc.Error as error:
        print("Failed {}".format(error))
    
    close_db_connection(connection)


def orders_table(data_dir):
    i = 0
    connection = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password+';TrustServerCertificate=yes;', autocommit=True)
    data_file = os.path.join(data_dir, "orders.csv")

    # create orders table
    try:
        cursor = connection.cursor()
        sql_query = """CREATE table [public].dbo.orders(
            order_id VARCHAR(50) PRIMARY KEY,
            product_id VARCHAR(50),
            customer_id VARCHAR(50),
            purchase_timestamp VARCHAR(128)
        );"""
        cursor.execute(sql_query)
        print("Successfully created 'orders' table.")
        
        sleep(0.5)
        # start tracking for CDC
        sql_query = """exec sys.sp_cdc_enable_table   
            @source_schema           = N'dbo'
            ,  @source_name             = N'orders'
            ,  @role_name               = N'admin'"""
        cursor.execute(sql_query)
        print("Successfully enabled CDC on the 'orders' table.")

    except pyodbc.Error as error:
        print("Failed {}".format(error))

    sleep (0.5)
    print("Inserting values to 'orders' table.")
    with open(data_file, "r") as orders_file:
        orders_file.seek(0)
        rows = csv.reader(orders_file)
        # skip first line
        next(rows, None) 
        for row in rows:
            if(i < purchase_count):
                current_time = datetime.now()
                order_id = row[0]
                product_id = row[1]
                customer_id = row[2]
                purchase_timestamp = current_time.isoformat()
                try:
                    cursor = connection.cursor()
                    sql_query = """INSERT INTO orders (order_id, product_id, customer_id, purchase_timestamp) VALUES (?, ?, ?, ?)"""
                    insert_values = (order_id, product_id, customer_id, purchase_timestamp)
                    cursor.execute(sql_query, insert_values)
                    connection.commit()
                    print("Successfully added a new order: "+order_id+","+product_id+","+customer_id+","+purchase_timestamp)
                except pyodbc.Error as error:
                    connection.rollback()
                    print("Failed to insert into 'orders' table {}".format(error))
                i += 1
                sleep(0.2)
    
    close_db_connection(connection)

def products_table(data_dir):
    connection = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password+';TrustServerCertificate=yes;', autocommit=True)
    data_file = os.path.join(data_dir,"products.csv")

    # create products table
    try:
        cursor = connection.cursor()
        sql_query = """CREATE table [public].dbo.products(
            product_id VARCHAR(50) PRIMARY KEY,
            product_name VARCHAR(50),
            sale_price int,
            product_rating float
        );"""
        cursor.execute(sql_query)
        print("Successfully created 'products' table.")
        
        sleep(0.5)

        # start tracking for CDC 
        sql_query = """exec sys.sp_cdc_enable_table   
            @source_schema           = N'dbo'
            ,  @source_name             = N'products'
            ,  @role_name               = N'admin'"""
        cursor.execute(sql_query)
        print("Successfully enabled CDC on the 'products' table.")

    except pyodbc.Error as error:
        print("Failed {}".format(error))

    sleep (0.5)
    print("Inserting values to 'products' table.")
    with open(data_file, "r") as products_file:
        products_file.seek(0)
        rows = csv.reader(products_file)
        # skip first line
        next(rows, None) 
        for row in rows:
            product_id = row[0]
            product_name = row[1]
            sale_price = row[2]
            product_rating = row[3]
            try:
                cursor = connection.cursor()
                sql_query = """INSERT INTO products (product_id, product_name, sale_price, product_rating) VALUES (?, ?, ?, ?)"""
                insert_values = (product_id, product_name, sale_price, product_rating)
                cursor.execute(sql_query, insert_values)
                connection.commit()
                print("Successfully added a new product: "+product_id+","+product_name+","+sale_price+","+product_rating)
            except pyodbc.Error as error:
                connection.rollback()
                print("Failed to insert into 'products' table {}".format(error))

    
    close_db_connection(connection)


def close_db_connection(connection):
    if(connection):
        connection.close()
        print("SQL Server connection is closed")

if __name__ == '__main__':

    python_prepare_database = Path(__file__).absolute().with_name("prepare_sqlserver.py")
    parent_directory = os.path.dirname(python_prepare_database)
    data_dir = os.path.join(os.path.dirname(parent_directory), "data")

    print("Create 'public' database...")
    create_database()
    print("Enable CDC on the database...")
    enable_cdc_database()

    print("Create 'products' table.")
    products_table(data_dir)
    
    print("Create 'orders' table.")
    orders_table(data_dir)



