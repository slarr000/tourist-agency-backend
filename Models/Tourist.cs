namespace TouristAgencyApp.Models
{
    public class Tourist
    {
        public int tourist_id { get; set; }
        public string tourist_name { get; set; } = string.Empty;
        public string tourist_surname { get; set; } = string.Empty;
        public string tourist_patronymic { get; set; } = string.Empty;
        public DateTime tourist_date_of_birth { get; set; }
        public string tourist_gender { get; set; } = string.Empty;

        // Эти поля оставляем, если они всё ещё физически существуют в твоей таблице БД
        public string tourist_children { get; set; } = string.Empty;
        public string tourist_cargo { get; set; } = string.Empty;

        public int? flight_id { get; set; }

        // НОВЫЕ ПОЛЯ ДЛЯ ТЕХНИЧЕСКОГО ЗАДАНИЯ
        public string category { get; set; } = string.Empty;
        public bool has_visa { get; set; }
    }
}