const { S3 } = require("aws-sdk");
const string_bucket_s3 = new S3({
  apiVersion: "2006-03-01"
})

module.exports.handler = async function handler (event, context) {
  try {
    var payload = await s3.getObject({
      Key: "string.json",
      Bucket: process.env.STRING_BUCKET_NAME
    }).promise()
    var reversed_string = payload.body.toString().split("").reverse().join("")
    await s3.putObject({
      Key: "reversed_string.json",
      Bucket: process.env.REVERSE_STRING_BUCKET_NAME,
      Body: reversed_string
    }).promise()
    
    return { "statusCode": 200 }
  } catch (err) {
    return { "statusCode": 500 }
  }
}
