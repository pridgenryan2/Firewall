#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ios_dir="$root_dir/ios"
linux_dir="$root_dir/linux"
conflict_dir="$root_dir/conflicts"

if [[ ! -d "$ios_dir" || ! -d "$linux_dir" ]]; then
  echo "Missing ios/ or linux/ directory under $root_dir" >&2
  exit 1
fi

copy_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  echo "Synced: $src -> $dest"
}

handle_conflict() {
  local rel="$1"
  local ios_file="$2"
  local linux_file="$3"
  mkdir -p "$conflict_dir"
  local base="${rel//\//__}"
  cp -a "$ios_file" "$conflict_dir/${base}.ios"
  cp -a "$linux_file" "$conflict_dir/${base}.linux"
  echo "Conflict: $rel (saved to $conflict_dir/${base}.ios and .linux)" >&2
  exit 2
}

mapfile -t files < <(
  cd "$root_dir"
  {
    find ios -type f -print
    find linux -type f -print
  } | sed -e 's|^ios/||' -e 's|^linux/||' | sort -u
)

for rel in "${files[@]}"; do
  ios_file="$ios_dir/$rel"
  linux_file="$linux_dir/$rel"

  if [[ -f "$ios_file" && ! -f "$linux_file" ]]; then
    copy_file "$ios_file" "$linux_file"
    continue
  fi

  if [[ -f "$linux_file" && ! -f "$ios_file" ]]; then
    copy_file "$linux_file" "$ios_file"
    continue
  fi

  if cmp -s "$ios_file" "$linux_file"; then
    continue
  fi

  ios_mtime=$(stat -c %Y "$ios_file")
  linux_mtime=$(stat -c %Y "$linux_file")

  if [[ "$ios_mtime" -gt "$linux_mtime" ]]; then
    copy_file "$ios_file" "$linux_file"
  elif [[ "$linux_mtime" -gt "$ios_mtime" ]]; then
    copy_file "$linux_file" "$ios_file"
  else
    handle_conflict "$rel" "$ios_file" "$linux_file"
  fi
done

echo "Sync complete."
