using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Models;

[Keyless]
public class CaixaAbertoView
{
    // ⚠️ AJUSTE estes campos para bater com o retorno da função public.caixa_aberto()
    public int VendaId { get; set; }
    public decimal Total { get; set; }
    public DateTime DataAbertura { get; set; }
}