using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class PassportCreateDto
    {
        [Required]
        public int tourist_id { get; set; }

        [Required(ErrorMessage = "Тип паспорта обязателен.")]
        [MaxLength(50)]
        public string type_passport { get; set; } = string.Empty;

        [Required(ErrorMessage = "Серия паспорта обязательна.")]
        [MaxLength(20)]
        public string passport_serial { get; set; } = string.Empty;

        [Required(ErrorMessage = "Номер паспорта обязателен.")]
        [MaxLength(50)]
        public string passport_number { get; set; } = string.Empty;

        [Required]
        public DateTime date_of_issue { get; set; }

        [Required(ErrorMessage = "Поле 'Кем выдано' обязательно.")]
        [MaxLength(200)]
        public string issued_by { get; set; } = string.Empty;

        [Required(ErrorMessage = "Имя латиницей обязательно.")]
        [MaxLength(100)]
        public string latin_name { get; set; } = string.Empty;

        [Required]
        public DateTime expiry_date { get; set; }

        [Required(ErrorMessage = "Код подразделения обязателен.")]
        [MaxLength(20)]
        public string department_code { get; set; } = string.Empty;

        [Required(ErrorMessage = "Адрес регистрации обязателен.")]
        [MaxLength(250)]
        public string registration_address { get; set; } = string.Empty;
    }
}