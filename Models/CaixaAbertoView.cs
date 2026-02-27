using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Models;

[Keyless]
public class CaixaAbertoView
{
    public int Id { get; set; }
    public DateTime DataAbertura { get; set; }
    public DateTime? DataFechamento { get; set; }

    public decimal ValorInicial { get; set; }
    public decimal TotalPagamentos { get; set; }
    public decimal SaldoAtual { get; set; }

    public bool Aberto { get; set; }
}