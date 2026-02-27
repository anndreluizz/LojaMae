namespace LojaMae.Api.Dtos;

public class PagamentoCreateDto
{
    public int VendaId { get; set; }
    public string Forma { get; set; } = string.Empty;
    public decimal Valor { get; set; }
}