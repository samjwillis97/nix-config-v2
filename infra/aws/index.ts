import * as aws from "@pulumi/aws";

// Create an AWS resource (S3 Bucket)
const paperlessDocuementBucket = new aws.s3.Bucket("document-storage");
const paperlessSqliteBackupBucket = new aws.s3.Bucket("paperless-pgsql-backup");
const mediaserverPostgresBackupBucket = new aws.s3.Bucket("mediaserver-pgsql-backup", {
})

new aws.s3.BucketLifecycleConfigurationV2("mediaserver-pgsql-backup-lifecycle-rule", {
  bucket: mediaserverPostgresBackupBucket.id,
  rules: [{
    id: "deleteAfter90Days",
    status: "Enabled",
    expiration: {
      days: 90,
    },
    // An empty filter applies the rule to all objects in the bucket.
    filter: {},
  }],
});


// Export the name of the bucket
export const paperlessDocumentBucketName = paperlessDocuementBucket.id;
export const paperlessSqliteBackupBucketName = paperlessSqliteBackupBucket.id;
export const mediaserverPostgresBackupBucketName = mediaserverPostgresBackupBucket.id;
