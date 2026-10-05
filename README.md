# Sandyk — дополнение для Home Assistant

Сервер [Sandyk](https://github.com/Keremet-DEV/sandyk-server) как дополнение Home
Assistant OS / Supervised: бэкап фото, видео и файлов с телефона, поиск дубликатов,
освобождение места на устройстве. Работает на amd64 и aarch64 (Raspberry Pi 4/5, Green, Yellow); armv7 Home Assistant
больше не поддерживает (с 2025.12).

## Установка

1. **Настройки → Дополнения → Магазин дополнений → ⋮ → Репозитории**, добавить
   `https://github.com/Keremet-DEV/sandyk-ha-addon`.
2. Найти **Sandyk**, **Установить**, **Запустить**, **Открыть веб-интерфейс**.
3. Первый зарегистрированный пользователь — админ.

Настройки и подробности — [sandyk/DOCS.md](sandyk/DOCS.md) (их же показывает Home
Assistant на вкладке «Документация»).

## Как устроено

Дополнение — образ сервера `ghcr.io/keremet-dev/sandyk-server:<версия>` плюс
`run.sh`: тот превращает настройки дополнения (`/data/options.json`) в переменные `FM_*`,
готовит папки и запускает сервер от uid 65532. Домашние адреса по умолчанию берутся из
Supervisor API (`hassio_api`).

- База — `/data/sandyk` (входит в бэкапы Home Assistant), файлы — `storage_dir`
  (по умолчанию `/share/sandyk`).
- Новая версия сервера: тег `vX.Y.Z` в sandyk-server, затем здесь тот же номер в
  `sandyk/config.yaml` (`version`), `sandyk/build.yaml`, `Dockerfile` и запись в
  `CHANGELOG.md`.

## Проверка

```sh
scripts/test.sh                 # собрать и запустить, как это делает Supervisor (Docker)
scripts/test.sh sandyk-server:host   # с локально собранным образом сервера
```
