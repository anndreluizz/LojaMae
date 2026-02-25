namespace LojaMae.Api.Dtos;

public class PagamentoResponseDto
{
    public int Id { get; set; }
    public int VendaId { get; set; }
    public decimal Valor { get; set; }
    public string FormaPagamento { get; set; } = string.Empty;
    public DateTime CriadoEm { get; set; }
}