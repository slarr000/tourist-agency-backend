using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class TouristCargoCreateDto : IValidatableObject
    {
        [Required]
        public int tourist_id { get; set; }

        [Required(ErrorMessage = "Укажите дату приёма груза на склад.")]
        public DateOnly? received_date { get; set; }
        public DateOnly? shipped_date { get; set; }

        [Required(ErrorMessage = "Тип груза обязателен.")]
        [MaxLength(100)]
        public string cargo_type { get; set; } = string.Empty;

        [Required]
        [Range(1, 1000, ErrorMessage = "Количество мест должно быть не менее 1.")]
        public int places_count { get; set; }

        [Required]
        [Range(0.1, 100000.0, ErrorMessage = "Фактический вес должен быть больше нуля.")]
        public decimal actual_weight { get; set; }

        [Required]
        [Range(0.0, 100000.0)]
        public decimal volume_weight { get; set; }

        [MaxLength(100)]
        public string marking { get; set; } = string.Empty;

        [MaxLength(100)]
        public string tags { get; set; } = string.Empty;

        public decimal packaging_cost { get; set; }
        public decimal insurance_cost { get; set; }
        public decimal total_amount { get; set; }

        [Required]
        public int flight_id { get; set; }

        [Required]
        [RegularExpression("Принят на склад|Упакован|Готов к отправке|Отправлен")]
        public string status { get; set; } = "Принят на склад";

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (status != "Отправлен" && shipped_date is not null)
                yield return new ValidationResult("Дата отправки допустима только для отправленного груза.", [nameof(shipped_date)]);
            if (shipped_date is not null && received_date is not null && shipped_date < received_date)
                yield return new ValidationResult("Дата отправки не может быть раньше даты приёма.", [nameof(shipped_date)]);
        }
    }
}