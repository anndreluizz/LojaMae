namespace LojaMae.Api.Models;

public class Pagamento
{
    public int Id { get; set; }
    public int VendaId { get; set; }
    public decimal Valor { get; set; }
    public string? Metodo { get; set; }
    public DateTime DataPagamento { get; set; }
}