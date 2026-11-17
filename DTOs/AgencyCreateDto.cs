using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class AgencyCreateDto
    {
        [Required(ErrorMessage = "Название агентства обязательно.")]
        [MaxLength(100, ErrorMessage = "Название не может превышать 100 символов.")]
        public string agency_name { get; set; } = string.Empty;

        [Range(0.0, 10.0, ErrorMessage = "Рейтинг должен быть от 0 до 10.")]
        public decimal quality_rating { get; set; }
    }
}