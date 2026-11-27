# The remote noise is a bare repository with one commit, N, which holds
# noise's astra.yaml: the decision model, the output psd built per
# universe, and the universes white and pink.
noise=$ASTRA_CASE_REMOTES/noise
mkdir "$noise.work"
cat > "$noise.work/astra.yaml" <<'EOF'
spec_version: "0.1.0"
decisions:
  model:
    options:
      white: {}
      pink: {}
outputs:
  psd:
    type: data
    format: csv
    decisions: [model]
    recipe:
      command: python make.py '{decisions.model}' '{output}'
universes:
  white:
    decisions: {model: white}
  pink:
    decisions: {model: pink}
EOF
git -C "$noise.work" init --quiet
git -C "$noise.work" add astra.yaml
git -C "$noise.work" commit --quiet --message N
git -C "$noise.work" tag N
git clone --quiet --bare "$noise.work" "$noise"
rm -rf "$noise.work"

# One commit holds every file, with astra.yaml declaring noise by its URL
# and N.
commit=$(git -C "$noise" rev-parse N)
sed -e "s|@url:noise@|file://$noise|" -e "s|@commit:N@|$commit|" \
  astra.yaml > astra.yaml.new
mv astra.yaml.new astra.yaml
git init --quiet
git add --all
git commit --quiet --message files
