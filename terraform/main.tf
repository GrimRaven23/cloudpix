provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  common_tags = {
    Project     = "CloudPix"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 BUCKETS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "original_images" {
  bucket = "cloudpix-original-${random_id.bucket_suffix.hex}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_cors_configuration" "original_images_cors" {
  bucket = aws_s3_bucket.original_images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] 
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "processed_images" {
  bucket = "cloudpix-processed-${random_id.bucket_suffix.hex}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_cors_configuration" "processed_images_cors" {
  bucket = aws_s3_bucket.processed_images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "website" {
  bucket = "cloudpix-web-${random_id.bucket_suffix.hex}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  depends_on = [aws_s3_bucket_public_access_block.website_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  name = "cloudpix_lambda_role_${random_id.bucket_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "cloudpix_lambda_policy_${random_id.bucket_suffix.hex}"
  description = "IAM policy for CloudPix Lambda to access S3 and CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.original_images.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.processed_images.arn}",
          "${aws_s3_bucket.processed_images.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA FUNCTIONS
# ---------------------------------------------------------------------------------------------------------------------

# 1. Image Processor (Triggered by S3)
resource "aws_lambda_function" "image_processor" {
  filename      = "../lambda/function.zip"
  function_name = "CloudPixProcessor-${random_id.bucket_suffix.hex}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "image_processor.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  environment {
    variables = {
      PROCESSED_BUCKET_NAME = aws_s3_bucket.processed_images.id
    }
  }

  source_code_hash = fileexists("../lambda/function.zip") ? filebase64sha256("../lambda/function.zip") : null
}

# 2. List Images (Called by Frontend)
resource "aws_lambda_function" "list_images" {
  filename      = "../lambda/function.zip"
  function_name = "CloudPixLister-${random_id.bucket_suffix.hex}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "list_images.lambda_handler"
  runtime       = "python3.11"
  timeout       = 10

  environment {
    variables = {
      PROCESSED_BUCKET_NAME = aws_s3_bucket.processed_images.id
      REGION                = "us-east-1"
    }
  }

  source_code_hash = fileexists("../lambda/function.zip") ? filebase64sha256("../lambda/function.zip") : null
}

resource "aws_lambda_function_url" "list_images_url" {
  function_name      = aws_lambda_function.list_images.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 TRIGGER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.original_images.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.original_images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".png"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
