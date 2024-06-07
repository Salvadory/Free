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

# Функция для создания контрольной суммы для каждого файла
generate_checksums() {
    dir=$1
    find "$dir" -type f -exec md5sum {} \; | sort -k 1
}

# Создаем контрольные суммы для файлов в обеих директориях
checksums1=$(generate_checksums "$dir1")
checksums2=$(generate_checksums "$dir2")

# Сравниваем контрольные суммы
if [ "$checksums1" == "$checksums2" ]; then
    echo "Все файлы в обеих директориях совпадают по содержимому"
else
    echo "Есть различия в содержимом файлов между двумя директориями"
    echo "Файлы, отличающиеся по содержимому:"

    # Найдем различия
    diff <(echo "$checksums1") <(echo "$checksums2") | grep '^<' | awk '{print $2}'
    diff <(echo "$checksums1") <(echo "$checksums2") | grep '^>' | awk '{print $2}'
fi

echo "Сравнение завершено"
