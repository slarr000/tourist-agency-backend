using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class BookingCreateDto
    {
        [Required]
        public int tourist_id { get; set; }

        [Required(ErrorMessage = "Выберите поездку туриста.")]
        [Range(1, int.MaxValue, ErrorMessage = "Выберите корректную поездку туриста.")]
        public int? visit_id { get; set; }

        [Required]
        public int hotel_id { get; set; }

        [Required]
        public DateTime check_in_date { get; set; }

        [Required]
        public DateTime check_out_date { get; set; }

        [Required(ErrorMessage = "Номер комнаты обязателен.")]
        [MaxLength(50)]
        public string room_number { get; set; } = string.Empty;
    }
}