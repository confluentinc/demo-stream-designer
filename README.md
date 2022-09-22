# Current 2022 Confluent Keynote Demo

Internal repo for Current 2022 Confluent Keynote Demo covering Stream Designer, Stream Sharing, and Stream Catalog.

## Requirements

In order to successfully complete this demo you need to install few tools before getting started.

- This demo uses Stream Designer in Confluent Cloud. If you don't have a Confluent Cloud account, sign up for a free trial [here](https://www.confluent.io/confluent-cloud/tryfree).
- Install Confluent Cloud CLI by following the instructions [here](https://docs.confluent.io/confluent-cli/current/install.html).
- An AWS account with permissions to create resources. Sign up for an account [here](https://aws.amazon.com/account/).
- (Optional) Install a database tool. This demo uses [DBeaver Community](https://dbeaver.io/).
- This demo uses Python 3.9.13 version.
- This demo uses pyodbc module. You can install this module through `pip`.
  ```
  pip3 install pyodbc
  ```

> **Note:** This demo was built and validate on a Mac (x86).

## Prerequisites

### Set up Confluent Cloud

1. Sign up for a Confluent Cloud account [here](https://www.confluent.io/get-started/).
1. After verifying your email address, access Confluent Cloud sign-in by navigating [here](https://confluent.cloud).
1. When provided with the _username_ and _password_ prompts, fill in your credentials.

   > **Note:** If you're logging in for the first time you will see a wizard that will walk you through the some tutorials. Minimize this as you will walk through these steps in this guide.

1. Click **+ Add environment**.

   > **Note:** There is a _default_ environment ready in your account upon account creation. You can use this _default_ environment for the purpose of this demo if you do not wish to create an additional environment.

   - Specify a meaningful `name` for your environment and then click **Create**.
     > **Note:** It will take a few minutes to assign the resources to make this new environment available for use.

1. Now that you have an environment, let's create a cluster. Select **Create Cluster**.

   > **Note**: Confluent Cloud clusters are available in 3 types: **Basic**, **Standard**, and **Dedicated**. Basic is intended for development use cases and only support single zone availability. Standard and Dedicated clusters are intended for production use and support Multi-zone deployments. If you’re interested in learning more about the different types of clusters and their associated features and limits, refer to this [documentation](https://docs.confluent.io/current/cloud/clusters/cluster-types.html).

   - Choose the **Dedicated** cluster type.

   - Click **Begin Configuration**.

   - Choose **AWS** as your Cloud Provider and your preferred Region. In this demo we use Oregon (West2) as the region.

   - Specify a meaningful **Cluster Name** and then review the associated _Configuration & Cost_, _Usage Limits_, and _Uptime SLA_ before clicking **Launch Cluster**.

#### Create an API key pair

1. Select API keys on the navigation menu.
1. If this is your first API key within your cluster, click **Create key**. If you have set up API keys in your cluster in the past and already have an existing API key, click **+ Add key**.
1. Select **Global Access**, then click Next.
1. Save your API key and secret - you will need these during the demo.
1. After creating and saving the API key, you will see this API key in the Confluent Cloud UI in the API keys tab. If you don’t see the API key populate right away, refresh the browser.

#### Enable Schema Registery

1. On the navigation menu, select **Schema Registery**.
1. Click **Set up on my own**.
1. Choose **AWS** as the cloud provider and a supported **Region**
1. Click on **Enable Schema Registry**.

### Setup SQL Server

1. This demo uses a Microsoft SQL Server Standard Edition hosted on AWS. Change Data Capture (CDC) is only Enterprise, Developer, Enterprise Evaluation, and Standard editions, so ensure you choose a configuration that supports CDC.
1. This demo uses Amazon RDS Microsoft SQL Server that is publicly accessible. If your database is in a VPC, follow the instructions on our [doc](https://docs.confluent.io/cloud/current/networking/peering/aws-peering.html) page.
1. Navigate to https://aws.amazon.com/console/ and log into your account.
1. Search for **RDS** and click on results.
1. Click on **Create database** and create an Microsoft SQL Server database using the following configurations and leave everything else as default.
   ```
   Creation mode: Standard
   Engine: Microsoft SQL Server
   Database management type: Amazon RDS
   Edition: SQL Server Standard Edition
   License: license-included
   Version: SQL Server 2019 15.00.4198.2.v1
   Template: production
   DB instance identifier: sql-server-demo
   Master username: admin
   Auto generate a password: check the box
   port: 1433
   Public access: Yes
   ```
1. If you opted in using an auto-generated password, ensure you click on **View credentials details** while the instance is being created to download your password.

1. Download and install Microsoft ODBC driver for your operating system from [here](https://docs.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server?view=sql-server-ver15).

1. You can use DBeaver and connect to your SQL Server and verify that your database is populating correctly in following steps.

1. Update `configure_sqlserver.py` so the following values correspond to your database.

   ```
   server = '<DB_ENDPOINT>'
   database = 'public'
   username = '<DB_USERNAME>'
   password = '<DB_PASSWORD>'
   ```

1. Run `python3 configure_sqlserver.py`.
1. This script completes the following task
   - Creates a database called `public`.
   - Creates and populates `orders` and `products` tables.
   - Enables CDC on the database and both tables.

## Setup

1. Log into Confluent Cloud and navigate to the **Topic** tab.
1. Click on **+Add topic** and create a new topic with following configuration.

   ```
   click_stream --partitions 1
   ```

   > Alternatively you can create this topic by using Confluent Cloud CLI and running `confluent kafka topic create click_stream --partitions 1` command.

1. Update `produce_clickstream.py` and set `num_clicks = 3000`.
1. Update `config.ini` file and set the following values with your own Confluent Cloud cluster.
   ```
   bootstrap.servers=<BOOTSTRAP.SERVER>
   sasl.username=<KAFKA_CLUSTER_API>
   sasl.password=<KAFKA_CLUSTER_SECRET_KEY>
   ```
1. Open a `Terminal` window and run the script.

   ```
   python3 produce_clickstream.py config.ini
   ```

1. Log into Confluent Cloud and navigate to Stream Designer tab.

1. Click on **+ Create pipeline** icon. Choose a name for your pipeline and create a ksqlDB Cluster.

## Demo

1. Log into Confluent Cloud and navigate to ksqlDB tab and step into your cluster.
1. Change `auto.offset.reset = Earliest`.
1. Create a ksqlDB stream off of `click_stream` topic.
   ```sql
   CREATE STREAM click_stream (user_id VARCHAR, product_id VARCHAR, view_time INTEGER, page_url VARCHAR, ip_address VARCHAR)
   WITH (KAFKA_TOPIC='click_stream', KEY_FORMAT ='JSON', VALUE_FORMAT='JSON');
   ```
1. Verify the `click_stream` stream is populated correctly.
   ```sql
   SELECT * FROM click_stream EMIT CHANGES;
   ```
1. We need to reserialize `click_stream` stream so Schema Registry can track all the changes to the schema.
   ```sql
   CREATE STREAM clickstreams_global WITH (KAFKA_TOPIC='clickstreams_global', PARTITIONS=1, REPLICAS=3, KEY_FORMAT ='JSON', VALUE_FORMAT='JSON_SR') AS
      SELECT *
      FROM CLICK_STREAM
      EMIT CHANGES;
   ```
1. Verify the `clickstreams_global` stream is populated correctly.
   ```sql
   SELECT * FROM clickstreams_global EMIT CHANGES;
   ```
1. Use the left handside menu and navigate to **Stream Designer** and set into the pipeline you created earlier.
1. Click on **Start with SQL** to open the code editor and paste the following code.

   ```sql
   CREATE SOURCE CONNECTOR "SqlServerCdcSourceConnector_0" WITH (
   "after.state.only"='true',
   "connector.class"='SqlServerCdcSource',
   "database.dbname"='public',
   "database.hostname"='sql-server-demo.***.us-west-2.rds.amazonaws.com',
   "database.password"='<SQL_SERVER_PASSWORD>',
   "database.port"='1433',
   "database.server.name"='sql',
   "database.user"='admin',
   "kafka.api.key"='<KAFKA_API_KEY>',
   "kafka.api.secret"='<KAFKA_API_SECRET>',
   "kafka.auth.mode"='KAFKA_API_KEY',
   "max.batch.size"='1',
   "output.data.format"='JSON_SR',
   "output.key.format"='JSON',
   "poll.interval.ms"='1',
   "snapshot.mode"='initial',
   "table.include.list"='dbo.products, dbo.orders',
   "tasks.max"='1'
   );

   CREATE OR REPLACE STREAM "orders_stream" (CUSTOMER_ID STRING, ORDER_ID STRING KEY, PRODUCT_ID STRING, PURCHASE_TIMESTAMP STRING)
   WITH (kafka_topic='sql.dbo.orders', partitions=1, key_format='JSON', value_format='JSON_SR');

   CREATE OR REPLACE STREAM "products_stream" (PRODUCT_ID STRING KEY, PRODUCT_NAME STRING, PRODUCT_RATING DOUBLE, SALE_PRICE INTEGER)
   WITH (kafka_topic='sql.dbo.products', partitions=1, key_format='JSON', value_format='JSON_SR');

   CREATE OR REPLACE TABLE "products_table"
   WITH (kafka_topic='products_table', partitions=1, value_format='JSON_SR') AS
      SELECT EXTRACTJSONFIELD(PRODUCT_ID, '$.product_id') AS PRODUCT_ID,
         LATEST_BY_OFFSET(PRODUCT_NAME) AS PRODUCT_NAME,
         LATEST_BY_OFFSET(PRODUCT_RATING) AS PRODUCT_RATING,
         LATEST_BY_OFFSET(SALE_PRICE) AS SALE_PRICE
      FROM "products_stream"
      GROUP BY EXTRACTJSONFIELD(PRODUCT_ID, '$.product_id');

   CREATE OR REPLACE STREAM "orders_stream_productid_rekeyed"
   WITH (kafka_topic='orders_stream_productid_rekeyed', partitions=1, value_format='JSON_SR') AS
      SELECT CUSTOMER_ID,
         EXTRACTJSONFIELD(ORDER_ID, '$.order_id') AS ORDER_ID,
         PRODUCT_ID,
         PURCHASE_TIMESTAMP
      FROM "orders_stream"
      PARTITION BY PRODUCT_ID;

   CREATE OR REPLACE STREAM "orders_and_products"
   WITH (kafka_topic='orders_and_products', partitions=1, value_format='JSON_SR') AS
      SELECT *
      FROM "orders_stream_productid_rekeyed" O
         INNER JOIN "products_table" P
         ON O.PRODUCT_ID = P.PRODUCT_ID;
   ```

1. Update the following variables to match your environment:

   ```
   database.hostname
   database.password
   kafka.api.key
   kafka.api.secret
   ```

1. Click on **Activate pipeline** and wait until all components are activated and the source connector is in **Running** state.
   > Note: you might have to **Activate** or **Re-activate** the pipeline if your topics and operations were activated before your source connector was in the running state.
1. Click on each topic to verify they are populated correctly.

![Alt Text](complete-pipeline.gif)

## Code Import

1. You can build the entire demo by going to pasting the following code into the code editor.

   ```sql
   CREATE SOURCE CONNECTOR "SqlServerCdcSourceConnector_0" WITH (
   "after.state.only"='true',
   "connector.class"='SqlServerCdcSource',
   "database.dbname"='public',
   "database.hostname"='sql-server-demo.***.us-west-2.rds.amazonaws.com',
   "database.password"='<SQL_SERVER_PASSWORD>',
   "database.port"='1433',
   "database.server.name"='sql',
   "database.user"='admin',
   "kafka.api.key"='<KAFKA_API_KEY>',
   "kafka.api.secret"='<KAFKA_API_SECRET>',
   "kafka.auth.mode"='KAFKA_API_KEY',
   "max.batch.size"='1',
   "output.data.format"='JSON_SR',
   "output.key.format"='JSON',
   "poll.interval.ms"='1',
   "snapshot.mode"='initial',
   "table.include.list"='dbo.products, dbo.orders',
   "tasks.max"='1'
   );

   CREATE OR REPLACE STREAM "orders_stream" (CUSTOMER_ID STRING, ORDER_ID STRING KEY, PRODUCT_ID STRING, PURCHASE_TIMESTAMP STRING)
   WITH (kafka_topic='sql.dbo.orders', partitions=1, key_format='JSON', value_format='JSON_SR');

   CREATE OR REPLACE STREAM "clickstreams_global" (IP_ADDRESS STRING, PAGE_URL STRING, PRODUCT_ID STRING , USER_ID STRING , VIEW_TIME INTEGER )
   WITH (kafka_topic='clickstreams_global', partitions=1, value_format='JSON_SR');

   CREATE OR REPLACE STREAM "orders_enriched"
   WITH (kafka_topic='orders_enriched', partitions=1, value_format='JSON_SR')
   AS SELECT * FROM "orders_stream" o INNER JOIN "clickstreams_global" c
      WITHIN 1 HOUR GRACE PERIOD 1 MINUTE
   ON o.customer_id = c.user_id;

   CREATE OR REPLACE STREAM "products_stream" (PRODUCT_ID STRING KEY, PRODUCT_NAME STRING, PRODUCT_RATING DOUBLE, SALE_PRICE INTEGER)
   WITH (kafka_topic='sql.dbo.products', partitions=1, key_format='JSON', value_format='JSON_SR');

   CREATE OR REPLACE TABLE "products_table"
   WITH (kafka_topic='products_table', partitions=1, value_format='JSON_SR') AS
      SELECT EXTRACTJSONFIELD(PRODUCT_ID, '$.product_id') AS PRODUCT_ID,
         LATEST_BY_OFFSET(PRODUCT_NAME) AS PRODUCT_NAME,
         LATEST_BY_OFFSET(PRODUCT_RATING) AS PRODUCT_RATING,
         LATEST_BY_OFFSET(SALE_PRICE) AS SALE_PRICE
      FROM "products_stream"
      GROUP BY EXTRACTJSONFIELD(PRODUCT_ID, '$.product_id');

   CREATE OR REPLACE STREAM "orders_stream_productid_rekeyed"
   WITH (kafka_topic='orders_stream_productid_rekeyed', partitions=1, value_format='JSON_SR') AS
      SELECT CUSTOMER_ID,
         EXTRACTJSONFIELD(ORDER_ID, '$.order_id') AS ORDER_ID,
         PRODUCT_ID,
         PURCHASE_TIMESTAMP
      FROM "orders_stream"
      PARTITION BY PRODUCT_ID;

   CREATE OR REPLACE STREAM "orders_and_products"
   WITH (kafka_topic='orders_and_products', partitions=1, value_format='JSON_SR') AS
      SELECT *
      FROM "orders_stream_productid_rekeyed" O
         INNER JOIN "products_table" P
         ON O.PRODUCT_ID = P.PRODUCT_ID;

   CREATE OR REPLACE STREAM "big_bend_shoes"
   WITH (kafka_topic='big_bend_shoes', partitions=1, value_format='JSON_SR') AS
      SELECT *
      FROM "orders_and_products"
      WHERE LCASE(P_PRODUCT_NAME) LIKE '%big bend shoes%';

   CREATE SINK CONNECTOR "MongoDbAtlasSinkConnector_0" WITH (
   "connection.host"='<MONGODB_ENDPOINT>',
   "connection.password"='<DATABASE_PASSWORD>',
   "connection.user"='<DATABASE_USER>',
   "connector.class"='MongoDbAtlasSink',
   "database"='<DATABASE_NAME>',
   "input.data.format"='JSON_SR',
   "kafka.api.key"='<KAFKA_API_KEY>',
   "kafka.api.secret"='<KAFKA_API_SECRET>',
   "kafka.auth.mode"='KAFKA_API_KEY',
   "tasks.max"='1',
   "topics"='orders_enriched'
   );
   ```

## Teardown

## References
