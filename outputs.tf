output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.my_subnet[*].id
}

output "ec2_instance_details" {
  value = aws_instance.my_ec2_instance
}

output "rds_endpoint" {
  value = aws_db_instance.my_rds.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_s3_bucket.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.my_dynamodb_table.name
}