#!/bin/bash

# Проверка наличия двух аргументов
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <directory1> <directory2>"
  exit 1
fi

DIR1=$1
DIR2=$2

# Проверка существования папок
if [ ! -d "$DIR1" ]; then
  echo "Directory $DIR1 does not exist."
  exit 1
fi

if [ ! -d "$DIR2" ]; then
  echo "Directory $DIR2 does not exist."
  exit 1
fi

# Функция для рекурсивного сравнения директорий по именам и содержимому
compare_dirs() {
  local dir1=$1
  local dir2=$2

  # Получаем список файлов и директорий в первой папке
  local entries1=$(find "$dir1" -type f -printf '%P\n' | sort)

  # Получаем список файлов и директорий во второй папке
  local entries2=$(find "$dir2" -type f -printf '%P\n' | sort)

  # Проходим по элементам из первой папки
  for entry in $entries1; do
    if [ ! -e "$dir2/$entry" ]; then
      echo "$dir2/$entry does not exist."
    fi
  done

  # Проходим по элементам из второй папки
  for entry in $entries2; do
    if [ ! -e "$dir1/$entry" ]; then
      echo "$dir1/$entry does not exist."
    fi
  done

  # Сравниваем файлы с одинаковыми путями
  for entry in $entries1; do
    if [ -e "$dir2/$entry" ]; then
      if [ -f "$dir1/$entry" ] && [ -f "$dir2/$entry" ]; then
        if ! cmp -s "$dir1/$entry" "$dir2/$entry"; then
          echo "Files $dir1/$entry and $dir2/$entry differ:"
          diff "$dir1/$entry" "$dir2/$entry"
        fi
      fi
    fi
  done
}

# Функция для сравнения содержимого файлов вне зависимости от имен
compare_content() {
  local dir1=$1
  local dir2=$2

  # Получаем список всех файлов в обеих папках
  local files1=$(find "$dir1" -type f)
  local files2=$(find "$dir2" -type f)

  declare -A file_hash_map

  # Вычисляем хэши файлов в первой папке и сохраняем их в ассоциативный массив
  for file in $files1; do
    hash=$(md5sum "$file" | awk '{print $1}')
    file_hash_map["$hash"]="$file"
  done

  # Проверяем хэши файлов во второй папке
  for file in $files2; do
    hash=$(md5sum "$file" | awk '{print $1}')
    if [[ -n "${file_hash_map["$hash"]}" ]]; then
      unset file_hash_map["$hash"]
    else
      echo "File $file in $dir2 does not match any file in $dir1"
    fi
  done

  # Выводим файлы из первой папки, которые не совпали с файлами из второй папки
  for hash in "${!file_hash_map[@]}"; do
    echo "File ${file_hash_map["$hash"]} in $dir1 does not match any file in $dir2"
  done
}

# Вызов функции сравнения директорий по именам и содержимому
compare_dirs "$DIR1" "$DIR2"

# Вызов функции сравнения содержимого файлов
compare_content "$DIR1" "$DIR2"
