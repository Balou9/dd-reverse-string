const { S3 } = require("aws-sdk")
const s3 = new S3({ apiVersion: '2006-03-01' })

function reverse (str) {
  return str.split('').reverse().join('')
}

module.exports.handler = async function (event, context) {
  try {
    if (!event.from || !event.to) {
      return { statusCode: 400 }
    }

    const response = await s3.getObject({
      Key: event.from,
      Bucket: process.env.STRING_BUCKET_NAME
    }).promise()

    const reversed = reverse(response.Body.toString())

    await s3.putObject({
      Key: event.to,
      Bucket: process.env.REVERSE_STRING_BUCKET_NAME,
      Body: reversed
    }).promise()

    return { statusCode: 204 }
  } catch (err) {
    return { statusCode: 500 }
  }
}
