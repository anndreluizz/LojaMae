namespace LojaMae.Api.Dtos;

public class DashboardResumoDto
{
    public decimal FaturamentoTotal { get; set; }
    public int TotalVendas { get; set; }
    public List<DashboardFormaPagamentoDto> Pagamentos { get; set; } = new();
}

public class DashboardFormaPagamentoDto
{
    public string Forma { get; set; } = "";
    public decimal Total { get; set; }
}