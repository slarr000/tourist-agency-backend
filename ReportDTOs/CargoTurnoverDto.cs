namespace TouristAgencyApp.ReportDTOs;

public class CargoTurnoverDto
{
    public long TotalPlaces { get; set; }
    public decimal ActualWeight { get; set; }
    public decimal VolumeWeight { get; set; }
    public long FlightsWithCargo { get; set; }
    public long CargoOnlyFlights { get; set; }
    public long PassengerCargoFlights { get; set; }
}
