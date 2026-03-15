using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LojaMae.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddCodigoBarrasApenas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "data_venda",
                table: "vendas",
                type: "timestamptz",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_fechamento",
                table: "vendas",
                type: "timestamptz",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Desconto",
                table: "vendas",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "CodigoBarras",
                table: "produtos",
                type: "text",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_pagamento",
                table: "pagamentos",
                type: "timestamptz",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AddColumn<int>(
                name: "caixa_id",
                table: "pagamentos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_fechamento",
                table: "caixas",
                type: "timestamptz",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_abertura",
                table: "caixas",
                type: "timestamptz",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.CreateIndex(
                name: "IX_pagamentos_caixa_id",
                table: "pagamentos",
                column: "caixa_id");

            migrationBuilder.CreateIndex(
                name: "IX_pagamentos_venda_id",
                table: "pagamentos",
                column: "venda_id");

            migrationBuilder.AddForeignKey(
                name: "FK_pagamentos_caixas_caixa_id",
                table: "pagamentos",
                column: "caixa_id",
                principalTable: "caixas",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_pagamentos_vendas_venda_id",
                table: "pagamentos",
                column: "venda_id",
                principalTable: "vendas",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_pagamentos_caixas_caixa_id",
                table: "pagamentos");

            migrationBuilder.DropForeignKey(
                name: "FK_pagamentos_vendas_venda_id",
                table: "pagamentos");

            migrationBuilder.DropIndex(
                name: "IX_pagamentos_caixa_id",
                table: "pagamentos");

            migrationBuilder.DropIndex(
                name: "IX_pagamentos_venda_id",
                table: "pagamentos");

            migrationBuilder.DropColumn(
                name: "Desconto",
                table: "vendas");

            migrationBuilder.DropColumn(
                name: "CodigoBarras",
                table: "produtos");

            migrationBuilder.DropColumn(
                name: "caixa_id",
                table: "pagamentos");

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_venda",
                table: "vendas",
                type: "timestamp with time zone",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamptz");

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_fechamento",
                table: "vendas",
                type: "timestamp with time zone",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamptz",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_pagamento",
                table: "pagamentos",
                type: "timestamp with time zone",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamptz");

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_fechamento",
                table: "caixas",
                type: "timestamp with time zone",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamptz",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "data_abertura",
                table: "caixas",
                type: "timestamp with time zone",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamptz");
        }
    }
}
