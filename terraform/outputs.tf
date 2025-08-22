output "instance_ip" {
  value = aws_instance.label_studio_server.public_ip
}

output "s3_bucket_id" {
  value = aws_s3_bucket.label_studio_bucket.id
}
