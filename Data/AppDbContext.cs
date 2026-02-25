using LojaMae.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace LojaMae.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Cliente> Clientes { get; set; } = null!;
    public DbSet<Produto> Produtos { get; set; } = null!;
    public DbSet<Venda> Vendas { get; set; } = null!;
    public DbSet<ItemVenda> ItensVenda { get; set; } = null!;
    public DbSet<Pagamento> Pagamentos { get; set; } = null!;

    // ✅ PASSO 2: DbSet Keyless para retorno da função
    public DbSet<CaixaAbertoView> CaixaAberto { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Cliente>()
            .HasIndex(c => c.Telefone)
            .IsUnique();

        modelBuilder.Entity<Cliente>().ToTable("clientes");
        modelBuilder.Entity<Produto>().ToTable("produtos");
        modelBuilder.Entity<Venda>().ToTable("vendas");
        modelBuilder.Entity<ItemVenda>().ToTable("itens_venda");
        modelBuilder.Entity<Pagamento>().ToTable("pagamentos");

        // ✅ PASSO 2: Configurar o keyless (não é tabela, nem view)
        modelBuilder.Entity<CaixaAbertoView>(e =>
        {
            e.HasNoKey();
            e.ToView(null);
        });

        // ✅ Produto
        modelBuilder.Entity<Produto>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.Nome).HasColumnName("nome");
            e.Property(x => x.Preco).HasColumnName("preco");
            e.Property(x => x.Estoque).HasColumnName("estoque");
        });

        // ✅ Venda
        modelBuilder.Entity<Venda>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.ClienteId).HasColumnName("cliente_id");
            e.Property(x => x.DataVenda).HasColumnName("data_venda");
            e.Property(x => x.Total).HasColumnName("total");
            e.Property(x => x.Status).HasColumnName("status");
            e.Property(x => x.DataFechamento).HasColumnName("data_fechamento");
            e.Property(x => x.Observacao).HasColumnName("observacao");
        });

        // ✅ ItemVenda
        modelBuilder.Entity<ItemVenda>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.VendaId).HasColumnName("venda_id");
            e.Property(x => x.ProdutoId).HasColumnName("produto_id");
            e.Property(x => x.Quantidade).HasColumnName("quantidade");
            e.Property(x => x.PrecoUnitario).HasColumnName("preco_unitario");
        });
    }
}