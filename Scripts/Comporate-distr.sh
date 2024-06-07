#!/bin/bash

# Проверяем наличие двух аргументов (папок)
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <folder1> <folder2>"
    exit 1
fi

FOLDER1=$1
FOLDER2=$2

# Проверяем, существуют ли указанные папки
if [ ! -d "$FOLDER1" ]; then
    echo "Folder $FOLDER1 does not exist."
    exit 1
fi

if [ ! -d "$FOLDER2" ]; then
    echo "Folder $FOLDER2 does not exist."
    exit 1
fi

# Функция для сравнения двух файлов
compare_files() {
    if cmp -s "$1" "$2"; then
        echo "OK: $1 and $2 are identical"
    else
        echo "DIFFERENT: $1 and $2 differ"
    fi
}

# Обходим файлы в первой папке
for file1 in "$FOLDER1"/*; do
    filename=$(basename "$file1")
    file2="$FOLDER2/$filename"

    if [ -e "$file2" ]; then
        # Если файл существует во второй папке, сравниваем их
        compare_files "$file1" "$file2"
    else
        echo "MISSING: $file1 has no corresponding file in $FOLDER2"
    fi
done

# Обходим файлы во второй папке для поиска файлов, которых нет в первой папке
for file2 in "$FOLDER2"/*; do
    filename=$(basename "$file2")
    file1="$FOLDER1/$filename"

    if [ ! -e "$file1" ]; then
        echo "MISSING: $file2 has no corresponding file in $FOLDER1"
    fi
done
