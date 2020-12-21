test_reverse_string_200() {
  printf "test_profiles_upsert_204\n"
  resp_head="$(mktemp)"
  resp_body="$(mktemp)"

  aws lambda invoke --function-name reverse-string-handler $resp_body

  cat $resp_body | jq .statusCode
  cat $resp_body | jq .Body

}
