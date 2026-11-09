using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class FlightCreateDto
    {
        [Required(ErrorMessage = "Номер рейса обязателен.")]
        [MaxLength(50)]
        public string flight_number { get; set; } = string.Empty;

        [Required]
        public DateTime flight_date { get; set; }

        [Required(ErrorMessage = "Тип самолета обязателен.")]
        [MaxLength(100)]
        public string aircraft_type { get; set; } = string.Empty;

        // НОВОЕ ПОЛЕ: Тип рейса
        [Required(ErrorMessage = "Тип рейса обязателен.")]
        [MaxLength(50)]
        public string flight_type { get; set; } = string.Empty;

        [Range(0, 1000, ErrorMessage = "Количество мест должно быть от 0 до 1000.")]
        public int seat_capacity { get; set; }
    }
}