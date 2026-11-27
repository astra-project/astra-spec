# The first commit, C1, holds a minimal astra.yaml at the top and
# stage/astra.yaml: decision2, and output3, built per universe.
git init --quiet
mv astra.yaml astra.yaml.final
cat > astra.yaml <<'EOF'
spec_version: "0.1.0"
EOF
git add astra.yaml stage/astra.yaml
git commit --quiet --message C1
git tag C1

# The second holds the final astra.yaml, which declares stage at C1.
commit=$(git rev-parse C1)
sed "s/@commit:C1@/$commit/" astra.yaml.final > astra.yaml
rm astra.yaml.final
git add --all
git commit --quiet --message files
