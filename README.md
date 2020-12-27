# dd-reverse-string

[![cdci](https://github.com/Balou9/dd-reverse-string/workflows/cdci/badge.svg)](https://github.com/Balou9/dd-reverse-string/actions)W

## Challenge

Create a Lambda Handler which performs a string reversion.  
The handler reads the string from one S3 bucket, flips the string,  
and then stores it in another S3 bucket.
The use of Terraform is mandatory.

## CD/CI Workflow

I created a workflow which gets triggered on push to the main branch.  
It consists of a deployment job `deploy` and a test job `test`.   

The workflow runs the `deploy` and the `test` job in a sequence,  
to ensure that the `test` job tests against the new deployment.

**Trigger:**

```
on: push
```
**Branch:**

```
main
```

## CD

The first job `deploy` creates a terraform execution plan based  
on the defined resources in the main.tf template and deploys   
the execution plan in the terraform cloud.

The lambda function code gets bundled to provide the zip file archive for the deployment of the lambda function.  
Afterwards a terraform project is being initiated in the terraform cloud.   
Next the main.tf template gets validated an execution plan is being created    
and then applied in the terraform cloud.

## CI

The second job `test` tests the integration of the lambda handler against   
the new deployment. It ensures that the lambda handler reads a string from S3,   
reverses it and puts its into another S3 bucket.   

A sample string is copied into the bucket to provide a string for the lambda handler.

### Test cases

The test cases are defined in a test suite as pure bash functions.  
They are executed directly in the pipeline without the need of a third-party testing framework.

#### test_reverse_string_204()

- tests if the reverse_string_handler returns statusCode `204` on success

#### test_string_has_been_reversed()

- tests if the string in the destination bucket has actually been reversed

#### test_reverse_string_400()

- tests if the reverse_string_handler returns statusCode `400`  
if required parameters are not being passed to the handler

#### test_reverse_string_500()

- tests if the reverse_string_handler returns statusCode `500`  
if invalid s3 object keys are passed to the handler
