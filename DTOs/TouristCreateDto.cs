using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class TouristCreateDto
    {
        [Required(ErrorMessage = "Имя обязательно.")]
        [MaxLength(50)]
        public string tourist_name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Фамилия обязательна.")]
        [MaxLength(50)]
        public string tourist_surname { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? tourist_patronymic { get; set; }

        [Required]
        public DateTime tourist_date_of_birth { get; set; }

        [Required]
        [MaxLength(20)]
        public string tourist_gender { get; set; } = string.Empty;

        // Те самые поля, из-за которых ломался Dapper
        [Required]
        [MaxLength(10)]
        public string tourist_children { get; set; } = "Нет";

        [MaxLength(10)]
        public string? tourist_cargo { get; set; } = "Нет";

        // Новые поля для бизнес-логики агентства
        [Required]
        [MaxLength(50)]
        public string category { get; set; } = string.Empty;

        [Required]
        public bool has_visa { get; set; }

        public int? flight_id { get; set; }
    }
}