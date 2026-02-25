namespace LojaMae.Api.Dtos;

public class CaixaResponseDto
{
    public int Id { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal ValorInicial { get; set; }
    public decimal SaldoCaixa { get; set; }
}