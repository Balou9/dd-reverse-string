test_reverse_string_200() {
  printf "test_reverse_string_200\n"
  resp_body="$(mktemp)"

  aws lambda invoke \
  --function-name reverse-string-handler \
  --payload '{"from": "string.json", "to": "reversed_string.json"}' \
  $resp_body

  status=$(cat $resp_body | jq .statusCode)
  assert_equal $status 200
}

test_reverse_string_400() {
  printf "test_reverse_string_400\n"
  resp_body="$(mktemp)"

  aws lambda invoke \
  --function-name reverse-string-handler \
  --payload '{"origin": "string.json", "destination": "reversed_string.json"}' \
  $resp_body

  status=$(cat $resp_body | jq .statusCode)
  assert_equal $status 400
}
