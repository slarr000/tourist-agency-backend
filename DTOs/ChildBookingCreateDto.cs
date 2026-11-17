using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs;

public class ChildBookingCreateDto
{
    [Range(1, int.MaxValue)]
    public int tourist_id { get; set; }
    [Range(1, int.MaxValue)]
    public int visit_id { get; set; }
    [Range(1, int.MaxValue)]
    public int booking_id { get; set; }
    [Range(1, int.MaxValue)]
    public int child_id { get; set; }
}
