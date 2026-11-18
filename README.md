# Домашнее задание к занятию 4 «Работа с roles»

## Ссылки на результат

- Роль Vector: https://github.com/DaneenaL/vector-role (теги v1.0.0 и v1.0.1)
- Роль LightHouse: https://github.com/DaneenaL/lighthouse-role (тег v1.0.0)
- Playbook: https://github.com/DaneenaL/ansible-playbook (этот репозиторий)

## Подготовка к выполнению

1. LightHouse по ссылке из задания (необязательный пункт) не смотрел.
2. Создал на GitHub три пустых публичных репозитория: vector-role, lighthouse-role и ansible-playbook.
3. Публичная часть SSH-ключа (id_ed25519.pub) добавлена в профиль GitHub. Сначала "ssh -T git@github.com" отвечал "Permission denied (publickey)", после добавления ключа ответил "Hi DaneenaL!".

![ssh к GitHub](screenshots/prep/01_ssh_github.png)

### Окружение

Для проверки нужны были хосты, поэтому создал их в Yandex Cloud (облако на тот момент было пустое):

![Облако пустое](screenshots/prep/02_empty_cloud.png)

- сеть ansible-net и подсеть ansible-subnet в зоне ru-central1-d (зона d работает, в других у меня бывали проблемы с ресурсами);
- две прерываемые ВМ на Ubuntu 22.04, 2 vCPU с долей 20% на platform standard-v3: clickhouse-01 (4 ГБ) и lighthouse-01 (2 ГБ).

![Сеть и подсеть](screenshots/prep/03_network_subnet.png)

![ВМ](screenshots/prep/04_vms_created.png)

Отличие от типичного варианта задания: у меня хосты на Ubuntu, а не на CentOS, поэтому роли пишу под apt и deb-пакеты.

В папке ansible-playbook сделал инвентарь inventory/prod.yml (группы clickhouse, vector и lighthouse; Vector стоит на той же ВМ, что и ClickHouse) и ansible.cfg. Проверил связь:

![ansible ping](screenshots/prep/05_ansible_ping.png)

## Основная часть

### 1. requirements.yml с ролью ClickHouse

В папке playbook создал requirements.yml ровно с тем содержимым, что дано в задании (src, scm git, версия 1.13, имя clickhouse).

### 2. Скачивание роли через ansible-galaxy

Команда: "ansible-galaxy install -r requirements.yml -p roles". Роль clickhouse 1.13 скачалась в папку roles.

![requirements и ansible-galaxy](screenshots/task1-2/01_requirements_clickhouse.png)

### 3. Каталог роли Vector

Создал каркас: "ansible-galaxy role init vector-role". Роль делал в отдельной папке рядом с playbook, потому что это отдельный репозиторий.

![ansible-galaxy role init](screenshots/task3-6/01_vector_init.png)

### 4. Задачи роли Vector, разнесение переменных

Tasks в роли такие: скачать deb-пакет, установить его через apt, положить конфиг из шаблона (с проверкой "vector validate"), включить и запустить сервис. Обработчик перезапускает сервис при смене конфига.

Переменные разнёс так:
- defaults/main.yml: то, что пользователь роли может менять (версия Vector, интервал и формат тестовых логов, имя файла конфига);
- vars/main.yml: внутренности, которые менять не нужно (имя и URL пакета, пути, имя сервиса).

![vars и defaults](screenshots/task3-6/02_vector_vars.png)

![tasks, handlers, template](screenshots/task3-6/03_vector_tasks_templates.png)

### 5. Шаблоны конфигов

Конфиг Vector лежит в templates/vector.yaml.j2. Источник demo_logs генерирует тестовые логи, приёмник file пишет их в /var/lib/vector/out.log. К ClickHouse Vector в конфиге не подключал: задание про роли, а не про пайплайн логов, поэтому оставил простой рабочий вариант.

### 6. README ролей

В каждой роли написал README.md: что делает роль, требования, таблица переменных, пример использования. Роль ClickHouse чужая (AlexeySetevoi), её документация лежит в самой роли.

![meta и README Vector](screenshots/task3-6/04_vector_meta_readme.png)

Коммит и первая попытка push. Репозиторий vector-role я ещё не создал, поэтому получил "Repository not found". Создал репозитории и повторил push, уже с тегом.

![git status](screenshots/task3-6/05_vector_git_status.png)

![Repository not found](screenshots/task3-6/06_vector_push_error.png)

![push и тег](screenshots/task3-6/07_vector_push_tag.png)

### 7. Роль LightHouse

Те же шаги 3-6 для LightHouse. Одна роль настраивает один продукт, поэтому ClickHouse и Vector в неё не входят.

Зависимости LightHouse: nginx (отдаёт статику) и git (забрать исходники). Эти пакеты ставит сама роль, отдельных ролей-зависимостей нет. Tasks: установить nginx и git, клонировать LightHouse из репозитория VKCOM в /var/www/lighthouse, убрать стандартный сайт nginx (он занимает порт 80), положить конфиг nginx из шаблона, запустить nginx. При смене конфига nginx перечитывается (reload).

Переменные: в defaults адрес репозитория, версия (ветка или тег), порт и server_name; в vars список пакетов, каталог сайта и пути конфигов.

![role init](screenshots/task7/01_lighthouse_init.png)

![vars и defaults](screenshots/task7/02_lighthouse_vars.png)

![tasks, handlers, template](screenshots/task7/03_lighthouse_tasks.png)

![git status](screenshots/task7/04_lighthouse_git_status.png)

![push и тег](screenshots/task7/05_lighthouse_push_tag.png)

### 8. Репозитории, теги, requirements.yml

Обе роли выложены в свои репозитории. Теги по семантической нумерации: vector-role v1.0.0 и v1.0.1, lighthouse-role v1.0.0.

![Теги vector-role](screenshots/task8/01_vector_tags.png)

![Теги lighthouse-role](screenshots/task8/02_lighthouse_tags.png)

Роли добавил в requirements.yml playbook, каждую с версией-тегом, и скачал:

![requirements и ansible-galaxy](screenshots/task8/03_requirements_install.png)

### 9. Playbook на ролях

Файл site.yml состоит из трёх плеев: ClickHouse (хост clickhouse), Vector (хост vector) и LightHouse (хост lighthouse). Параметры ClickHouse вынес в group_vars/clickhouse.yml, чтобы в playbook не было захардкоженных значений.

Роли совмещены с задачами:
- в плее ClickHouse в pre_tasks обновляется кеш apt, а в post_tasks создаётся база logs;
- в плее LightHouse в post_tasks проверяется, что страница отвечает кодом 200.

Проверка синтаксиса:

![syntax-check](screenshots/task9/01_syntax_check.png)

#### Что ломалось при запуске

Первые запуски падали, ошибки были по моей вине:

1. "no command given" в моей задаче создания базы. На Ansible 2.9 модуль command с полным именем ansible.builtin.command не принимает команду одной строкой. Заменил на короткое имя "command".

![no command given](screenshots/task9/02_error_command.png)

2. "Connection refused (localhost:9000)". Сервер ClickHouse слушает только 0.0.0.0, то есть только IPv4, а localhost на хосте резолвится в ::1, куда клиент и пошёл. Это подтвердил командой ss. Исправил: адрес клиента вынес в переменную clickhouse_client_host со значением 127.0.0.1.

![Connection refused](screenshots/task9/03_error_clickhouse_localhost.png)

![ss: порты слушают на 0.0.0.0](screenshots/task9/04_ss_listen.png)

3. В роли Vector проверка конфига падала с "TOML parse error". Ansible проверяет конфиг во временном файле без расширения, и Vector считал его TOML, а у меня YAML. Исправил в самой роли, добавив флаг "--config-yaml" к команде validate, и выпустил тег v1.0.1. В requirements.yml playbook обновил версию роли Vector на v1.0.1 и перекачал роль с --force.

![TOML parse error](screenshots/task9/05_error_vector_validate.png)

![Исправление и тег v1.0.1](screenshots/task9/06_vector_fix_push.png)

#### Результат

Запуск прошёл без ошибок (failed=0 на обоих хостах):

![Успешный запуск](screenshots/task9/07_run_ok.png)

Повторный запуск показал changed=0 (playbook идемпотентный). Vector активен и пишет логи в файл, nginx отвечает 200:

![Повторный запуск и проверки](screenshots/task9/08_second_run_checks.png)

База logs создалась в ClickHouse:

![SHOW DATABASES](screenshots/task9/09_show_databases.png)

LightHouse открывается в браузере. К ClickHouse из интерфейса я не подключался (по умолчанию он предлагает 127.0.0.1:8123), проверял только то, что страница отдаётся.

![LightHouse в браузере](screenshots/task9/10_lighthouse_browser.png)

### 10. Playbook в репозитории

Playbook выложен в этот репозиторий: site.yml, inventory, ansible.cfg, group_vars и requirements.yml. Скачанные роли (папка roles) в git не кладу, их ставит ansible-galaxy по requirements.yml. Код файлов приведён в конце README.

### 11. Ссылки

- Роль Vector: https://github.com/DaneenaL/vector-role
- Роль LightHouse: https://github.com/DaneenaL/lighthouse-role
- Playbook: https://github.com/DaneenaL/ansible-playbook

## Удаление ресурсов

После проверки удалил ВМ, подсеть и сеть. Облако снова пустое:

![Облако пустое](screenshots/cleanup/01_cloud_empty.png)

## Код проекта

### site.yml

```
---
- name: Install ClickHouse
  hosts: clickhouse
  pre_tasks:
    - name: Обновить кеш apt перед установкой
      become: true
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
  roles:
    - clickhouse
  post_tasks:
    - name: Создать базу для логов
      command: "clickhouse-client --host {{ clickhouse_client_host }} -q 'CREATE DATABASE IF NOT EXISTS {{ clickhouse_log_db }}'"
      changed_when: false

- name: Install Vector
  hosts: vector
  roles:
    - vector-role

- name: Install LightHouse
  hosts: lighthouse
  roles:
    - lighthouse-role
  post_tasks:
    - name: Проверить, что LightHouse отвечает по HTTP
      ansible.builtin.uri:
        url: "http://{{ ansible_host }}:{{ lighthouse_port }}/"
        status_code: 200
      delegate_to: localhost
```

### requirements.yml

```
---
  - src: git@github.com:AlexeySetevoi/ansible-clickhouse.git
    scm: git
    version: "1.13"
    name: clickhouse

  - src: git@github.com:DaneenaL/vector-role.git
    scm: git
    version: "v1.0.1"
    name: vector-role

  - src: git@github.com:DaneenaL/lighthouse-role.git
    scm: git
    version: "v1.0.0"
    name: lighthouse-role
```

### ansible.cfg

```
[defaults]
host_key_checking = False
inventory = inventory/prod.yml
roles_path = roles
```

### inventory/prod.yml

```
---
all:
  children:
    clickhouse:
      hosts:
        clickhouse-01:
          ansible_host: 153.51.171.158
    vector:
      hosts:
        clickhouse-01:
    lighthouse:
      hosts:
        lighthouse-01:
          ansible_host: 153.51.164.162
  vars:
    ansible_user: yc-user
```

### group_vars/clickhouse.yml

```
---
clickhouse_version: "22.3.3.44"
clickhouse_listen_host:
  - "0.0.0.0"
clickhouse_log_db: logs
clickhouse_client_host: "127.0.0.1"
```

### .gitignore

```
roles/
*.retry
```
