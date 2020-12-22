assert_equal() {
  # usage: assert_equal "$a" "$b"
  if [[ "$1" != "$2" ]]; then
    >&2 printf "values are not equal\n" "$1" "$2"
    exit 1
  fi
}
printf "test_reverse_string_200\n"
status="$(mktemp)"
resp_body="$(mktemp)"

aws lambda invoke --function-name reverse-string-handler $resp_body

cat $resp_body | jq .StatusCode >> $status
assert_equal $status 200
cat $resp_body
