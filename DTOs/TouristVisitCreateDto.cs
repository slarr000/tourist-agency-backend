using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs
{
    public class TouristVisitCreateDto
    {
        [Required]
        public int tourist_id { get; set; }

        [Required]
        public int flight_id { get; set; }

        [Required]
        public DateTime arrival_date { get; set; }

        [Required]
        public DateTime departure_date { get; set; }
    }
}