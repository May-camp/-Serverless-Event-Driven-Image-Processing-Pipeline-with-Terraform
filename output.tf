output "source_bucket_name" {
   value = aws_s3_bucket.source_bucket.bucket
}

output "dest_bucket_name" {
   value = aws_s3_bucket.dest_bucket.bucket
}