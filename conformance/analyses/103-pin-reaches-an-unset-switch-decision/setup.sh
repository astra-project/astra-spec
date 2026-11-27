# The remote upstream is a bare repository with one commit, U, which holds
# upstream's astra.yaml: the decisions decision0 and decision1, the outputs
# output1, output2 and output3, built once, switch1 on decision1, report,
# which reads it, switch0 on decision0, and the universe v1, which sets
# only decision0.
upstream=$ASTRA_CASE_REMOTES/upstream
mkdir "$upstream.work"
cat > "$upstream.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  decision0:
    options: {x: {}, y: {}}
  decision1:
    options: {a: {}, b: {}}
outputs:
  output1:
    type: data
    format: csv
    recipe:
      command: python make.py output1 '{output}'
  output2:
    type: data
    format: csv
    recipe:
      command: python make.py output2 '{output}'
  output3:
    type: data
    format: csv
    recipe:
      command: python make.py output3 '{output}'
  switch1:
    switch: decision1
    cases: {a: output1, b: output2}
  report:
    type: report
    format: md
    inputs: [switch1]
    recipe:
      command: python make.py '{inputs.switch1}' '{output}'
  switch0:
    switch: decision0
    cases: {x: report, y: output3}
universes:
  v1:
    decisions: {decision0: y}
EOF
git -C "$upstream.work" init --quiet
git -C "$upstream.work" add astra.yaml
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
