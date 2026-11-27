# The remote upstream is a bare repository with one commit, U, which holds
# upstream's astra.yaml: decision1, and output4, built per universe.
upstream=$ASTRA_CASE_REMOTES/upstream
mkdir "$upstream.work"
cat > "$upstream.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  decision1:
    options:
      a: {}
      b: {}
outputs:
  output4:
    type: metric
    format: json
    decisions: [decision1]
    recipe:
      command: python make.py '{decisions.decision1}' '{output}'
EOF
git -C "$upstream.work" init --quiet
git -C "$upstream.work" add astra.yaml
git -C "$upstream.work" commit --quiet --message U
git -C "$upstream.work" tag U
git clone --quiet --bare "$upstream.work" "$upstream"
rm -rf "$upstream.work"

# One commit holds every file, with stage/astra.yaml declaring upstream by
# its URL and U.
commit=$(git -C "$upstream" rev-parse U)
sed -e "s|@url:upstream@|file://$upstream|" -e "s|@commit:U@|$commit|" \
  stage/astra.yaml > stage/astra.yaml.new
mv stage/astra.yaml.new stage/astra.yaml
git init --quiet
git add --all
git commit --quiet --message files
