output "original_bucket_name" {
  value = aws_s3_bucket.original_images.id
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed_images.id
}

output "website_bucket_name" {
  value = aws_s3_bucket.website.id
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}"
}

output "api_url" {
  value = aws_lambda_function_url.list_images_url.function_url
}

output "region" {
  value = "us-east-1"
}
