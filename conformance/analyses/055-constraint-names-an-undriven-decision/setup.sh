# The remote catalog is a bare repository with one commit, C, which holds
# catalog's astra.yaml at its top: input1, output3, built once, output4,
# built per universe, and the universe main. An option of its decision
# mode requires decision1 of other/, which it declares.
catalog=$ASTRA_CASE_REMOTES/catalog
mkdir -p "$catalog.work/data" "$catalog.work/other"
printf 'sample,value\n1,0.5\n' > "$catalog.work/data/input1.csv"
cat > "$catalog.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
analyses:
  other:
    path: other
inputs:
  input1:
    path: data/input1.csv
decisions:
  mode:
    options:
      fast: {}
      slow:
        requires: [other.decision1.a]
outputs:
  output3:
    type: data
    format: csv
    inputs: [input1]
    recipe:
      command: python make.py '{inputs.input1}' '{output}'
  output4:
    type: metric
    format: json
    decisions: [mode]
    recipe:
      command: python make.py '{decisions.mode}' '{output}'
universes:
  main:
    decisions: {mode: fast}
EOF
cat > "$catalog.work/other/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  decision1:
    options:
      a: {}
      b: {}
outputs:
  output1:
    type: metric
    format: json
    decisions: [decision1]
    recipe:
      command: python make.py '{decisions.decision1}' '{output}'
EOF
git -C "$catalog.work" init --quiet
git -C "$catalog.work" add --all
git -C "$catalog.work" commit --quiet --message C
git -C "$catalog.work" tag C
git clone --quiet --bare "$catalog.work" "$catalog"
rm -rf "$catalog.work"

# One commit holds every file, with astra.yaml declaring catalog by its URL
# and C.
commit=$(git -C "$catalog" rev-parse C)
sed -e "s|@url:catalog@|file://$catalog|" -e "s|@commit:C@|$commit|" \
  astra.yaml > astra.yaml.new
mv astra.yaml.new astra.yaml
git init --quiet
git add --all
git commit --quiet --message files
