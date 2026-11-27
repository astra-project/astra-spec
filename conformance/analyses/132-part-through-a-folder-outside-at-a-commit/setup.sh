# The first commit, C1, holds a minimal astra.yaml at the top and data/.
git init --quiet
mv astra.yaml astra.yaml.final
cat > astra.yaml <<'EOF'
spec_version: "0.1.0"
EOF
git add astra.yaml data
git commit --quiet --message C1
git tag C1

# The second holds the rest, with study/astra.yaml declaring data at C1.
mv astra.yaml.final astra.yaml
commit=$(git rev-parse C1)
sed "s/@commit:C1@/$commit/" study/astra.yaml > study/astra.yaml.new
mv study/astra.yaml.new study/astra.yaml
git add --all
git commit --quiet --message files
