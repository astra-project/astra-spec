# The remote stage is a bare repository with one commit, S, which holds
# stage's astra.yaml: the decisions mode and decision2, whose option a
# requires mode's x, output3, built per universe, output4, switch3, and the
# universe v1.
stage=$ASTRA_CASE_REMOTES/stage
mkdir "$stage.work"
cat > "$stage.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  mode:
    options: {x: {}, y: {}}
  decision2:
    options:
      a:
        requires: [mode.x]
      b: {}
outputs:
  output3:
    type: data
    format: csv
    decisions: [decision2]
    recipe:
      command: python make.py '{decisions.decision2}' '{output}'
  output4:
    type: data
    format: csv
    recipe:
      command: python make.py output4 '{output}'
  switch3:
    switch: mode
    cases: {x: output3, y: output4}
universes:
  v1:
    decisions: {mode: y, decision2: a}
EOF
git -C "$stage.work" init --quiet
git -C "$stage.work" add astra.yaml
git -C "$stage.work" commit --quiet --message S
git -C "$stage.work" tag S
git clone --quiet --bare "$stage.work" "$stage"
rm -rf "$stage.work"

# One commit holds every file, with astra.yaml declaring stage by its URL
# and S.
commit=$(git -C "$stage" rev-parse S)
sed -e "s|@url:stage@|file://$stage|" -e "s|@commit:S@|$commit|" \
  astra.yaml > astra.yaml.new
mv astra.yaml.new astra.yaml
git init --quiet
git add --all
git commit --quiet --message files
