using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Models;

public class Caixa
{
    public int Id { get; set; }
    public DateTime DataAbertura { get; set; }

    [Precision(18, 2)]
    public decimal ValorInicial { get; set; }

    public DateTime? DataFechamento { get; set; }

    [Precision(18, 2)]
    public decimal? ValorFinal { get; set; }

    public bool Aberto { get; set; }
}