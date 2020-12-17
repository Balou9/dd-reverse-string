// Backend configuration
terraform {

  backend "remote" {
    organization = "etoo"

    workspaces {
      name = "dd-reverse-strings"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
// Declare variables set by github actions workflow

variable "stack_name" {

  type = string
  description = "The stack-name"

}

// Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "dd-reverse-strings-oai"
}

// Bucket
resource "aws_s3_bucket" "bucket" {
  tags = {
    Key   = "dd-reverse-string:name"
    Value = "dd-reverse-string"
  }
  bucket = "${var.stack_name}-bucket"
}

// Bucket Policy
data "aws_iam_policy_document" "bucket_policy_document" {

  statement {
    sid    = "AllowOriginAccesIdentity"
    effect = "allow"
    principals {
      type        = "CanonicalUser"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id]
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
    ]
  }

  statement {
    sid    = "AllowReverseStringHandlerGetObject"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"]
  }

  statement {
    sid    = "AllowReverseStringHandlerPutObject"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"]
  }

  statement {
    sid    = "AllowReverseStringHandlerListBucket"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.bucket}"]
  }

}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy_document.id
}


data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    sid    = "AllowAssumeRoleByLambda"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

// LambdaExecutionRole
resource "aws_iam_role" "role" {
  name               = "ReverseStringHandlerExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
}


data "aws_iam_policy_document" "reverse_string_handler_execution_policy" {

  statement {
    sid    = "AllowLogCreation"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid       = "AllowS3GetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"]
  }

  statement {
    sid       = "AllowS3PutObject"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"]
  }

  statement {
    sid       = "AllowS3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.bucket}"]
  }

}
// LambdaExecutionPolicy
resource "aws_iam_policy" "policy" {
  name   = "ReverseStringHandlerExecutionPolicy"
  policy = data.aws_iam_policy_document.reverse_string_handler_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_lambda_function" "reverse_string_handler" {
  filename      = "dummy.zip"
  function_name = "${var.stack_name}-handler"
  role          = aws_iam_role.role.arn
  handler       = "exports.handler"
  runtime       = "nodejs12.x"
}
