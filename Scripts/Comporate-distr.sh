#!/bin/bash

# Убедимся, что передано два аргумента
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 <директория1> <директория2>"
    exit 1
fi

dir1=$1
dir2=$2

# Проверяем, что обе директории существуют
if [ ! -d "$dir1" ]; then
    echo "Директория $dir1 не существует"
    exit 1
fi

if [ ! -d "$dir2" ]; then
    echo "Директория $dir2 не существует"
    exit 1
fi

# Сравниваем содержимое файлов в двух директориях
for file1 in "$dir1"/*; do
    match_found=false
    for file2 in "$dir2"/*; do
        if cmp -s "$file1" "$file2"; then
            match_found=true
            break
        fi
    done

    if ! $match_found; then
        echo "Файл $(basename "$file1") из $dir1 не имеет соответствия в $dir2"
    fi
done

for file2 in "$dir2"/*; do
    match_found=false
    for file1 in "$dir1"/*; do
        if cmp -s "$file1" "$file2"; then
            match_found=true
            break
        fi
    done

    if ! $match_found; then
        echo "Файл $(basename "$file2") из $dir2 не имеет соответствия в $dir1"
    fi
done

echo "Сравнение завершено"
