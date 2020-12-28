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

  printf "test_reversed_string_has_actually_been_reversed\n"
  plain_string="$(mktemp)"
  reversed_string="$(mktemp)"

  aws s3api get-object \
    --bucket plain-string-bucket \
    --key example.txt \
    $plain_string \
  > /dev/null

  aws s3api get-object \
    --bucket reversed-string-bucket \
    --key reversed_example.txt \
    $reversed_string \
  > /dev/null

  bash_reversed_string=$(cat $plain_string | rev)
  if grep -xq "$bash_reversed_string" "$reversed_string"; then
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
