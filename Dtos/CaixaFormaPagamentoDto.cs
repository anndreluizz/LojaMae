namespace LojaMae.Api.Dtos;

public class CaixaFormaPagamentoDto
{
    public string FormaPagamento { get; set; } = string.Empty;
    public decimal Total { get; set; }
}