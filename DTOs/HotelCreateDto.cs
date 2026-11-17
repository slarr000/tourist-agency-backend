using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class HotelCreateDto
    {
        [Required(ErrorMessage = "Название гостиницы обязательно для заполнения.")]
        [MaxLength(150, ErrorMessage = "Максимальная длина названия - 150 символов.")]
        public string hotel_name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Укажите страну гостиницы.")]
        [MaxLength(100)]
        public string country { get; set; } = string.Empty;

        [Required(ErrorMessage = "Укажите количество звезд.")]
        [Range(1, 5, ErrorMessage = "Количество звезд должно быть от 1 до 5.")]
        public int stars_count { get; set; }

        [Required(ErrorMessage = "Адрес обязателен.")]
        public string address { get; set; } = string.Empty;

        [Required]
        [Range(0.01, 100000.00, ErrorMessage = "Цена за ночь должна быть больше нуля.")]
        public decimal price_per_night { get; set; }
    }
}