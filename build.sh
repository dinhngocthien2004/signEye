#!/bin/bash
set -e

echo "===> 1. Cấu hình quyền Git (Tránh lỗi dubious ownership trên container)..."
git config --global --add safe.directory "*"

echo "===> 2. Thiết lập Flutter SDK..."
if [ -d "flutter" ]; then
  echo "Thư mục flutter đã tồn tại, đồng bộ bản mới nhất..."
  cd flutter
  git fetch --depth 1 origin stable
  git reset --hard origin/stable
  cd ..
else
  echo "Clone Flutter SDK (shallow clone --depth 1 tiết kiệm dung lượng và tránh timeout)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

export PATH="$PATH:$PWD/flutter/bin"

echo "===> 3. Cấu hình Flutter không gửi analytics và tải trước web engine..."
flutter config --no-analytics
flutter precache --web

echo "===> 4. Tải các thư viện phụ thuộc..."
flutter pub get

echo "===> 5. Biên dịch Flutter Web (Kèm cờ --no-tree-shake-icons để chống tràn RAM 512MB trên Render)..."
flutter build web --release --no-tree-shake-icons

echo "===> HOÀN THÀNH BUILD FLUTTER WEB THÀNH CÔNG!"

