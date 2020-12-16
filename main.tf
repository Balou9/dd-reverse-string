// Backend configuration
terraform {
  backend "remote" {
    organization = "etoo"

    workspaces {
      name = "dd-reverse-strings"
    }
  }
}

// Declare variables set by github actions workflow
variable "s3_bucket_name" {
  type        = string
  description = "The name of the s3 bucket"
  default = "reverse_string_bucket"
}

variable "reverse_string_handler_name" {
  type        = string
  description = "The lambda function name of the 'reverse string' handler"
  default = "reverse_string_handler"

}

provider "aws" {
  region = "us-east-1"
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
  bucket = "${var.s3_bucket_name}-bucket"
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
      "arn:aws:s3:::${var.s3_bucket_name}/*"
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
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  statement {
    sid    = "AllowReverseStringHandlerPutObject"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  statement {
    sid    = "AllowReverseStringHandlerListBucket"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}"]
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
  name               = "ReverseStringHandlerExecutionrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.id
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
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  statement {
    sid       = "AllowS3PutObject"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  statement {
    sid       = "AllowS3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}"]
  }

}
// LambdaExecutionPolicy
resource "aws_iam_policy" "policy" {
  name   = "ReverseStringHandlerExecutionPolicy"
  policy = data.aws_iam_policy_document.reverse_string_handler_execution_policy.id
}

resource "aws_lambda_function" "reverse_string_handler" {
  filename      = "dummy.zip"
  function_name = "${var.reverse_string_handler_name}_handler"
  role          = aws_iam_role.role.arn
  handler       = "exports.handler"
  runtime       = "nodejs12.x"
}
