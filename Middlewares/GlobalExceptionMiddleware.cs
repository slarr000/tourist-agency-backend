using System.Net;
using System.Text.Json;
using Npgsql;

namespace TouristAgencyApp.Middlewares
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                // Попытка передать запрос дальше по конвейеру
                await _next(context);
            }
            catch (Exception ex)
            {
                // Если где-то произошла ошибка, перехватываем её и логируем
                _logger.LogError(ex, "Произошла необработанная ошибка во время выполнения запроса.");
                await HandleExceptionAsync(context, ex);
            }
        }

        private static Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            if (exception is PostgresException { SqlState: "23514" } constraintException)
            {
                context.Response.ContentType = "application/json";
                context.Response.StatusCode = StatusCodes.Status400BadRequest;
                return context.Response.WriteAsync(JsonSerializer.Serialize(new
                {
                    statusCode = context.Response.StatusCode,
                    message = constraintException.MessageText
                }));
            }

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError; // Код 500

            // Формируем красивый JSON-ответ
            var response = new
            {
                StatusCode = context.Response.StatusCode,
                Message = "Внутренняя ошибка сервера. Мы уже работаем над решением проблемы.",
                // Оставляем техническую деталь для удобства отладки курсового проекта
                DetailedError = exception.Message
            };

            var jsonResponse = JsonSerializer.Serialize(response);
            return context.Response.WriteAsync(jsonResponse);
        }
    }
}