namespace LojaMae.Api.Dtos;

public class PagamentoResponseDto
{
    public int Id { get; set; }
    public int VendaId { get; set; }
    public int CaixaId { get; set; }          // ✅ precisa existir
    public string Forma { get; set; } = string.Empty;
    public decimal Valor { get; set; }
    public DateTime DataPagamento { get; set; } // ✅ precisa existir
}