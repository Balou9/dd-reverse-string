# dd-reverse-string

[![cdci](https://github.com/Balou9/dd-reverse-string/workflows/cdci/badge.svg)](https://github.com/Balou9/dd-reverse-string/actions)

Datadrivers Coding Challenge

## Task

Create a Lambda handler which performs a string reversion. The handler reads the string from one S3 bucket, flips the string, and then stores it in another S3 bucket. The use of Terraform is mandatory.

## CD/CI Workflow

I created a [workflow](https://github.com/Balou9/dd-reverse-string/blob/main/.github/workflows/cdci.yml) which gets triggered on push commits to the main branch. It consists of a deployment job `deploy` and a test job `test`. The workflow runs the `deploy` and the `test` job in a sequence, to test against the new deployment.

## CD

The first job `deploy` bundles the [handler](https://github.com/Balou9/dd-reverse-string/blob/main/index.js) and creates a terraform execution plan based on the defined resources in the [main.tf](https://github.com/Balou9/dd-reverse-string/blob/main/main.tf) template. Afterwards it deploys the execution plan in the terraform cloud.

## CI

The second job `test` runs after the `deploy` job. It copies an example string to the bucket and runs a couple of test functions against the new deployment.

### Test cases

The test cases are defined in a [test suite](https://github.com/Balou9/dd-reverse-string/blob/main/test_suite.sh) as pure bash functions. They are executed directly in the pipeline without the need of a third-party testing framework.

#### test_reverse_string_204()

- tests if the reverse-string-handler returns statusCode `204` if required parameters `from: s3 object key of the file which contains a string to be reversed, to: s3 object key of the reversed string file` are passed and if the string in the destination bucket has actually been reversed

#### test_reverse_string_400()

- tests if the reverse-string-handler returns statusCode `400` if required parameters are not being passed to the handler

#### test_reverse_string_500()

- tests if the reverse-string-handler returns statusCode `500` if invalid s3 object keys are passed to the handler
