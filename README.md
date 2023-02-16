# Stream Designer Demo

Data pipelines continue to do the heavy-lifting in data integration. In order to immediately act on insights, companies turn to Apache Kafka® to replace legacy, batch-based pipelines with streaming data pipelines. There are still major challenges with building reusable data pipelines on open-source Kafka, like an overreliance on specialized Kafka engineering talent and cumbersome development cycles. These bottlenecks limit the speed at which teams can set data in motion.

Confluent’s Stream Designer is a new visual canvas for rapidly building, testing, and deploying streaming data pipelines powered by Kafka. You can quickly and easily build pipelines graphically or with SQL, leveraging built-in integrations with fully managed connectors, ksqlDB for stream processing, and Kafka topics.
This demo walks you through building streaming data pipelines in minute!

Watch the [demo](https://youtu.be/vc3od1KLU_0?t=1538) during Current 2022 keynote: Reimagining Data Pipelines for the Streaming Era.

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

   - Choose the **Basic** cluster type.

   - Click **Begin Configuration**.

   - Choose **AWS** as your Cloud Provider and your preferred Region. In this demo we use Oregon (West2) as the region.

   - Specify a meaningful **Cluster Name** and then review the associated _Configuration & Cost_, _Usage Limits_, and _Uptime SLA_ before clicking **Launch Cluster**.

#### Create an API key pair

1. Select API keys on the navigation menu.
1. If this is your first API key within your cluster, click **Create key**. If you have set up API keys in your cluster in the past and already have an existing API key, click **+ Add key**.
1. Select **Global Access**, then click Next.
1. Save your API key and secret - you will need these during the demo.
1. After creating and saving the API key, you will see this API key in the Confluent Cloud UI in the API keys tab. If you don’t see the API key populate right away, refresh the browser.

#### Enable Stream Governance Advanced package

1. Navigate to your cluster page and on the right hand-side enable **Stream Goveranance Advanced** package.
1. Choose **AWS** as the cloud provider and a supported **Region**
1. Click on **Tags** to create new tags.
1. Click on the **+Create tag** icon and add the following **Free-form** tags.
   ```
   Tag name: prod
   Description: Data for production environment.
   Tag name: stag
   Description: Data for staging environment.
   Tag name: dev
   Description: Data for development environment.
   ```
1. Create a **Recommended** tag and check **PII** box.
1. Navigate back to your cluster and click on **Business metadata** and create a new business metadata with following configuration.
   ```
   Name: Domain
   Description: Events for analyzing users behavior.
   Attribute 1: Team_owner
   Attribute 2: Slack_contact
   Attribute 3: Name
   ```
1. For more information and detailed instructions visit our [doc](https://docs.confluent.io/cloud/current/stream-governance/index.html) page.

### Setup SQL Server

1. This demo uses a Microsoft SQL Server Standard Edition hosted on AWS. Change Data Capture (CDC) is only supported on Enterprise, Developer, Enterprise Evaluation, and Standard editions, so ensure you choose a configuration that supports CDC.
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

1. Update `configure_sqlserver.py` and `produce_orders.py` so the following values match with your database.

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

1. Log into Confluent Cloud and navigate to your cluster.
1. Navigate to the **Topic** tab and click on **+Add topic** and create a new topic with following configuration.

   ```
   click_stream --partitions 1
   ```

   > Alternatively you can create this topic by using Confluent Cloud CLI and running `confluent kafka topic create click_stream --partitions 1` command.

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

1. Open anoterh `Terminal` window and create new orders.
   ```
   python3 produce_orders.py
   ```
1. Log into Confluent Cloud and navigate to Stream Designer tab.

1. Click on **+ Create pipeline** icon. Choose a name for your pipeline and create a ksqlDB Cluster.
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
1. Use **Stream Catalog** and search for `clickstreams_global` and click on the topic.
1. On the right side of the screen add `prod` in **Tags** section.
1. Click on **+Add business metadata** and from the drop down list select **Domain** and add the following information
   - Team_owner: Web
   - Slack_contact: #web-optimization
   - Name: user clickstreams

## Demo

1. Log into Confluent Cloud and navigate to **Stream Designer** and step into the pipeline you created earlier.
1. Click on **Start with SQL** to open the code editor and paste the following code.
1. The code adds the below components to the canvas

   - SQL Server source connector which captures all data changes in our source database and streams it to Confluent Cloud in near real time([doc](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-source-cdc-debezium.html)).
   - `sql.dbo.orders` and `sql.dbo.products` as connector's output topics.
   - `orders_stream` and `products_stream` that are ksqlDB streams based on output topics.
   - `products_table` which is a ksqlDB table that has the latest information for each product.
   - We need to re-partition the `orders_stream` and use `product_id` as the key so we can join the stream with `products_table`. This stream is called `orders_stream_productid_rekeyed`.
   - Join `products_table` and `orders_stream_productid_rekeyed` and call the resulting stream `orders_and_products`.

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
1. We want to see how Big Bend Shoes are selling in our store. In order to do that, we need to apply a filter to `orders_and_products` stream.
1. Click on the right edge of `orders_and_products` stream and hit on **Filter** from list of options.
1. Create a new filter with the following properties and hit **Save**
   ```
   query name: shoes
   filter name: shoes
   filter expression: LCASE(P_PRODUCT_NAME) LIKE '%big bend shoes%'
   ```
1. Click on the right edge of **Filter** component and create a new Kafka topic and ksqlDB stream with the following properties and hit **Save**
   ```
   topic name: big_bend_shoes
   stream name: big_bend_shoes
   ```
1. Re-activate the pipeline.
1. `big_bend_shoes` is now data as a product. Other team in your Confluent Cloud's organization can write consumers against this topic to create dashboards, apps, etc.
1. Next, we want to send promotional materials to our online users based on their order and browsing history on our website. To do so, we need do data enrichment.
1. We will use **Stream Catalog** to find the right clickstreams data.
1. Click on **Stream Catalog** search bar and search for `clickstreams_global` and click on the topic.
1. Click on **Schema** tab and expand the properties and apply **PII** tag to `IP_ADDRESS`.
1. Verify the tags and business metadata listed on the right hand-side are correct.
1. Go back to **Stream Designer** and step into your pipeline to continue adding more components.
1. Add a new **Topic** to the canvas and click on `configure` link in the topic box and click on **Configuration** tab and click on **Choose an existing topic instead**.
1. Select `clickstreams_global` from the list of topics and hit **Save**.
1. Click on `configure` link in the stream name and add the following properties and hit **Save**

   ```
   Name: clickstreams_global
   Key format: JSON
   Value format: JSON_SR
   Columns for the stream: IP_ADDRESS STRING, PAGE_URL STRING, PRODUCT_ID STRING , USER_ID STRING , VIEW_TIME INTEGER
   ```

1. Re-activate the pipeline.
1. Now we can do our data enrichment by doing a Stream-Stream join on `orders_stream` and `clickstreams_global`.
1. Initiate a join by clicking on the right edge of `orders_stream` and hit on **Join** from list of options.
1. Add the second stream by innitiating a connection from the right edge of `clickstreams_global` stream.
1. Create a new join with the following properties and hit **Save**
   ```
   query name: orders_clickstreams
   join name: orders_clickstreams
   left input source: orders_stream
   alias of the left: o
   input source: clickstreams_global
   alias of the input source: c
   join type: INNER
   join on clause: o.customer_id = c.user_id
   window duration: 1
   duration unit: HOUR
   grace period duration: 1
   grace period unit: MINUTE
   ```
1. Click on the right edge of the `Join` component and select **Stream** from the list and create a new Kafka topic and ksqlDB stream with the following properties and hit **Save**
   ```
   topic name: orders_enriched
   stream name: orders_enriched
   ```
1. Re-activate the pipeline.
1. The marketing team decided to use MongoDB Atlas as their cloud-native database and we can easily send `orders_enriched` stream to that database by leveraging our full-managed connector.
1. Click on the right edge of `orders_enriched` Kafka topic and hit on **Sink Connector**.
1. Look for and provision a MongoDB Atlas Sink Connector.
1. Re-activate the pipeline and once all components are activated verify the data is showing up in MongoDB database correctly.
   > For more information and detailed instructions refer to our [doc](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html)page.

### CONGRATULATIONS

Congratulations on building your streaming data pipeline with **Stream Designer**. Your complete pipeline should resemble the following one.
![Alt Text](complete-pipeline.gif)

## Code Import

1. You can build the entire demo by pasting the following code into the code editor.

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

Ensure all the resources that were created for the demo are deleted so you don't incur additional charges.

## References

Watch the [webinar](https://www.confluent.io/resources/online-talk/stream-designer-build-apache-kafka-r-pipelines-visually/) on demand!
