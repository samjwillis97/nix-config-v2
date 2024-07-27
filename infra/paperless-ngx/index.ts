import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";

// Create an AWS resource (S3 Bucket)
const documentBucket = new aws.s3.Bucket("document-storage");
const postgresBackupBucket = new aws.s3.Bucket("document-storage");

// Export the name of the bucket
export const documentBucketName = documentBucket.id;
export const postgresBackupBucketName = postgresBackupBucket.id;
