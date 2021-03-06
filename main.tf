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

// string Bucket
resource "aws_s3_bucket" "string_bucket" {
  bucket = "plain-string-bucket"
}

// reverse_string Bucket
resource "aws_s3_bucket" "reversed_string_bucket" {
  bucket = "reversed-string-bucket"
}
// String Bucket Policy
data "aws_iam_policy_document" "string_bucket_policy_document" {

  statement {

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.role.arn]
    }

    sid       = "AllowReverseStringHandlerGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.string_bucket.bucket}/*"]
  }

}

// reverse_string Bucket Policy
data "aws_iam_policy_document" "reverse_string_bucket_policy_document" {

  statement {

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.role.arn]
    }

    sid       = "AllowReverseStringHandlerPutObject"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reversed_string_bucket.bucket}/*"]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.role.arn]
    }

    sid       = "AllowReverseStringHandlerListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reversed_string_bucket.bucket}"]
  }

}

resource "aws_s3_bucket_policy" "string_policy" {
  bucket = aws_s3_bucket.string_bucket.id
  policy = data.aws_iam_policy_document.string_bucket_policy_document.json
}

resource "aws_s3_bucket_policy" "reverse_string_policy" {
  bucket = aws_s3_bucket.reversed_string_bucket.id
  policy = data.aws_iam_policy_document.reverse_string_bucket_policy_document.json
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
    resources = ["arn:aws:s3:::${aws_s3_bucket.reversed_string_bucket.bucket}/*"]
  }

  statement {
    sid       = "AllowS3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.reversed_string_bucket.bucket}"]
  }

}

data "aws_iam_policy_document" "assume_role_policy_document" {

  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    sid     = "AllowAssumeRoleByLambda"
    effect  = "Allow"
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
  filename      = "reverse_string_lambda.zip"
  function_name = "reverse-string-handler"
  role          = aws_iam_role.role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  source_code_hash = filebase64sha256("reverse_string_lambda.zip")

  environment {
    variables = {
      STRING_BUCKET_NAME         = aws_s3_bucket.string_bucket.bucket
      REVERSE_STRING_BUCKET_NAME = aws_s3_bucket.reversed_string_bucket.bucket
    }
  }
}

resource "aws_cloudwatch_log_group" "reverse_string_handler_log" {
  name              = "/aws/lambda/reverse-string-handler"
  retention_in_days = 7
}
