namespace LojaMae.Api.Models;

public class Pagamento
{
    public int Id { get; set; }
    public int VendaId { get; set; }

    public string Forma { get; set; } = string.Empty;  // ✅ precisa existir

    public decimal Valor { get; set; }
    public DateTime DataPagamento { get; set; }
}