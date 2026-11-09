using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class FinanceCreateDto
    {
        [Required(ErrorMessage = "Укажите тип транзакции (Доход/Расход).")]
        [MaxLength(50)]
        public string transaction_type { get; set; } = string.Empty;

        [Required(ErrorMessage = "Укажите категорию (Отель, Экскурсия, Таможня и т.д.).")]
        [MaxLength(100)]
        public string category { get; set; } = string.Empty;

        [Required]
        [Range(0.01, 10000000.00, ErrorMessage = "Сумма должна быть больше нуля.")]
        public decimal amount { get; set; }

        [Required]
        public DateTime transaction_date { get; set; }

        public string? description { get; set; }
        public int? flight_id { get; set; }
        public int? tourist_id { get; set; }
    }
}