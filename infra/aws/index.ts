import * as aws from "@pulumi/aws";

// Create an AWS resource (S3 Bucket)
const paperlessDocuementBucket = new aws.s3.Bucket("document-storage");
const paperlessSqliteBackupBucket = new aws.s3.Bucket("paperless-pgsql-backup");
const mediaserverPostgresBackupBucket = new aws.s3.Bucket("mediaserver-pgsql-backup")

// Export the name of the bucket
export const paperlessDocumentBucketName = paperlessDocuementBucket.id;
export const paperlessSqliteBackupBucketName = paperlessSqliteBackupBucket.id;
export const mediaserverPostgresBackupBucketName = mediaserverPostgresBackupBucket.id;
