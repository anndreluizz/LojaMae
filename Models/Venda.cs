namespace LojaMae.Api.Models;

public class Venda
{
    public int Id { get; set; }
    public int ClienteId { get; set; }
    public DateTime DataVenda { get; set; }
    public decimal Total { get; set; }
    public decimal Desconto { get; set; } = 0;
    public string Status { get; set; } = "RASCUNHO";
    public DateTime? DataFechamento { get; set; }
    public string? Observacao { get; set; }
}