# Claude Restriction Scripts

Скрипты для блокировки доступа к сервисам Claude и Anthropic на уровне файла `hosts`. Доступны версии для macOS и Windows.

## Содержание

- [Что делают скрипты](#что-делают-скрипты)
- [Блокируемые домены](#блокируемые-домены)
- [Требования](#требования)
- [Использование на macOS](#использование-на-macos)
- [Использование на Windows](#использование-на-windows)
- [Где хранятся резервные копии](#где-хранятся-резервные-копии)
- [Как удалить блокировку вручную](#как-удалить-блокировку-вручную)
  - [macOS — ручное удаление](#macos--ручное-удаление)
  - [Windows — ручное удаление](#windows--ручное-удаление)
- [Восстановление из резервной копии](#восстановление-из-резервной-копии)
- [Проверка, что блокировка работает](#проверка-что-блокировка-работает)
- [Возможные проблемы](#возможные-проблемы)

## Что делают скрипты

1. Создают резервную копию текущего файла `hosts` с меткой времени.
2. Для каждого домена из списка проверяют, нет ли его уже в `hosts`.
3. Если домена нет — добавляют строку `192.0.2.1 <домен>`, перенаправляя его на адрес из зарезервированного диапазона TEST-NET-1 (RFC 5737), который гарантированно не маршрутизируется.
4. Сбрасывают DNS-кэш операционной системы, чтобы изменения вступили в силу немедленно.
5. Выводят отчёт: сколько доменов добавлено и сколько пропущено (уже были в файле).

Скрипты идемпотентны — повторный запуск не создаёт дубликатов записей.

## Блокируемые домены

- `claude.ai`, `www.claude.ai`, `api.claude.ai`
- `anthropic.com`, `www.anthropic.com`, `api.anthropic.com`
- `console.anthropic.com`, `cdn.anthropic.com`
- `statsig.anthropic.com`, `sentry.anthropic.com`, `amplitude.anthropic.com`

## Требования

- **macOS:** права администратора (скрипт сам запросит пароль).
- **Windows:** права администратора (скрипт сам перезапустится через UAC).

## Использование на macOS

1. Откройте файл `MacOS Claude Restrictions Hosts.applescript` двойным щелчком — он запустится в Script Editor.
2. Нажмите кнопку **Run** (▶) или сочетание `Cmd+R`.
3. Введите пароль администратора, когда система его запросит.
4. По завершении появится диалог с количеством добавленных и пропущенных записей.

Альтернативно через терминал:

```bash
osascript "MacOS Claude Restrictions Hosts.applescript"
```

## Использование на Windows

1. Дважды щёлкните по файлу `Windows Claude Restrictions Hosts.bat`.
2. Подтвердите запрос UAC на повышение прав.
3. Откроется окно консоли с отчётом по каждому домену (`ADD` или `SKIP`).
4. Нажмите любую клавишу для закрытия.

## Где хранятся резервные копии

- **macOS:** `/var/backups/hosts/hosts.YYYYMMDD_HHMMSS`
- **Windows:** `C:\hosts_backups\hosts.YYYYMMDD_HHMMSS`

Резервная копия создаётся при каждом запуске скрипта.

## Как удалить блокировку вручную

### macOS — ручное удаление

1. Откройте терминал и отредактируйте `/etc/hosts`:

   ```bash
   sudo nano /etc/hosts
   ```

2. Найдите и удалите строки вида:

   ```
   192.0.2.1 claude.ai
   192.0.2.1 www.claude.ai
   192.0.2.1 api.claude.ai
   192.0.2.1 anthropic.com
   192.0.2.1 www.anthropic.com
   192.0.2.1 api.anthropic.com
   192.0.2.1 console.anthropic.com
   192.0.2.1 cdn.anthropic.com
   192.0.2.1 statsig.anthropic.com
   192.0.2.1 sentry.anthropic.com
   192.0.2.1 amplitude.anthropic.com
   ```

3. Сохраните файл (`Ctrl+O`, `Enter`, `Ctrl+X`).

4. Сбросьте DNS-кэш:

   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```

Альтернативный однострочник, удаляющий все записи с `192.0.2.1` и связанными доменами:

```bash
sudo sed -i.bak '/192\.0\.2\.1.*\(claude\.ai\|anthropic\.com\)/d' /etc/hosts \
  && sudo dscacheutil -flushcache \
  && sudo killall -HUP mDNSResponder
```

### Windows — ручное удаление

1. Запустите **Блокнот** от имени администратора (правый клик → «Запуск от имени администратора»).
2. Откройте файл `C:\Windows\System32\drivers\etc\hosts`.
   - В диалоге открытия выберите «Все файлы», иначе `hosts` не будет виден.
3. Удалите строки, добавленные скриптом, например:

   ```
   192.0.2.1 claude.ai
   192.0.2.1 www.claude.ai
   192.0.2.1 api.claude.ai
   192.0.2.1 anthropic.com
   192.0.2.1 www.anthropic.com
   192.0.2.1 api.anthropic.com
   192.0.2.1 console.anthropic.com
   192.0.2.1 cdn.anthropic.com
   192.0.2.1 statsig.anthropic.com
   192.0.2.1 sentry.anthropic.com
   192.0.2.1 amplitude.anthropic.com
   ```

4. Сохраните файл (`Ctrl+S`).
5. Сбросьте DNS-кэш в командной строке от администратора:

   ```cmd
   ipconfig /flushdns
   ```

Альтернатива через PowerShell от администратора (удалит все строки, содержащие указанные домены):

```powershell
$hosts = "C:\Windows\System32\drivers\etc\hosts"
(Get-Content $hosts) |
    Where-Object { $_ -notmatch '192\.0\.2\.1.*(claude\.ai|anthropic\.com)' } |
    Set-Content $hosts -Encoding ASCII
ipconfig /flushdns
```

## Восстановление из резервной копии

Если что-то пошло не так, можно полностью восстановить `hosts` из бэкапа.

**macOS:**

```bash
ls /var/backups/hosts/
sudo cp /var/backups/hosts/hosts.YYYYMMDD_HHMMSS /etc/hosts
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Windows** (cmd от администратора):

```cmd
dir C:\hosts_backups
copy /Y C:\hosts_backups\hosts.YYYYMMDD_HHMMSS C:\Windows\System32\drivers\etc\hosts
ipconfig /flushdns
```

## Проверка, что блокировка работает

После запуска скрипта попробуйте:

```bash
ping claude.ai
```

Запросы должны идти на `192.0.2.1` и не получать ответа. В браузере страницы `claude.ai` и `anthropic.com` перестанут открываться.

После удаления блокировки `ping` снова должен резолвить реальные адреса Anthropic.

## Возможные проблемы

- **Сайты всё ещё открываются.** Браузер мог закэшировать DNS. Полностью закройте и снова откройте браузер, либо очистите его DNS-кэш (например, в Chrome: `chrome://net-internals/#dns` → Clear host cache).
- **VPN / DNS-over-HTTPS (DoH).** Если включён VPN или DoH (Cloudflare 1.1.1.1, NextDNS и т. п.), запросы могут обходить `hosts`. Отключите их или настройте блокировку на уровне VPN/DNS-сервиса.
- **Антивирус блокирует изменение `hosts`.** На Windows некоторые антивирусы защищают `hosts` от записи. Временно отключите такую защиту или добавьте файл в исключения.
- **macOS просит права повторно.** Это нормально: AppleScript выполняет команду через `do shell script ... with administrator privileges`.
