# AWS Glue Crawler - Lake Formation Configuration Guide

This guide provides step-by-step instructions to configure your Glue crawler to use Lake Formation credentials on the AWS Console.

**Reference:** [AWS Glue Crawler Lake Formation Integration](https://docs.aws.amazon.com/glue/latest/dg/crawler-lf-integ.html)

---

## Prerequisites

Before starting, ensure you have:
- Your S3 bucket name (raw data bucket) - check Terraform outputs
- Your Glue IAM role name (e.g., `aws-glue-csv-to-json-etl-glue-service-role`)
- Your Glue database name (e.g., `aws_glue_csv_to_json_etl_raw_data`)
- Administrator access to AWS Lake Formation and IAM

## Console Navigation Overview

**Lake Formation Console Structure:**
- **Data Catalog** → Databases, Tables and Materialized Views, Views, etc.
- **Crawlers** (Note: Crawlers are managed in AWS Glue Console, not Lake Formation)
- **Permissions** → Data permissions, LF-Tags and permissions, Hybrid access mode
- **Administration** → Administrative roles and tasks, **Data lake locations**, Application integration settings, etc.

**Quick Navigation Tips:**
- **Data lake locations** is under **Administration** section (not a top-level menu item)
- **Databases** are under **Data Catalog** section
- **Permissions** can be managed from multiple places (Data permissions section or from individual resource pages)
- **Crawlers** are configured in the **AWS Glue Console**, not Lake Formation

**Reference:** [Registering an Amazon S3 Location](https://docs.aws.amazon.com/lake-formation/latest/dg/register-location.html)

---

## Step 1: Register S3 Location in Lake Formation

1. Navigate to **AWS Lake Formation Console**
   - Go to: https://console.aws.amazon.com/lakeformation/
   - Sign in as the data lake administrator or as a user with the `lakeformation:RegisterResource` IAM permission
   - Select your region (e.g., `eu-west-1`)

2. Navigate to Data Lake Locations
   - In the left navigation pane, under **Administration**, select **Data lake locations**

3. Register the S3 Data Location
   - Click **Register location** button
   - Click **Browse** to select an Amazon S3 path, or manually enter:
     - **S3 path**: `s3://<your-raw-data-bucket-name>/`
     - Example: `s3://aws-glue-csv-to-json-etl-raw-data-bucket-xxxx/`
   
4. **(Optional, but strongly recommended)** Review Location Permissions
   - Select **Review location permissions** to view a list of all existing resources in the selected S3 location and their permissions
   - This helps ensure that existing data remains secure when registering the location
   - Review the list before proceeding

5. Select IAM Role
   - For **IAM role**, choose one of the following:
     - **Service-linked role**: `AWSServiceRoleForLakeFormationDataAccess` (default)
       - *Note: If you use the service-linked role, you cannot edit the location later. You would need to deregister and re-register.*
     - **Custom IAM role**: Select a custom IAM role that meets the requirements
       - *Note: Using a custom role allows you to update the location later*
   - The role must have permissions to access the S3 bucket

6. **(Optional)** Enable Data Catalog Federation
   - Check **Enable Data Catalog Federation** if you want Lake Formation to assume a role and vend temporary credentials to integrated AWS services to access tables under federated databases
   - This is required if you want to use the same location for tables under federated databases

7. **(Optional)** Enable Hybrid Access Mode
   - Check **Hybrid access mode** to not enable Lake Formation permissions by default
   - When enabled, you can enable Lake Formation permissions by opting in principals for databases and tables under that location
   - For most use cases, leave this unchecked (use standard Lake Formation permissions)

8. Complete Registration
   - Click **Register location**
   - Wait for the registration to complete

**Important Notes:**
- Avoid registering an S3 bucket that has **Requester pays** enabled
- For same-account crawling (which is our use case), the location should be in the same AWS account as the Data Catalog
- The data in the location should not be encrypted (for basic setup)

**Reference:** [Registering an Amazon S3 Location](https://docs.aws.amazon.com/lake-formation/latest/dg/register-location.html)

---

## Step 2: Grant Data Location Permissions to Glue IAM Role

1. In **Lake Formation Console**, navigate to **Permissions** → **Data permissions**
   - In the left navigation pane, under **Permissions**, choose **Data permissions**
   - Click **Grant** button

2. Configure the grant:
   - **Resource type**: Select **Data location**
   - **Data location**: Choose your registered S3 location from the dropdown
     - This will list all registered S3 locations in your account
     - Select the location you registered in Step 1 (e.g., `s3://aws-glue-csv-to-json-etl-raw-data-bucket-xxxx/`)
   - **IAM users and roles**: Select your Glue IAM role
     - Example: `aws-glue-csv-to-json-etl-glue-service-role`
   - **Permissions**: Select **Data location**
   - Click **Grant**

**Note:** 
- The Glue service IAM role needs **Data location** permission to read data from the registered S3 location.
- You can review existing permissions for a data location by going to **Administration** → **Data lake locations**, selecting the location, and using the **Review permissions** option. However, to grant new permissions, you must use the **Permissions** → **Data permissions** section as described above.

---

## Step 3: Grant Database Permissions to Glue IAM Role

1. In **Lake Formation Console**, navigate to **Data Catalog** → **Databases**
   - In the left navigation menu, expand **Data Catalog** section
   - Click **Databases**

2. Select your Glue database from the list (e.g., `aws_glue_csv_to_json_etl_raw_data`)

3. Grant permissions using one of these methods:
   
   **Method A: From Database Details Page**
   - Click on the database name to open it
   - Click **Actions** → **Grant** (or use the **Grant** button)
   
   **Method B: From Permissions Section**
   - In the left navigation, go to **Permissions** → **Data permissions**
   - Click **Grant**
   - Select **Database** as the resource type
   - Choose your database
   
4. Configure permissions:
   - **IAM users and roles**: Select your Glue IAM role
     - Example: `aws-glue-csv-to-json-etl-glue-service-role`
   - **Database permissions**: Select **Create**
   - **Grantable permissions**: (Optional) Select **Create** if you want to allow the role to grant permissions
   - Click **Grant**

---

## Step 4: Add Lake Formation Policy to IAM Role

1. Navigate to **IAM Console**
   - Go to: https://console.aws.amazon.com/iam/
   - Click **Roles** in the left navigation

2. Find and click your Glue service role
   - Example: `aws-glue-csv-to-json-etl-glue-service-role`

3. Add Lake Formation permission:
   - Click **Add permissions** → **Create inline policy**
   - Click **JSON** tab
   - Paste the following policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "lakeformation:GetDataAccess"
         ],
         "Resource": "*"
       }
     ]
   }
   ```
   - Click **Next**
   - **Policy name**: `GlueLakeFormationAccess`
   - Click **Create policy**

---

## Step 5: Configure Crawler to Use Lake Formation Credentials

1. Navigate to **AWS Glue Console**
   - Go to: https://console.aws.amazon.com/glue/
   - Select your region

2. Open your Crawler
   - Click **Crawlers** in the left navigation
   - Find and click your crawler (e.g., `aws-glue-csv-to-json-etl-csv-crawler`)

3. Edit Crawler Configuration
   - Click **Edit** button
   - Scroll to **Security configuration, encryption, and Lake Formation access** section

4. Enable Lake Formation
   - Find **Lake Formation** section
   - Check the box: **Use Lake Formation credentials for crawling Amazon S3 data source**
   - **Account ID**: (Optional for same-account crawling) Leave empty or enter your AWS account ID
   - Click **Next** through the remaining steps
   - Click **Save** to save the crawler configuration

---

## Step 6: Verify Configuration

1. **Test the Crawler**
   - In the Glue Console, select your crawler
   - Click **Run crawler**
   - Monitor the run in **Runs** tab
   - Check CloudWatch logs if there are any errors

2. **Verify Tables Created**
   - In **Lake Formation Console**, go to **Data Catalog** → **Tables and Materialized Views**
   - Or in **AWS Glue Console**, go to **Databases** → Select your database
   - Verify that tables with prefix `raw_` are created
   - Check table schema and data location

---

## Troubleshooting

### Common Issues:

1. **"Access Denied" errors**
   - Verify IAM role has `lakeformation:GetDataAccess` permission
   - Check that data location permissions are granted in Lake Formation
   - Ensure database permissions include "Create" for the IAM role

2. **Crawler fails to discover data**
   - Verify S3 bucket path is correctly registered in Lake Formation
   - Check that the IAM role has S3 read permissions
   - Ensure the S3 bucket exists and contains data files

3. **Lake Formation option not available**
   - Ensure you're using a supported AWS region
   - Verify Lake Formation is enabled in your account
   - Check that you have proper permissions to modify the crawler

---

## Additional Notes

- **Same Account vs Cross-Account**: These steps are for same-account crawling. For cross-account, additional configuration is required.
- **IAM Role**: The Glue service role must have both IAM permissions and Lake Formation permissions.
- **Data Catalog**: The crawler will create tables in the Glue Data Catalog with Lake Formation managed permissions.

---

## Terraform Integration

If you want to automate this configuration via Terraform, you would need to:

1. Add `lake_formation_configuration` block to the `aws_glue_crawler` resource
2. Add `lakeformation:GetDataAccess` to the IAM role policy
3. Create Lake Formation data location and permissions resources

Example Terraform configuration:
```hcl
resource "aws_glue_crawler" "csv_crawler" {
  # ... existing configuration ...
  
  lake_formation_configuration {
    use_lake_formation_credentials = true
    account_id                     = null  # Optional for same-account
  }
}
```

---

## Important Considerations

### IAM Role Selection for Location Registration

When registering a location, you have two options:

1. **Service-Linked Role** (`AWSServiceRoleForLakeFormationDataAccess`)
   - Default option, easier to set up
   - **Limitation**: Cannot edit the location after registration
   - To make changes, you must deregister and re-register

2. **Custom IAM Role**
   - More flexible, allows updates to the location
   - Must meet specific requirements (see AWS documentation)
   - Recommended if you need to modify the location later

**Recommendation:** For this setup, you can use the service-linked role unless you anticipate needing to update the location configuration.

### Requirements for Roles Used to Register Locations

The IAM role used to register a location must have:
- Permissions to access the S3 bucket (read/list)
- Trust relationship allowing Lake Formation to assume the role
- Appropriate IAM policies for S3 access

---

## References

- [AWS Glue Crawler Lake Formation Integration](https://docs.aws.amazon.com/glue/latest/dg/crawler-lf-integ.html)
- [Registering an Amazon S3 Location](https://docs.aws.amazon.com/lake-formation/latest/dg/register-location.html)
- [Granting Data Location Permissions](https://docs.aws.amazon.com/lake-formation/latest/dg/granting-data-location-permissions.html)
- [Requirements for Roles Used to Register Locations](https://docs.aws.amazon.com/lake-formation/latest/dg/register-location.html#register-location-requirements)