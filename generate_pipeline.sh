#!/bin/bash

sleep_time=2
output="pipeline.sql"
template="pipeline_template.sql"
env_file=".env"

# Create the entire pipeline in one command
pipeline_code="CREATE SOURCE CONNECTOR \"SqlServerCdcSourceConnector_0\" WITH (
\"after.state.only\"='true',
\"connector.class\"='SqlServerCdcSource',
\"database.dbname\"='public',
\"database.hostname\"='sql-server',
\"database.password\"='db-sd-c0nflu3nt!',
\"database.port\"='1433',
\"database.server.name\"='sql',
\"database.user\"='admin',
\"kafka.api.key\"='api-key',
\"kafka.api.secret\"='api-secret',
\"kafka.auth.mode\"='KAFKA_API_KEY',
\"max.batch.size\"='1',
\"output.data.format\"='JSON_SR',
\"output.key.format\"='JSON',
\"poll.interval.ms\"='1',
\"snapshot.mode\"='initial',
\"table.include.list\"='dbo.products, dbo.orders',
\"tasks.max\"='1'
);
CREATE OR REPLACE STREAM \"orders_stream\" (CUSTOMER_ID STRING, ORDER_ID STRING KEY, PRODUCT_ID STRING, PURCHASE_TIMESTAMP STRING)
WITH (kafka_topic='sql.dbo.orders', partitions=1, key_format='JSON', value_format='JSON_SR');

CREATE OR REPLACE STREAM \"clickstreams_global\" (IP_ADDRESS STRING, PAGE_URL STRING, PRODUCT_ID STRING , USER_ID STRING , VIEW_TIME INTEGER )
WITH (kafka_topic='clickstreams_global', partitions=1, key_format='JSON', value_format='JSON_SR');

CREATE OR REPLACE STREAM \"orders_enriched\"
WITH (kafka_topic='orders_enriched', partitions=1, value_format='JSON_SR')
AS SELECT * FROM \"orders_stream\" o INNER JOIN \"clickstreams_global\" c
   WITHIN 1 HOUR GRACE PERIOD 1 MINUTE
ON o.customer_id = c.user_id;

CREATE OR REPLACE STREAM \"products_stream\" (PRODUCT_ID STRING KEY, PRODUCT_NAME STRING, PRODUCT_RATING DOUBLE, SALE_PRICE INTEGER)
WITH (kafka_topic='sql.dbo.products', partitions=1, key_format='JSON', value_format='JSON_SR');

CREATE OR REPLACE TABLE \"products_table\"
WITH (kafka_topic='products_table', partitions=1, key_format='JSON', value_format='JSON_SR') AS
   SELECT EXTRACTJSONFIELD(PRODUCT_ID, '\$.product_id') AS PRODUCT_ID,
      LATEST_BY_OFFSET(PRODUCT_NAME) AS PRODUCT_NAME,
      LATEST_BY_OFFSET(PRODUCT_RATING) AS PRODUCT_RATING,
      LATEST_BY_OFFSET(SALE_PRICE) AS SALE_PRICE
   FROM \"products_stream\"
   GROUP BY EXTRACTJSONFIELD(PRODUCT_ID, '\$.product_id');

CREATE OR REPLACE STREAM \"orders_stream_productid_rekeyed\"
WITH (kafka_topic='orders_stream_productid_rekeyed', partitions=1, key_format='JSON', value_format='JSON_SR') AS
   SELECT CUSTOMER_ID,
      EXTRACTJSONFIELD(ORDER_ID, '\$.order_id') AS ORDER_ID,
      PRODUCT_ID,
      PURCHASE_TIMESTAMP
   FROM \"orders_stream\"
   PARTITION BY PRODUCT_ID;

CREATE OR REPLACE STREAM \"orders_and_products\"
WITH (kafka_topic='orders_and_products', partitions=1, key_format='JSON', value_format='JSON_SR') AS
   SELECT *
   FROM \"orders_stream_productid_rekeyed\" O
      INNER JOIN \"products_table\" P
      ON O.PRODUCT_ID = P.PRODUCT_ID;

CREATE OR REPLACE STREAM \"big_bend_shoes\"
WITH (kafka_topic='big_bend_shoes', partitions=1, key_format='JSON', value_format='JSON_SR') AS
   SELECT *
   FROM \"orders_and_products\"
   WHERE LCASE(P_PRODUCT_NAME) LIKE '%big bend shoes%';

CREATE SINK CONNECTOR \"MongoDbAtlasSinkConnector_0\" WITH (
\"connection.host\"='mongodb-endpoint',
\"connection.password\"='db-sd-c0nflu3nt!',
\"connection.user\"='admin',
\"connector.class\"='MongoDbAtlasSink',
\"database\"='demo-stream-designer',
\"input.data.format\"='JSON_SR',
\"kafka.api.key\"='api-key',
\"kafka.api.secret\"='api-secret',
\"kafka.auth.mode\"='KAFKA_API_KEY',
\"tasks.max\"='1',
\"topics\"='orders_enriched'
);"

# Redirect the pipeline_template to a new file while preserving quotes
echo "$pipeline_code" > $template

# Copy the content of the template to the output file. This is the file that will be used to create the pipeline. 
#The repo igonres pipeline.sql since it has sensitive information.
cp $template $output

# Sleep for a few seconds
sleep $sleep_time

# use grep to extract relevant values and sed to replace the values in the file
ccloud_api_key_value=$(grep -E "^CCLOUD_API_KEY=" "$env_file" | cut -d '=' -f 2| sed 's/"//g')
ccloud_api_secret_value=$(grep -E "^CCLOUD_API_SECRET=" "$env_file" | cut -d '=' -f 2| sed 's/"//g')
sql_server=$(grep -E "^SQL_SERVER=" "$env_file" | cut -d '=' -f 2| sed 's/"//g')
mongodb_endpoint=$(grep -E "^MONGO_ENDPOINT=" "$env_file" | cut -d '=' -f 2| sed 's/"//g')

sed -i .bak "s^api-key^$ccloud_api_key_value^g" $output
sed -i .bak "s^api-secret^$ccloud_api_secret_value^g" $output
sed -i .bak "s^sql-server^$sql_server^g" $output
sed -i .bak "s^mongodb-endpoint^$mongodb_endpoint^g" $output