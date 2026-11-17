namespace TouristAgencyApp.Models
{
    public class TouristChild
    {
        public int child_id { get; set; }
        public int tourist_id { get; set; }
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? patronymic { get; set; } // Значение может быть NULL
        public DateTime date_of_birth { get; set; }
        public string gender { get; set; } = string.Empty;
        public string birth_certificate_number { get; set; } = string.Empty;
        public DateTime date_of_issue { get; set; }
        public string issued_by { get; set; } = string.Empty;
    }
}