using System.ComponentModel.DataAnnotations;

namespace LojaMae.Api.Dtos;

public class PagamentoCreateDto
{
    [Required]
    [Range(0.01, 999999999)]
    public decimal Valor { get; set; }

    [Required]
    [MaxLength(30)]
    public string FormaPagamento { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? Observacao { get; set; }
}