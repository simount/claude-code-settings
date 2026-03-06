# Copy all .env files from the git root to the worktree (skip node_modules)
find "$CCMANAGER_GIT_ROOT" -name "*.env" -not -path "*/node_modules/*" | while read -r src; do
  rel="${src#$CCMANAGER_GIT_ROOT/}"
  dst="$CCMANAGER_WORKTREE_PATH/$rel"
  if [ ! -f "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
done

# Prepare the working directory as well
mkdir -p "$CCMANAGER_WORKTREE_PATH/.tmp"
