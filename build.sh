#!/bin/bash
set -e

echo "===> 1. Cáº¥u hÃ¬nh Git an toÃ n..."
git config --global --add safe.directory "*"

echo "===> 2. CÃ i Ä‘áº·t Flutter SDK (Shallow clone depth 1)..."
if [ -d "flutter" ]; then
  echo "ThÆ° má»¥c flutter Ä‘Ã£ tá»“n táº¡i, Ä‘á»“ng bá»™ báº£n má»›i nháº¥t..."
  cd flutter
  git fetch --depth 1 origin stable
  git reset --hard origin/stable
  cd ..
else
  echo "Clone Flutter SDK báº£n stable..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

export PATH="$PATH:$PWD/flutter/bin"
FLUTTER_BIN="$PWD/flutter/bin/flutter"

echo "===> 3. Cáº¥u hÃ¬nh Flutter khÃ´ng gá»­i analytics vÃ  táº£i trÆ°á»›c web engine..."
"$FLUTTER_BIN" config --no-analytics
"$FLUTTER_BIN" precache --web

echo "===> 4. Táº£i cÃ¡c gÃ³i thÆ° viá»‡n phá»¥ thuá»™c..."
"$FLUTTER_BIN" pub get

echo "===> 5. BiÃªn dá»‹ch Flutter Web..."
"$FLUTTER_BIN" build web --release --no-tree-shake-icons

echo "===> BUILD FLUTTER WEB THÃ€NH CÃ”NG!"
