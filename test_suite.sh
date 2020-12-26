test_reverse_string_204() {
  printf "test_reverse_string_204\n"
  resp_body="$(mktemp)"

  aws lambda invoke \
    --function-name reverse-string-handler \
    --payload '{"from":"example.txt","to":"reversed_example.txt"}' \
    $resp_body \
  > /dev/null

  status=$(cat $resp_body | jq .statusCode)
  assert_equal $status 204
}

test_string_has_been_reversed() {
  printf "test_string_has_been_reversed\n"
  example="$(mktemp)"
  reversed_example="$(mktemp)"

  aws s3api get-object \
    --bucket plain-string-bucket \
    --key example.json \
    $example
  > /dev/null
  aws s3api get-object \
    --bucket reversed-string-bucket \
    --key reversed_example.json \
    $reversed_example \
  > /dev/null

  bash_reversed=$(cat $example | rev)
  if grep -xq "$bash_reversed" "$reversed_example"; then
    printf "The string has been reversed\n"
  fi
}

test_reverse_string_400() {
  printf "test_reverse_string_400\n"
  resp_body="$(mktemp)"

  aws lambda invoke \
    --function-name reverse-string-handler \
    --payload '{}' \
    $resp_body \
  > /dev/null

  status=$(cat $resp_body | jq .statusCode)
  assert_equal $status 400
}

test_reverse_string_500() {
  printf "test_reverse_string_500\n"
  resp_body="$(mktemp)"

  aws lambda invoke \
    --function-name reverse-string-handler \
    --payload '{"from":"^a)f","to":"e>"}' \
  $resp_body \
  > /dev/null

  status=$(cat $resp_body | jq .statusCode)
  assert_equal $status 500
}
