using System.ComponentModel.DataAnnotations;

namespace TouristAgencyApp.DTOs;

public class DocumentEventCreateDto : IValidatableObject
{
    [Range(1, int.MaxValue)]
    public int tourist_id { get; set; }

    [Range(1, int.MaxValue)]
    public int? child_id { get; set; }

    [Required]
    [RegularExpression("Паспортные документы|Виза|Документ ребёнка")]
    public string document_type { get; set; } = string.Empty;

    [Required]
    public DateOnly? processed_date { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if ((document_type == "Документ ребёнка") != child_id.HasValue)
        {
            yield return new ValidationResult(
                "Ребёнка необходимо указать только для документа ребёнка.",
                [nameof(child_id), nameof(document_type)]);
        }
    }
}
