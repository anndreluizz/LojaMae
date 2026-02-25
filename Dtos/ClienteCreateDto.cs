using System.ComponentModel.DataAnnotations;

namespace LojaMae.Api.Dtos;

public class ClienteCreateDto
{
    [Required]
    [MaxLength(150)]
    public string Nome { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Telefone { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? Cidade { get; set; }
}