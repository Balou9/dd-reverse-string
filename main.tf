// Declare variables set by github actions workflow
variable "s3_bucket_name" {
  type        = string
  description = "The name of the s3 bucket"
}

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
    principals {
      type = "CanonicalUser"
      identifiers = [ aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id ]
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
    principals {
      type = "AWS"
      identifiers = [ aws_lambda_function.reverse_string_handler.arn ]
    }
    actions = [ "s3:GetObject" ]
    resources = [ "arn:aws:s3:::${var.s3_bucket_name}/*" ]
  }

  statement {
    sid = "AllowReverseStringHandlerPutObject"
    effect = "allow"
    principals {
      type = "AWS"
      identifiers = [ aws_lambda_function.reverse_string_handler.arn ]
    }
    actions = [ "s3:PutObject" ]
    resources = [ "arn:aws:s3:::${var.s3_bucket_name}/*" ]
  }

  statement {
    sid = "AllowReverseStringHandlerListBucket"
    effect = "allow"
    principals {
      type = "AWS"
      identifiers = [ aws_lambda_function.reverse_string_handler.arn ]
    }
    actions = [ "s3:ListBucket" ]
    resources = [ "arn:aws:s3:::${var.s3_bucket_name}" ]
  }

}

// Bucket Policy
resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy_document.id
}


data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    sid = "AllowAssumeRoleByLambda"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
    action = [ "sts:AssumeRole" ]
  }
}

// LambdaExecutionRole
resource "aws_iam_role" "role" {
  name               = "ReverseStringHandlerExecutionrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.id
}


data "aws_iam_policy" "reverse_string_handler_execution_policy" {

  statement {
    sid = "AllowLogCreation"
    effect = "Allow"
    action = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [ "arn:aws:logs:*:*:*" ]
  }

  statement {
    sid = "AllowS3GetObject"
    effect = "Allow"
    action = [ "s3:GetObject" ]
    resources = "arn:aws:s3:::${var.s3_bucket_name}/*"
  }

  statement {
    sid = "AllowS3PutObject"
    effect = "Allow"
    action = [ "s3:PutObject" ]
    resources = "arn:aws:s3:::${var.s3_bucket_name}/*"
  }

  statement {
    sid = "AllowS3ListBucket"
    effect = "Allow"
    action = [ "s3:ListBucket" ]
    resources = "arn:aws:s3:::${var.s3_bucket_name}"
  }

}
// LambdaExecutionPolicy
resource "aws_iam_policy" "policy" {
  name   = "ReverseStringHandlerExecutionPolicy"
  policy = data.aws_iam_policy.reverse_string_handler_execution_policy.id
}

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
