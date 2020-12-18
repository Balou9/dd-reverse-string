const { S3 } = require("aws-sdk");
const s3 = new S3({
  apiVersion: "2006-03-01"
})

module.exports.handler = async function handler (event, context) {

  try {

    const payload = await s3.getObject({
      Key: event.pathParameters.string,
      Bucket: process.env.STRING_BUCKET_NAME
    }).promise()

    return {
      "statusCode": 200,
      "headers": {
        "content-type": "application/json",
      },
      "body": JSON.stringify(payload)
    }

  } catch (err) {

    if ( err.code === "NoSuchKey" ) {
      return { "statusCode": 404 }
    }

    return {
      "statusCode": err.code,
      "body": err.message
    }

  }
}

if (!process.env.STRING_BUCKET_NAME) {
  throw new Error("missing required env var STRING_BUCKET_NAME");
}

if (!process.env.REVERSE_STRING_BUCKET_NAME) {
  throw new Error("missing required env var STRING_BUCKET_NAME");
}
