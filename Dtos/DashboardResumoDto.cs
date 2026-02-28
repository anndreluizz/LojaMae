namespace LojaMae.Api.Dtos;

public class DashboardResumoDto
{
    public bool CaixaAberto { get; set; }
    public DateOnly Dia { get; set; }
    public decimal TotalRecebidoHoje { get; set; }
}