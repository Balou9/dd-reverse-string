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
variable "reverse_string" {

  type = string
  description = "The string 'reverse-string' to use for resource naming of revelvant resources"

}

variable "string" {

  type = string
  description = "The string 'string' to use for resource naming of revelvant resources"

}

// Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "dd-reverse-strings-oai"
}

// string Bucket
resource "aws_s3_bucket" "string_bucket" {
  tags = {
    Key   = "dd-string:name"
    Value = "dd-string"
  }
  bucket = "${var.string}-bucket"
}

// reverse_string Bucket
resource "aws_s3_bucket" "reverse_string_bucket" {
  tags = {
    Key   = "dd-reverse-string:name"
    Value = "dd-reverse-string"
  }
  bucket = "${var.reverse_string}-bucket"
}
// String Bucket Policy
data "aws_iam_policy_document" "string_bucket_policy_document" {

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
      aws_s3_bucket.string_bucket.arn,
      "arn:aws:s3:::${aws_s3_bucket.string_bucket.bucket}/*"
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
    resources = ["arn:aws:s3:::${aws_s3_bucket.string_bucket.bucket}/*"]
  }

}

// reverse_string Bucket Policy
data "aws_iam_policy_document" "reverse_string_bucket_policy_document" {

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
      aws_s3_bucket.reverse_string_bucket.arn,
      "arn:aws:s3:::${aws_s3_bucket.reverse_string_bucket.bucket}/*"
    ]
  }

  statement {
    sid    = "AllowReverseStringHandlerPutObject"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reverse_string_bucket.bucket}/*"]
  }

  statement {
    sid    = "AllowReverseStringHandlerListBucket"
    effect = "allow"
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.reverse_string_handler.arn]
    }
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reverse_string_bucket.bucket}"]
  }

}

resource "aws_s3_bucket_policy" "string_policy" {
  bucket = aws_s3_bucket.string_bucket.id
  policy = data.aws_iam_policy_document.string_bucket_policy_document.id
}

resource "aws_s3_bucket_policy" "reverse_string_policy" {
  bucket = aws_s3_bucket.reverse_string_bucket.id
  policy = data.aws_iam_policy_document.reverse_string_bucket_policy_document.id
}


// LambdaExecutionRole
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
    resources = ["arn:aws:s3:::${aws_s3_bucket.string_bucket.bucket}/*"]
  }

  statement {
    sid       = "AllowS3PutObject"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reverse_string_bucket.bucket}/*"]
  }

  statement {
    sid       = "AllowS3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reverse_string_bucket.bucket}"]
  }

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

resource "aws_iam_role" "role" {
  name               = "ReverseStringHandlerExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
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

// ReverseStringHandler
resource "aws_lambda_function" "reverse_string_handler" {
  function_name = "${var.reverse_string}-handler"
  role          = aws_iam_role.role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  environment {
    variables = {
      STRING_BUCKET_NAME = aws_s3_bucket.string_bucket.bucket
      REVERSE_STRING_BUCKET_NAME = aws_s3_bucket.reverse_string_bucket.bucket
    }
  }
}
