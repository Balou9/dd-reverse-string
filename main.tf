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
} // TODO: add env variable ENVIRONMENT: test | prod ?

# data "aws_iam_policy_document" "example" {
#   statement {
#     sid = "AllowOriginAccesIdentity"
#     effect = "allow"
#     principals = {
#
#     }
#     actions = [
#       "s3:Get*",
#       "s3:List*"
#     ]
#     resources = [
#       "!GetAtt Bucket.Arn",
#       "!Sub arn:aws:s3:::{Bucket}/*"
#     ]
#   }
# }
// Bucket Policy
resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOriginAccessIdentity",
      "Effect": "Allow",
      "Principal": {
        "CanonialUser": "!GetAtt OriginAccessIdentity.S3CanonialUserId"
      },
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "!GetAtt Bucket.Arn",
        "!Sub arn:aws:s3:::{Bucket}/*"
      ]
    },
    {
      "Sid": "AllowReverseStringHandlerGetObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "!GetAtt ReverseStringHandlerExecutionRole.Arn"
      },
      "Action": [ "s3:GetObject" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}/*"
    },
    {
      "Sid": "AllowReverseStringHandlerPutObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "!GetAtt ReverseStringHandlerExecutionRole.Arn"
      },
      "Action": [ "s3:PutObject" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}/*"
    },
    {
      "Sid": "AllowReverseStringHandlerListBucket",
      "Effect": "Allow",
      "Principal": {
        "AWS": "!GetAtt ReverseStringHandlerExecutionRole.Arn"
      },
      "Action": [ "s3:ListBucket" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}"
    }
  ]
}
POLICY
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

# resource "aws_lambda_function" "lambda" {
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
