namespace TouristAgencyApp.DTOs
{
    public class HotelQueryParameters
    {
        // Поиск по названию
        public string? SearchTerm { get; set; }

        // Фильтры
        public int? MinStars { get; set; }
        public decimal? MaxPrice { get; set; }

        // Пагинация (по умолчанию 1-я страница, 10 записей на страницу)
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}