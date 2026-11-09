namespace TouristAgencyApp.ReportDTOs
{
    public class HotelCheckInListDto
    {
        public string HotelName { get; set; } = string.Empty;
        public string TouristFullName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public DateTime? CheckInDate { get; set; }
        public DateTime? CheckOutDate { get; set; }
        public string RoomNumber { get; set; } = string.Empty; // Добавили номер комнаты
        public string AccompanyingChildren { get; set; } = string.Empty;
        public long ChildrenCount { get; set; }
    }
}