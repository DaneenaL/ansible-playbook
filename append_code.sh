#!/bin/bash
# Запускать из корня репозитория ansible-playbook: дописывает код проекта в README.md
set -e
if grep -q "^## Код проекта" README.md; then echo "уже добавлено"; exit 0; fi
{
  echo
  echo "## Код проекта"
  for f in site.yml requirements.yml ansible.cfg inventory/prod.yml group_vars/clickhouse.yml .gitignore; do
    echo
    echo "### $f"
    echo
    echo '```'
    cat "$f"
    echo '```'
  done
} >> README.md
echo "добавлено файлов: 6"
