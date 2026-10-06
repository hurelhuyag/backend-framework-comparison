using DemoDotnet.Dtos;
using FluentValidation;

namespace DemoDotnet.Validators;

public sealed class UpdateContentDtoValidator : AbstractValidator<UpdateContentDto>
{
    public UpdateContentDtoValidator()
    {
        RuleFor(dto => dto.Content).NotEmpty().MaximumLength(1000);
    }
}
