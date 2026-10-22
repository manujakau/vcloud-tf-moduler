for m in modules/*/; do
  echo "== $m"
  (cd "$m" && terraform init -backend=false -input=false >/dev/null && terraform test -verbose)
done