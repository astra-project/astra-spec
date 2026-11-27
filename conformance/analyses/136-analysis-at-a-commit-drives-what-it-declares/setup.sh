# The remote upstream is a bare repository with one commit, U, which holds
# upstream's astra.yaml at its top, whose universe v1 sets decision4 of
# inner/, which it declares by path.
upstream=$ASTRA_CASE_REMOTES/upstream
mkdir -p "$upstream.work/inner"
cat > "$upstream.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
analyses:
  inner:
    path: inner
outputs:
  output2:
    type: data
    format: csv
    inputs: [inner.output5]
    recipe:
      command: python make.py '{inputs.inner.output5}' '{output}'
universes:
  v1:
    decisions: {inner.decision4: a}
EOF
cat > "$upstream.work/inner/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  decision4:
    options:
      a: {}
      b: {}
outputs:
  output5:
    type: data
    format: csv
    decisions: [decision4]
    recipe:
      command: python make.py '{decisions.decision4}' '{output}'
EOF
git -C "$upstream.work" init --quiet
git -C "$upstream.work" add --all
git -C "$upstream.work" commit --quiet --message U
git -C "$upstream.work" tag U
git clone --quiet --bare "$upstream.work" "$upstream"
rm -rf "$upstream.work"

# One commit holds every file, with astra.yaml declaring upstream by its
# URL and U.
commit=$(git -C "$upstream" rev-parse U)
sed -e "s|@url:upstream@|file://$upstream|" -e "s|@commit:U@|$commit|" \
  astra.yaml > astra.yaml.new
mv astra.yaml.new astra.yaml
git init --quiet
git add --all
git commit --quiet --message files
