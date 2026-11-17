using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class TouristChildCreateDto
    {
        [Required(ErrorMessage = "ID туриста-родителя обязателен.")]
        public int tourist_id { get; set; }

        [Required(ErrorMessage = "Имя ребенка обязательно.")]
        [MaxLength(50, ErrorMessage = "Имя не может превышать 50 символов.")]
        public string first_name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Фамилия ребенка обязательна.")]
        [MaxLength(50, ErrorMessage = "Фамилия не может превышать 50 символов.")]
        public string last_name { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? patronymic { get; set; }

        [Required(ErrorMessage = "Дата рождения обязательна.")]
        public DateTime date_of_birth { get; set; }

        [Required(ErrorMessage = "Пол обязателен.")]
        [RegularExpression("Мужской|Женский", ErrorMessage = "Пол должен быть указан как 'Мужской' или 'Женский'.")]
        public string gender { get; set; } = string.Empty;

        [Required(ErrorMessage = "Номер свидетельства о рождении обязателен.")]
        [MaxLength(50)]
        public string birth_certificate_number { get; set; } = string.Empty;

        [Required]
        public DateTime date_of_issue { get; set; }

        [Required(ErrorMessage = "Поле 'Кем выдано' обязательно.")]
        [MaxLength(200)]
        public string issued_by { get; set; } = string.Empty;
    }
}