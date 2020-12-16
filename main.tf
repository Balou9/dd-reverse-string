// Declare variables set by github actions workflow

provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "dd-reverse-strings-oai"
}

// Bucket
resource "aws_s3_bucket" "bucket" {
  tags = {
    Key   = "dd-reverse-string:name"
    Value = "dd-reverse-string"
  }
  bucket = "${var.s3_bucket_name}-bucket"
}

data "aws_iam_policy_document" "bucket_policy_document" {

  statement {
    sid = "AllowOriginAccesIdentity"
    effect = "allow"
    principals = {
      "CanonicalUser": aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    sid = "AllowReverseStringHandlerGetObject"
    effect = "allow"
    principals = {
      "AWS": aws_lambda_function.reverse_string_handler.arn
    }
    actions = [ "s3:GetObject" ]
    resources = [ "arn:aws:s3:::${var.s3_bucket_name}/*" ]
  }

  statement {
    sid = "AllowReverseStringHandlerPutObject"
    effect = "allow"
    principals = {
      "AWS": aws_lambda_function.reverse_string_handler.arn
    }
    actions = [ "s3:PutObject" ]
    resources = [ "arn:aws:s3:::${var.s3_bucket_name}/*" ]
  }

  statement {
    sid = "AllowReverseStringHandlerListBucket"
    effect = "allow"
    principals = {
      "AWS": aws_lambda_function.reverse_string_handler.arn
    }
    actions = [ "s3:ListBucket" ]
    resources = [ "arn:aws:s3:::${var.s3_bucket_name}" ]
  }

}

// Bucket Policy
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = aws_iam_policy_document.bucket_policy_document.id
}

// LambdaExecutionRole
resource "aws_iam_role" "role" {
  name               = "ReverseStringHandlerExecutionrole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// LambdaExecutionPolicy
resource "aws_iam_policy" "policy" {
  name   = "ReverseStringHandlerExecutionPolicy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLogCreation",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Sid": "AllowS3GetObject",
      "Effect": "Allow",
      "Action": [ "s3:GetObject" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}/*"
    },
    {
      "Sid": "AllowS3PutObject",
      "Effect": "Allow",
      "Action": [ "s3:PutObject" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}/*"
    },
    {
      "Sid": "AllowS3ListBucket",
      "Effect": "Allow",
      "Action": [ "s3:ListBucket" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}"
    }
  ]
}
EOF
}

# resource "aws_iam_role_policy_attachment" "attach_reverseStringHandlerPolicy" {
#   role       = aws_iam_role.role.name
#   policy_arn = aws_iam_policy.policy.arn
# }
# 
# resource "aws_lambda_function" "reverse_string_handler" {
#   filename      = "lambda_function_payload.zip"
#   function_name = "lambda_function_name"
#   role          = aws_iam_role.iam_for_lambda.arn
#   handler       = "exports.test"
#
#   # # The filebase64sha256() function is available in Terraform 0.11.12 and later
#   # # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
#   # # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
#   # source_code_hash = filebase64sha256("lambda_function_payload.zip")
#
#   runtime = "nodejs12.x"
#
#   environment {
#     variables = {
#
#     }
#   }
# }
