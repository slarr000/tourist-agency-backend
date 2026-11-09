# IS Tour — система туристического агентства

Общий репозиторий API и клиентского приложения:

- `TouristAgencyApp.csproj` — ASP.NET Core API на .NET 9.
- `Database/` — SQL-скрипты PostgreSQL и демонстрационные данные.
- `client/` — React/TypeScript-приложение на Vite.

## Требования

- .NET 9 SDK
- PostgreSQL
- Node.js 20.19+ (или 22.12+) и npm

## Запуск API

Подготовьте базу PostgreSQL, используя инструкции и SQL-скрипты из
[руководства клиентского приложения](./client/README.md).

В терминале из корня репозитория задайте строку подключения через переменную
окружения. Введите пароль PostgreSQL при запросе — он не отображается и не
сохраняется в файлах проекта:

```bash
read -rsp "Пароль PostgreSQL: " DB_PASSWORD; echo
export ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=\"Touristic Firma\";Username=postgres;Password=$DB_PASSWORD"
unset DB_PASSWORD
dotnet run --launch-profile https
```

Swagger доступен по адресу `https://localhost:7062/swagger`.

## Запуск клиентского приложения

В другом терминале из корня репозитория:

```bash
cd client
npm install
cp .env.example .env
npm run dev -- --host localhost --port 5173 --strictPort
```

Откройте <http://localhost:5173>. При необходимости измените
`VITE_API_BASE_URL` в локальном `client/.env`.

Подробные инструкции по базе данных, демонстрационным данным и возможностям
интерфейса приведены в [client/README.md](./client/README.md).
