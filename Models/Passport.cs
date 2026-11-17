namespace TouristAgencyApp.Models
{
    public class Passport
    {
        public int passport_id { get; set; }
        public int tourist_id { get; set; } // Привязка к туристу
        public string type_passport { get; set; } = string.Empty;
        public string passport_serial { get; set; } = string.Empty;
        public string passport_number { get; set; } = string.Empty;
        public DateTime date_of_issue { get; set; }
        public string issued_by { get; set; } = string.Empty;
        public string latin_name { get; set; } = string.Empty;
        public DateTime expiry_date { get; set; }
        public string department_code { get; set; } = string.Empty;
        public string registration_address { get; set; } = string.Empty;
    }
}