############################################################################################################
#################################################Export####################################################
############################################################################################################
#!/bin/bash

# Функция для рекурсивного экспорта секретов с версиями
export_secrets() {
    local path="$1"
    local base_path="$2"

    # Получаем список всех ключей и директорий в текущем пути
    local keys=$(vault kv list -format=json "$path" | jq -r '.[]')

    for key in $keys; do
        if [[ "$key" == */ ]]; then
            # Если это директория, создаем соответствующую директорию и рекурсивно экспортируем её содержимое
            mkdir -p "$base_path/$key"
            export_secrets "$path/$key" "$base_path/$key"
        else
            # Если это секрет, экспортируем его версии в файлы
            local secret_path="$path/$key"
            local output_dir="$base_path/$key"
            mkdir -p "$output_dir"

            local versions=$(vault kv metadata get -format=json "$secret_path" | jq '.data.versions|keys|join("\n")' -r)

            for version in $versions; do
                local output_file="$output_dir/version_$version.json"
                vault kv get -version="$version" -format=json -field=data "$secret_path" > "$output_file"
                echo "Секрет $secret_path версии $version экспортирован в $output_file"
            done
        fi
    done
}

# Указание корневого пути в Vault
ROOT_PATH="kv1/"
# Указание корневого пути для экспорта
EXPORT_DIR="/scr1/Export/"

# Создаем корневую директорию для экспорта
mkdir -p "$EXPORT_DIR"

# Запуск функции для корневого пути
export_secrets "$ROOT_PATH" "$EXPORT_DIR"

############################################################################################################
################################################Import####################################################
############################################################################################################

#!/bin/bash

# Функция для рекурсивного импорта секретов с версиями
import_secrets() {
    local path="$1"
    local base_path="$2"
    
    echo "Обработка директории: $path"

    # Рекурсивно обходим все файлы и директории в текущем пути
    for entry in "$path"/*; do
        if [[ -d "$entry" ]]; then
            echo "Найдена директория: $entry"
            # Если это директория, рекурсивно импортируем её содержимое
            import_secrets "$entry" "$base_path"
        elif [[ -f "$entry" && "$entry" == *version_*.json ]]; then
            echo "Найден файл версии: $entry"
            # Если это JSON-файл, импортируем его как секрет определенной версии
            local relative_path="${entry#$base_path/}"
            local secret_path="${relative_path%/version_*}"
            local version="${relative_path#*version_}"
            version="${version%.json}"
            local secret_data=$(jq . "$entry")

            echo "Импортируем секрет из файла $entry в путь $ROOT_PATH/$secret_path с версией $version"
            echo "Данные секрета: $secret_data"

            tmp_file=$(mktemp)
            echo "$secret_data" > "$tmp_file"
            
            vault kv put "$ROOT_PATH$secret_path" @$tmp_file
            if [[ $? -eq 0 ]]; then
                echo "Секрет из $entry версии $version успешно импортирован в Vault по пути $ROOT_PATH/$secret_path"
            else
                echo "Ошибка при импорте секрета из $entry версии $version в Vault по пути $ROOT_PATH/$secret_path" >&2
            fi

            rm "$tmp_file"
        else
            echo "Пропущен элемент: $entry"
        fi
    done
}

# Указание корневого пути для импорта
IMPORT_DIR="/scr1/Export/"
ROOT_PATH="kv2/"
# Запуск функции для корневого пути
import_secrets "$IMPORT_DIR" "$IMPORT_DIR"

############################################################################################################
##############################################Import c проверкой############################################
############################################################################################################

#!/bin/bash

# Функция для рекурсивного импорта секретов с версиями
import_secrets() {
    local path="$1"
    local base_path="$2"
    
    echo "Обработка директории: $path"

    # Рекурсивно обходим все файлы и директории в текущем пути
    for entry in "$path"/*; do
        if [[ -d "$entry" ]]; then
            echo "Найдена директория: $entry"
            # Если это директория, рекурсивно импортируем её содержимое
            import_secrets "$entry" "$base_path"
        fi
    done

    # Получаем список версий, сортируем их и импортируем в правильном порядке
    for entry in $(ls "$path" | grep 'version_' | sort -V); do
        local file_path="$path/$entry"
        echo "Найден файл версии: $file_path"
        # Если это JSON-файл, импортируем его как секрет определенной версии
        local relative_path="${file_path#$base_path/}"
        local secret_path="${relative_path%/version_*}"
        local version="${relative_path#*version_}"
        version="${version%.json}"
        local secret_data=$(jq . "$file_path")

        # Проверка наличия версии секрета в Vault
        if vault kv get -version="$version" "$ROOT_PATH$secret_path" > /dev/null 2>&1; then
            echo "Секрет $secret_path версии $version уже существует, проверка данных..."
            local existing_data=$(vault kv get -version="$version" -format=json "$ROOT_PATH$secret_path" | jq .data.data)
            if [[ "$existing_data" == "$secret_data" ]]; then
                echo "Данные секрета $secret_path версии $version совпадают, пропуск..."
            else
                echo "Данные секрета $secret_path версии $version отличаются, обновление..."
                tmp_file=$(mktemp)
                echo "$secret_data" > "$tmp_file"
                
                vault kv put "$ROOT_PATH$secret_path" @$tmp_file
                if [[ $? -eq 0 ]]; then
                    echo "Секрет из $file_path версии $version успешно обновлен в Vault по пути $ROOT_PATH$secret_path"
                else
                    echo "Ошибка при обновлении секрета из $file_path версии $version в Vault по пути $ROOT_PATH$secret_path" >&2
                fi

                rm "$tmp_file"
            fi
        else
            echo "Импортируем секрет из файла $file_path в путь $ROOT_PATH$secret_path с версией $version"
            tmp_file=$(mktemp)
            echo "$secret_data" > "$tmp_file"
            
            vault kv put "$ROOT_PATH$secret_path" @$tmp_file
            if [[ $? -eq 0 ]]; then
                echo "Секрет из $file_path версии $version успешно импортирован в Vault по пути $ROOT_PATH$secret_path"
            else
                echo "Ошибка при импорте секрета из $file_path версии $version в Vault по пути $ROOT_PATH$secret_path" >&2
            fi

            rm "$tmp_file"
        fi
    done
}

# Указание корневого пути для импорта
IMPORT_DIR="/scr1/Export/"
ROOT_PATH="$kv2/"

# Запуск функции для корневого пути
import_secrets "$IMPORT_DIR" "$IMPORT_DIR"




