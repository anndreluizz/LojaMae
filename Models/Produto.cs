using System;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations.Schema;

namespace LojaMae.Api.Models;

public class Produto
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public decimal Preco { get; set; }
    public int Estoque { get; set; }
    public DateTime DataCadastro { get; set; }

    // Mapeia o JSON "codigoBarras" do Flutter para esta propriedade
    [JsonPropertyName("codigoBarras")]
    // Garante que o EF/Core use exatamente a coluna "CodigoBarras" no banco (case-sensitive se criada com aspas)
    [Column("CodigoBarras")]
    public string? CodigoBarras { get; set; }
}