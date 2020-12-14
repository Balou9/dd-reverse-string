// TODO: declare variables set by github actions workflow
#
provider "aws" {
  region = "us-east-1"
}

// TODO: Bucket
resource "aws_s3_bucket" "Bucket" {
  tags = {
    Key        = "dd-reverse-string:name"
    Value      = "dd-reverse-string"
  }
} // TODO: add env variable ENVIRONMENT: test | prod ?

// TODO: Bucket Policy
resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.b.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOriginAccessIdentity",
      "Effect": "Allow",
      "Principal": {
        CanonialUser: !GetAtt OriginAccessIdentity.S3CanonialUserId
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
        AWS: !GetAtt ReverseStringHandlerExecutionRole.Arn
      },
      "Action": [ "s3:GetObject" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}/*"
    },
    {
      "Sid": "AllowReverseStringHandlerPutObject",
      "Effect": "Allow"
      "Principal": {
        AWS: !GetAtt ReverseStringHandlerExecutionRole.Arn
      },
      "Action": [ "s3:PutObject" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}/*"
    },
    {
      "Sid": "AllowReverseStringHandlerListBucket",
      "Effect": "Allow"
      "Principal": {
        AWS: !GetAtt ReverseStringHandlerExecutionRole.Arn
      },
      "Action": [ "s3:ListBucket" ],
      "Resource": "!Sub arn:aws:s3:::{Bucket}"
    }
  ]
}
POLICY
} // TODO: syntax issues concerning resource arns

// TODO: LambdaExecutionRole
resource "aws_iam_role" "role" {
  name = "ReverseStringHandlerExecutionrole"
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

// TODO: LambdaExecutionPolicy
resource "aws_iam_policy" "policy" {
  name = "ReverseStringHandlerExecutionPolicy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLogCreation"
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

resource "aws_iam_role_policy_attachment" "attach_reverseStringHandlerPolicy" {
  role = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
