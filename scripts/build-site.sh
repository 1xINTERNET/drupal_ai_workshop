#!/usr/bin/env bash
# Builds the website with all step guides from the last step branch, and deploys it to
# the gh-pages branch with --deploy. The current checkout is not changed.
#
#   scripts/build-site.sh [--deploy] [branch]
set -euo pipefail

deploy=0
if [ "${1:-}" = "--deploy" ]; then deploy=1; shift; fi
branch="${1:-04_ai_content_review}"
repo_url="https://github.com/1xINTERNET/drupal_ai_workshop"

cd "$(git rev-parse --show-toplevel)"
build=.site-build
rm -rf "$build"
mkdir -p "$build/src" "$build/docs"

# Export the guides and the README of the branch.
git archive "$branch" docs README.md | tar -x -C "$build/src"
cp -r "$build/src/docs/." "$build/docs/"
cp "$build/src/README.md" "$build/docs/index.md"
# Logo, fonts and styles of the website.
cp -r site-theme/assets "$build/docs/"

# Links that leave docs/ point to the repository on GitHub instead.
BRANCH="$branch" REPO_URL="$repo_url" python3 - "$build/docs" <<'PY'
import os, re, sys
root, branch, repo = sys.argv[1], os.environ["BRANCH"], os.environ["REPO_URL"]

def github(path):
    kind = "tree" if path.endswith("/") else "blob"
    return f"{repo}/{kind}/{branch}/{path}"

def title(name):
    for line in open(os.path.join(root, name)):
        if line.startswith("# "):
            return line[2:].strip()
    return name

def rewrite(text, in_readme):
    def link(m):
        label, target = m.group(1), m.group(2)
        if re.match(r"(https?:|mailto:|#)", target):
            return m.group(0)
        path, _, anchor = target.partition("#")
        anchor = "#" + anchor if anchor else ""
        if in_readme:
            if path.startswith("docs/") and path.endswith(".md"):
                page = path[len("docs/"):]
                if label == path:
                    label = title(page)
                return f"[{label}]({page}{anchor})"
            return f"[{label}]({github(path)}{anchor})"
        if path == "../README.md":
            return f"[{label}](index.md{anchor})"
        if path.startswith("../"):
            return f"[{label}]({github(path[3:])}{anchor})"
        return m.group(0)
    return re.sub(r"\[([^\]]*)\]\(([^)\s]+)\)", link, text)

for name in os.listdir(root):
    if name.endswith(".md"):
        p = os.path.join(root, name)
        s = open(p).read()
        open(p, "w").write(rewrite(s, name == "index.md"))
PY

docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/docs" squidfunk/mkdocs-material:9.7 build --strict
echo "Built $build/site from $branch."

if [ "$deploy" = 1 ]; then
  touch "$build/site/.nojekyll"
  git fetch -q origin gh-pages 2>/dev/null || true
  export GIT_INDEX_FILE="$PWD/$build/index"
  git --work-tree="$build/site" add -A --force
  tree=$(git write-tree)
  unset GIT_INDEX_FILE
  parent=()
  if git rev-parse -q --verify origin/gh-pages >/dev/null; then parent=(-p origin/gh-pages); fi
  commit=$(git commit-tree "$tree" "${parent[@]}" -m "Build the website from $branch ($(git rev-parse --short "$branch"))")
  git push origin "$commit:refs/heads/gh-pages"
  echo "Deployed to https://1xinternet.github.io/drupal_ai_workshop/"
fi
