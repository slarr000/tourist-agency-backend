using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class ExcursionBookingCreateDto
    {
        [Required]
        public int tourist_id { get; set; }

        [Required]
        public int excursion_id { get; set; }

        public int? child_id { get; set; }
    }
}