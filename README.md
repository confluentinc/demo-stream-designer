# Current 2022 Confluent Keynote Demo

Internal repo for Current 2022 Confluent Keynote Demo covering Stream Designer, Stream Sharing, and Stream Catalog.

## Setup

## Set up Confluent Cloud

1. Sign up for a Confluent Cloud account [here](https://www.confluent.io/get-started/).
1. After verifying your email address, access Confluent Cloud sign-in by navigating [here](https://confluent.cloud).
1. When provided with the _username_ and _password_ prompts, fill in your credentials.

   > **Note:** If you're logging in for the first time you will see a wizard that will walk you through the some tutorials. Minimize this as you will walk through these steps in this guide.

1. Click **+ Add environment**.

   > **Note:** There is a _default_ environment ready in your account upon account creation. You can use this _default_ environment for the purpose of this demo if you do not wish to create an additional environment.

   - Specify a meaningful `name` for your environment and then click **Create**.
     > **Note:** It will take a few minutes to assign the resources to make this new environment available for use.

1. Now that you have an environment, let's create a cluster. Select **Create Cluster**.

   > **Note**: Confluent Cloud clusters are available in 3 types: **Basic**, **Standard**, and **Dedicated**. Basic is intended for development use cases so you should use that for this demo. Basic clusters only support single zone availability. Standard and Dedicated clusters are intended for production use and support Multi-zone deployments. If you’re interested in learning more about the different types of clusters and their associated features and limits, refer to this [documentation](https://docs.confluent.io/current/cloud/clusters/cluster-types.html).

   - Choose the **Basic** cluster type.

   - Click **Begin Configuration**.

   - Choose **AWS** as your Cloud Provider and your preferred Region. In this demo we use Oregon (West2) as the region.

   - Specify a meaningful **Cluster Name** and then review the associated _Configuration & Cost_, _Usage Limits_, and _Uptime SLA_ before clicking **Launch Cluster**.

### Create an API key pair

1. Select API keys on the navigation menu.
1. If this is your first API key within your cluster, click **Create key**. If you have set up API keys in your cluster in the past and already have an existing API key, click **+ Add key**.
1. Select **Global Access**, then click Next.
1. Save your API key and secret - you will need these during the demo.
1. After creating and saving the API key, you will see this API key in the Confluent Cloud UI in the API keys tab. If you don’t see the API key populate right away, refresh the browser.

### Enable Schema Registery

1. On the navigation menu, select **Schema Registery**.
1. Click **Set up on my own**.
1. Choose **AWS** as the cloud provider and a supported **Region**
1. Click on **Enable Schema Registry**.

## Setup SQL Server

1. This demo uses a Microsoft SQL Server Standard Edition hosted on AWS. Change Data Capture (CDC) is only Enterprise, Developer, Enterprise Evaluation, and Standard editions, so ensure you choose a configuration that supports CDC.
1. This demo uses Amazon RDS Microsoft SQL Server that is publicly accessible. If your database is in a VPC, follow the instructions on our [doc](https://docs.confluent.io/cloud/current/networking/peering/aws-peering.html) page.
1. Navigate to https://aws.amazon.com/console/ and log into your account.
1. Search for **RDS** and click on results.
1. Click on **Create database** and create an Microsoft SQL Server database using the following configurations and leave everything else as default.
   ```bash
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

## Demo

## Teardown

## References
