#!/bin/bash

# Две директории для сравнения
dir1="path/to/first/directory"
dir2="path/to/second/directory"

# Функция для сравнения файлов
compare_files() {
    file1=$1
    file2=$2

    # Сравнение содержимого файлов
    if cmp -s "$file1" "$file2"; then
        echo "Файлы $file1 и $file2 идентичны"
    else
        echo "Файлы $file1 и $file2 отличаются"
    fi
}

# Перебор всех файлов в первой директории
for file1 in "$dir1"/*; do
    # Перебор всех файлов во второй директории
    for file2 in "$dir2"/*; do
        compare_files "$file1" "$file2"
    done
done
