#!/usr/bin/env bash
# Install App Store into the current user's XDG directories.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$root/build"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
bin_dir="$HOME/.local/bin"
lib_dir="$HOME/.local/lib/appstore"
applications="$data_home/applications"
icons="$data_home/icons/hicolor/scalable/apps"

echo "Building App Store…"
cmake -S "$root" -B "$build_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build_dir" -j"$(nproc)" >/dev/null

echo "Installing…"
install -d "$lib_dir" "$bin_dir" "$applications" "$icons"
install -m 0755 "$build_dir/appstore" "$lib_dir/appstore"
install -m 0644 "$root/assets/appstore.svg" "$icons/org.clavis.AppStore.svg"

cat > "$bin_dir/appstore" <<EOF
#!/usr/bin/env bash
exec "$lib_dir/appstore" "\$@"
EOF
chmod 0755 "$bin_dir/appstore"

sed "s|@EXEC@|$bin_dir/appstore|g" \
    "$root/assets/org.clavis.AppStore.desktop.in" > "$applications/org.clavis.AppStore.desktop"
chmod 0644 "$applications/org.clavis.AppStore.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$applications" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$data_home/icons/hicolor" >/dev/null 2>&1 || true
fi

cat <<EOF
App Store installed.

  launcher  $bin_dir/appstore
  desktop   $applications/org.clavis.AppStore.desktop
  icon      $icons/org.clavis.AppStore.svg

Run:
  appstore

The app also appears in the application launcher as “App Store / 应用商店”.
EOF
