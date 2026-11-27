# The first commit, C1, holds only stage/astra.yaml: no astra.yaml is at
# the top.
git init --quiet
git add stage/astra.yaml
git commit --quiet --message C1
git tag C1

# The second holds the rest, with astra.yaml declaring stage at C1.
commit=$(git rev-parse C1)
sed "s/@commit:C1@/$commit/" astra.yaml > astra.yaml.new
mv astra.yaml.new astra.yaml
git add --all
git commit --quiet --message files
