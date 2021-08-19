import os
import boto3
import json
import botocore
import argparse

# Since every user gets their own namespace, we'll be using the same base name
# for all the buckets. If you're using shared infrastructure, pick a unique
# value for this.
bucket_base_name = os.getenv('BASE_BUCKET_NAME')

# Our access key and id were entered as environment variables earlier in the
# lab.
aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')

print("Access Key Id: %s"% (aws_access_key_id,))
print("Access Key: %s"% (aws_secret_access_key,))

# This value was defined when we created our Data Hub instance. Environment
# variables can be predefined as a part of the KFDef.
endpoint_url = os.getenv('S3_ENDPOINT_URL')

print("S3 Endpoint: %s"% (endpoint_url,))

s3 = boto3.client('s3', '',
                endpoint_url = os.getenv('S3_ENDPOINT_URL'),
                aws_access_key_id = aws_access_key_id,
                aws_secret_access_key = aws_secret_access_key,
                config=botocore.client.Config(signature_version = 's3'))

def create_bucket(bucket_name):
    result = s3.create_bucket(Bucket=bucket_name)
    return result

create_bucket(bucket_base_name)
create_bucket(bucket_base_name+'-processed')
create_bucket(bucket_base_name+'-anonymized')

for bucket in s3.list_buckets()['Buckets']:
    print(bucket['Name'])

for bucket in s3.list_buckets()['Buckets']:
    bucket_policy = {
                      "Version":"2012-10-17",
                      "Statement":[
                        {
                          "Sid":"AddPerm",
                          "Effect":"Allow",
                          "Principal": "*",
                          "Action":["s3:GetObject"],
                          "Resource":["arn:aws:s3:::{0}/*".format(bucket['Name'])]
                        }
                      ]
                    }
    bucket_policy = json.dumps(bucket_policy)
    s3.put_bucket_policy(Bucket=bucket['Name'], Policy=bucket_policy)