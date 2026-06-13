#!/usr/bin/env bash
set -euo pipefail

# Genera carpetas nativas con tu versión instalada de Flutter
# y luego restaura el código de la demo para evitar sobrescrituras.

BACKUP_DIR="$(mktemp -d)"

cp -R lib "$BACKUP_DIR/lib"
cp pubspec.yaml "$BACKUP_DIR/pubspec.yaml"
cp analysis_options.yaml "$BACKUP_DIR/analysis_options.yaml"
cp README.md "$BACKUP_DIR/README.md"
cp -R supabase "$BACKUP_DIR/supabase"
cp -R docs "$BACKUP_DIR/docs"
cp -R scripts "$BACKUP_DIR/scripts"
cp -R test "$BACKUP_DIR/test"
[ -d web ] && cp -R web "$BACKUP_DIR/web"
[ -d .vscode ] && cp -R .vscode "$BACKUP_DIR/.vscode"

flutter create --platforms=android,ios,web .

rm -rf lib supabase docs scripts test .vscode
[ -d "$BACKUP_DIR/web" ] && rm -rf web
cp -R "$BACKUP_DIR/lib" ./lib
cp "$BACKUP_DIR/pubspec.yaml" ./pubspec.yaml
cp "$BACKUP_DIR/analysis_options.yaml" ./analysis_options.yaml
cp "$BACKUP_DIR/README.md" ./README.md
cp -R "$BACKUP_DIR/supabase" ./supabase
cp -R "$BACKUP_DIR/docs" ./docs
cp -R "$BACKUP_DIR/scripts" ./scripts
cp -R "$BACKUP_DIR/test" ./test
[ -d "$BACKUP_DIR/web" ] && cp -R "$BACKUP_DIR/web" ./web
[ -d "$BACKUP_DIR/.vscode" ] && cp -R "$BACKUP_DIR/.vscode" ./.vscode

flutter pub get

echo "Proyecto listo. Revisa README.md para ejecutar con tus dart-defines de Supabase."
