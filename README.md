Data pipelines continue to do the heavy-lifting in data integration. In order to immediately act on insights, companies turn to Apache Kafka® to replace legacy, batch-based pipelines with streaming data pipelines. There are still major challenges with building reusable data pipelines on open-source Kafka, like an overreliance on specialized Kafka engineering talent and cumbersome development cycles. These bottlenecks limit the speed at which teams can set data in motion.

Confluent’s Stream Designer is a new visual canvas for rapidly building, testing, and deploying streaming data pipelines powered by Kafka. You can quickly and easily build pipelines graphically or with SQL, leveraging built-in integrations with fully managed connectors, ksqlDB for stream processing, and Kafka topics.
This demo walks you through building streaming data pipelines in minute!

Watch the [demo](https://youtu.be/vc3od1KLU_0?t=1538) during Current 2022 keynote: Reimagining Data Pipelines for the Streaming Era.

---

# Architecture Diagram

This demo uses two data sources (Microsoft SQL Server database and clickstream data through a Python publisher) and streams enriched data to two destinations (MongoDB Atlas database and a different organization through Stream Sharing).

<div align="center"> 
  <img src="images/arch_diagram.png" width =100% heigth=100%>
</div>

---

# Requirements

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
- Download and Install Terraform [here](https://developer.hashicorp.com/terraform/downloads?ajs_aid=837a4ee4-253b-4b3d-bf11-952575792ad1&product_intent=terraform)

  > **Note:** This demo was built and validate on a Mac (x86).

# Prerequisites

## Confluent Cloud

1. Sign up for a Confluent Cloud account [here](https://www.confluent.io/get-started/).
1. After verifying your email address, access Confluent Cloud sign-in by navigating [here](https://confluent.cloud).
1. When provided with the _username_ and _password_ prompts, fill in your credentials.

   > **Note:** If you're logging in for the first time you will see a wizard that will walk you through the some tutorials. Minimize this as you will walk through these steps in this guide.

1. Create Confluent Cloud API keys by following [this](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/guides/sample-project#summary) guide.
   > **Note:** This is different than Kafka cluster API keys.

## SQL Server

1. This demo uses a Microsoft SQL Server Standard Edition hosted on AWS. Change Data Capture (CDC) is only supported on Enterprise, Developer, Enterprise Evaluation, and Standard editions.

1. This demo uses Amazon RDS Microsoft SQL Server that is publicly accessible.

1. Download and install Microsoft ODBC driver for your operating system from [here](https://docs.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server?view=sql-server-ver15).

## MongoDB Atlas

1. Sign up for a free MongoDB Atlas account [here](https://www.mongodb.com/).

1. Create an API key pair so Terraform can create resources in the Atlas cluster. Follow the instructions [here](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#configure-atlas-programmatic-access).

# Setup

1. Clone and enter this repository.

   ```bash
   git clone https://github.com/confluentinc/demo-stream-designer.git
   cd demo-stream-designer
   ```

1. Create an `.accounts` file by running the following command.

   ```bash
   echo "CONFLUENT_CLOUD_EMAIL=add_your_email\nCONFLUENT_CLOUD_PASSWORD=add_your_password\nexport TF_VAR_confluent_cloud_api_key=\"add_your_api_key\"\nexport TF_VAR_confluent_cloud_api_secret=\"add_your_api_secret\"\nexport TF_VAR_mongodbatlas_public_key=\"add_your_public_key\"\nexport TF_VAR_mongodbatlas_private_key=\"add_your_private_key\"\nexport TF_VAR_mongodbatlas_org_id=\"add_your_org_id\"" > .accounts
   ```

   > **Note:** This repo ignores `.accounts` file

1. Update the `.accounts` file for the following variables with your credentials.

   ```bash
   CONFLUENT_CLOUD_EMAIL=<replace>
   CONFLUENT_CLOUD_PASSWORD=<replace>
   export TF_VAR_confluent_cloud_api_key="<replace>"
   export TF_VAR_confluent_cloud_api_secret="<replace>"
   export TF_VAR_mongodbatlas_public_key="<replace>"
   export TF_VAR_mongodbatlas_private_key="<replace>"

   ```

1. Navigate to the home directory of the project and run `create_env.sh` script. This bash script copies the content of `.accounts` file into a new file called `.env` and append additional variables to it.

   ```bash
   cd demo-stream-designer
   ./create_env.sh
   ```

1. Source `.env` file.

   ```bash
   source .env
   ```

   > **Note:**: if you don't source `.env` file you'll be prompted to manually provide the values through command line when running Terraform commands.

## Build your cloud infrastructure

1. Navigate to the repo's terraform directory.
   ```bash
   cd terraform
   ```
1. Log into your AWS account through command line.

1. Initialize Terraform within the directory.
   ```bash
   terraform init
   ```
1. Create the Terraform plan.
   ```bash
   terraform plan
   ```
1. Apply the plan to create the infrastructure.

   ```bash
   terraform apply
   ```

   > **Note:** Read the `main.tf` configuration file [to see what will be created](./terraform/main.tf).

1. Write the output of `terraform` to a JSON file. The `setup.sh` script will parse the JSON file to update the `.env` file.

   ```bash
   terraform output -json > ../resources.json
   ```

1. Run the `setup.sh` script.

   ```bash
   cd demo-stream-designer
   ./setup.sh
   ```

1. This script achieves the following:

   - Creates an API key pair that will be used in connectors' configuration files for authentication purposes.
   - Creates an API key pair for Schema Registry
   - Creates Tags and business metadata
   - Updates the `.env` file to replace the remaining variables with the newly generated values.

1. Source `.env` file.

   ```bash
   source .env
   ```

## Prepare the Database for Change Data Capture

1. Run the script to enable change data capture (CDC) on all tables of the database
   ```bash
   cd demo-stream-designer/sql_scripts
   python3 prepare_sqlserver.py
   ```

## Prepare streams

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

# Demo

1. Open a Terminal window and run the script to create new clickstreams data.

   ```bash
   cd demo-stream-designer/clickstreams_scripts
   python3 produce_clickstream.py
   ```

1. Open a second Terminal window and run the script to create new purchase orders.

   ```bash
   cd demo-stream-designer/sql_scripts
   python3 produce_orders.py
   ```

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

   ```bash
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
   ```bash
   query name: shoes
   filter name: shoes
   filter expression: LCASE(P_PRODUCT_NAME) LIKE '%big bend shoes%'
   ```
1. Click on the right edge of **Filter** component and create a new Kafka topic and ksqlDB stream with the following properties and hit **Save**
   ```bash
   topic name: big_bend_shoes
   stream name: big_bend_shoes
   ```
1. Re-activate the pipeline.
1. `big_bend_shoes` is now data as a product. We can share this stream with our partner retailers so they can see how their products are performing in our stores. We will use **Stream Sharing** to do that.

<details>
   <summary><b>Stream Sharing</b></summary>

1. Click on `big_bend_shoes` topic and then click on **+Share** icon on the top right corner of side panel.
1. Enter a valid recipient email address and double check to see `big_bend_shoes-value` is the selected schema subject.
1. Hit the **Invite** button.
1. The recipient can access the shared stream through the **Access** button in their email.
1. Next, they pick the client and download a configuration file.
1. Now they can use the configuration file and their consumer application to consume from the shared topic.
1. In this demo we use `kafka-console-consumer` from Confluent Platform. An example of configuration file is provided in [file](stream_sharing/client.properties.example).
1. Open a new terminal and run the following command to start consuming

   ```bash
   kafka-console-consumer --consumer.config stream_sharing/client.properties --topic big_bend_shoes --from-beginning --bootstrap-server <REPLACE-WITH-YOUR-BOOSTRAP-SERVER>
   ```

</details>
<br>

1. Next, we want to send promotional materials to our online users based on their order and browsing history on our website. To do so, we need do data enrichment.
1. We will use **Stream Catalog** to find the right clickstreams data.
1. Click on **Stream Catalog** search bar and search for `clickstreams_global` and click on the topic.
1. Click on **Schema** tab and expand the properties and apply **PII** tag to `IP_ADDRESS`.
1. Verify the tags and business metadata listed on the right hand-side are correct.
1. Go back to **Stream Designer** and step into your pipeline to continue adding more components.
1. Add a new **Topic** to the canvas and click on `configure` link in the topic box and click on **Configuration** tab and click on **Choose an existing topic instead**.
1. Select `clickstreams_global` from the list of topics and hit **Save**.
1. Click on `configure` link in the stream name and add the following properties and hit **Save**

   ```bash
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
   ```bash
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
   ```bash
   topic name: orders_enriched
   stream name: orders_enriched
   ```
1. Re-activate the pipeline.
1. The marketing team decided to use MongoDB Atlas as their cloud-native database and we can easily send `orders_enriched` stream to that database by leveraging our full-managed connector.
1. Click on the right edge of `orders_enriched` Kafka topic and hit on **Sink Connector**.
1. Look for and provision a MongoDB Atlas Sink Connector.
1. Re-activate the pipeline and once all components are activated verify the data is showing up in MongoDB database correctly.
   > For more information and detailed instructions refer to our [doc](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html) page.

# Congratulations!

Congratulations on building your streaming data pipeline with **Stream Designer**. Your complete pipeline should resemble the following one.
![Alt Text](images/complete-pipeline.gif)

# Code Import

1. You can build the entire demo by pasting the complete ksqlDB code directly into the code editor. To do so, run

   ```bash
   cd demo-stream-designer
   ./generate_pipeline.sh
   ```

1. The `generate_pipeline.sh` first creates a `pipeline_template.sql` file which doesn't include your credentials (such as Kafka API keys, database endpoints, etc). Then, it creates the `pipeline.sql` and update the credentials using the `.env` file.

   > **Note**: This repo ignores `pipeline.sql`.

1. Copy the content of `pipeline.sql` and paste into Code Import and hit **Apply Changes** and then **Activate**.

# Teardown

Ensure all the resources that were created for the demo are deleted so you don't incur additional charges.

1. The following script will de-activate and delete the pipeline. Note that doing so, will delete your topics and you can't restore them afterwards.
   ```bash
   cd demo-stream-designer
   ./teardown_pipeline.sh
   ```
2. You can delete the rest of the resources that were created during this demo by executing the following command.
   ```bash
   Terraform apply -destory
   ```

# References

1. Watch the [webinar](https://www.confluent.io/resources/online-talk/stream-designer-build-apache-kafka-r-pipelines-visually/) on demand!

1. Terraform guides
   - Confluent Cloud https://registry.terraform.io/providers/confluentinc/confluent/latest/docs
   - Amazon RDS https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
   - MongoDB Atlas https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs
