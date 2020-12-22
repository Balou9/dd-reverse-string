test_reverse_string_200() {
  printf "test_reverse_string_200\n"
  status="$(mktemp)"
  resp_body="$(mktemp)"

  aws lambda invoke --function-name reverse-string-handler $resp_body

  cat $resp_body | jq .statusCode >> $status
  assert_equal $status 200
}
