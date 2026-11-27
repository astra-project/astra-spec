# The remote upstream: a bare repository whose one commit, U, holds an
# input, a top astra.yaml that declares stage/, and stage/astra.yaml,
# which declares its parent with .. and reads its input.
upstream=$ASTRA_CASE_REMOTES/upstream
mkdir -p "$upstream.work/stage" "$upstream.work/data"
printf 'sample,value\n1,0.5\n' > "$upstream.work/data/input1.csv"
cat > "$upstream.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
analyses:
  stage:
    path: stage
inputs:
  input1:
    path: data/input1.csv
outputs:
  output4:
    type: metric
    format: json
    inputs: [stage.output2]
    recipe:
      command: python make.py '{inputs.stage.output2}' '{output}'
EOF
cat > "$upstream.work/stage/astra.yaml" <<'EOF'
spec_version: "0.1.0"
analyses:
  parent:
    path: ..
outputs:
  output2:
    type: data
    format: csv
    inputs: [parent.input1]
    recipe:
      command: python make.py '{inputs.parent.input1}' '{output}'
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
