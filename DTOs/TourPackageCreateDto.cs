using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs;

public class TourPackageCreateDto : IValidatableObject
{
    [Required, MaxLength(60)]
    public string package_code { get; set; } = string.Empty;
    [Required, MaxLength(150)]
    public string package_name { get; set; } = string.Empty;
    [Required, MaxLength(100)]
    public string destination { get; set; } = string.Empty;
    [Required, RegularExpression("Отдых|Шоп-тур")]
    public string category { get; set; } = string.Empty;
    [Required, Range(typeof(decimal), "0", "9999999999.99", ParseLimitsInInvariantCulture = true)]
    public decimal? price { get; set; }
    [Required, Range(0, int.MaxValue)]
    public int? monthly_capacity { get; set; }
    public DateOnly? available_from { get; set; }
    public DateOnly? available_until { get; set; }
    [Required]
    public bool? is_active { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (available_from > available_until)
            yield return new ValidationResult("Начало доступности не может быть позже окончания.", [nameof(available_from), nameof(available_until)]);
    }
}
