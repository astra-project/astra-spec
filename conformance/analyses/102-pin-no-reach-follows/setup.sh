# The remote upstream is a bare repository with one commit, U, which holds
# upstream's astra.yaml: the decisions decision0 and decision5, the outputs
# fit and other, built once, switch2 on decision5, switch1 on decision0,
# and the universe w1, which sets only decision0.
upstream=$ASTRA_CASE_REMOTES/upstream
mkdir "$upstream.work"
cat > "$upstream.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  decision0:
    options: {x: {}, y: {}}
  decision5:
    options: {p: {}, q: {}}
outputs:
  fit:
    type: data
    format: csv
    recipe:
      command: python make.py fit '{output}'
  other:
    type: data
    format: csv
    recipe:
      command: python make.py other '{output}'
  switch2:
    switch: decision5
    cases: {p: fit, q: fit}
  switch1:
    switch: decision0
    cases: {x: switch2, y: other}
universes:
  w1:
    decisions: {decision0: y}
EOF
git -C "$upstream.work" init --quiet
git -C "$upstream.work" add astra.yaml
git -C "$upstream.work" commit --quiet --message U
git -C "$upstream.work" tag U
git clone --quiet --bare "$upstream.work" "$upstream"
rm -rf "$upstream.work"

# One commit holds every file, with sub/astra.yaml declaring upstream by
# its URL and U.
commit=$(git -C "$upstream" rev-parse U)
sed -e "s|@url:upstream@|file://$upstream|" -e "s|@commit:U@|$commit|" \
  sub/astra.yaml > sub/astra.yaml.new
mv sub/astra.yaml.new sub/astra.yaml
git init --quiet
git add --all
git commit --quiet --message files
