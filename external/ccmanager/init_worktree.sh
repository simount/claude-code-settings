# Copy all .env files from the git root to the worktree (skip node_modules)
find "$CCMANAGER_GIT_ROOT" -maxdepth 3 -name "*.env" -not -path "*/node_modules/*" | while read -r src; do
  rel="${src#$CCMANAGER_GIT_ROOT/}"
  dst="$CCMANAGER_WORKTREE_PATH/$rel"
  if [ ! -f "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
done

# Copy node_modules via hardlink (fast, disk-efficient, safe for read-only sharing)
find "$CCMANAGER_GIT_ROOT" -maxdepth 2 -type d -name "node_modules" -not -path "*/node_modules/*/node_modules" | while read -r src; do
  rel="${src#$CCMANAGER_GIT_ROOT/}"
  dst="$CCMANAGER_WORKTREE_PATH/$rel"
  if [ ! -d "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp -al "$src" "$dst"
  fi
done

# Copy .tmp directory (investigation files, intermediate results, etc.)
if [ -d "$CCMANAGER_GIT_ROOT/.tmp" ]; then
  cp -r "$CCMANAGER_GIT_ROOT/.tmp" "$CCMANAGER_WORKTREE_PATH/.tmp"
else
  mkdir -p "$CCMANAGER_WORKTREE_PATH/.tmp"
fi
