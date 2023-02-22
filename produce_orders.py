from datetime import datetime
from time import sleep
import csv
from unittest import result
import pyodbc 

server = '<DB_ENDPOINT>'
database = 'public'
username = '<DB_USERNAME>'
password = '<DB_PASSWORD>'
purchase_count = 10000

try:
    connection = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password+';TrustServerCertificate=yes;')
    cursor = connection.cursor()
    sql_query="""DELETE FROM [public].dbo.orders;"""
    result = cursor.execute(sql_query)
    connection.commit()
except pyodbc.Error as error:
    print("Failed to connect to SQL Server {}".format(error))


def create_order():
    i = 0
    with open("orders.csv", "r") as orders_file:
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
                    sql_query = """INSERT INTO orders (order_id, product_id, customer_id, purchase_timestamp) VALUES (?, ?, ?, ?)"""
                    insert_values = (order_id, product_id, customer_id, purchase_timestamp)
                    result = cursor.execute(sql_query, insert_values)
                    connection.commit()
                    print("Successfully added a new order: "+order_id+","+product_id+","+customer_id+","+purchase_timestamp)
                except pyodbc.Error as error:
                    connection.rollback()
                    print("Failed to insert into orders table {}".format(error))
                i += 1
                sleep(0.2)

if __name__ == '__main__':
    create_order()
    if(connection):
        connection.close()
        print("SQL Server connection is closed")