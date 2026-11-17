namespace TouristAgencyApp.Models;

public class DocumentEvent
{
    public int document_event_id { get; set; }
    public int tourist_id { get; set; }
    public int? child_id { get; set; }
    public string document_type { get; set; } = string.Empty;
    public DateOnly processed_date { get; set; }
}
