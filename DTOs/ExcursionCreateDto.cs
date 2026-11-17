using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class ExcursionCreateDto
    {
        [Required]
        public int agency_id { get; set; }

        [Required(ErrorMessage = "Название экскурсии обязательно.")]
        [MaxLength(150)]
        public string excursion_name { get; set; } = string.Empty;

        [Required]
        public DateTime schedule_date { get; set; }

        [Required]
        [Range(0.01, 1000000.00, ErrorMessage = "Цена должна быть больше нуля.")]
        public decimal price { get; set; }
    }
}