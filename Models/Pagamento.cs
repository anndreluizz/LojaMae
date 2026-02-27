namespace LojaMae.Api.Models;

public class Pagamento
{
    public int Id { get; set; }

    public int VendaId { get; set; }
    public Venda Venda { get; set; } = null!;

    public int CaixaId { get; set; }
    public Caixa Caixa { get; set; } = null!;

    public string Forma { get; set; } = string.Empty;

    public decimal Valor { get; set; }

    public DateTime DataPagamento { get; set; }
}