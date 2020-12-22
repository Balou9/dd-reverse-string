test_reverse_string_200() {
  printf "test_reverse_string_200\n"
  status="$(mktemp)"
  string="$(mktemp)"
  resp_body="$(mktemp)"

  aws lambda invoke --function-name reverse-string-handler $resp_body

  cat $resp_body | jq .statusCode >> $status
  cat $resp_body | jq .body >> $string

  assert_status $status 200
}
