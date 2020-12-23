const { S3 } = require('aws-sdk')
const s3 = new S3({ apiVersion: '2006-03-01' })

function reverse (str) {
  return str.split('').reverse().join('')
}

module.exports.handler = async function (event, context) {
  const response = await s3.getObject({
    Key: 'string.json',
    Bucket: process.env.STRING_BUCKET_NAME
  }).promise()

  const reversed = reverse(response.Body.toString())

  await s3.putObject({
    Key: 'reversed_string.json',
    Bucket: process.env.REVERSE_STRING_BUCKET_NAME,
    Body: reversed
  }).promise()

  return { statusCode: 200 }
}
