# Tech Challenge Fase 3 — Pipeline de Dados AWS | State of Data Brasil

Pipeline de engenharia de dados em arquitetura medalhão (Bronze → Silver → Gold) construído na AWS, usando a base **State of Data Brasil** (Data Hackers + Bain), anos 2023, 2024 e 2025-2026 — desenvolvido como parte do Tech Challenge da Fase 3 da Pós Tech em Data Analytics (FIAP).

## O que este projeto faz

Transforma ~14.000 respostas brutas de pesquisa (3 arquivos CSV, com estruturas de colunas diferentes entre os anos) numa base analítica única e tratada, pronta para consumo em dashboards executivos — respondendo perguntas sobre estrutura do mercado, remuneração, diversidade, adoção de tecnologia e IA generativa no setor de dados no Brasil.

## Arquitetura

![Arquitetura AWS](diagramas/arquitetura.png)

| Camada | Serviço AWS | O que acontece |
|---|---|---|
| Ingestão (Bronze) | Amazon S3 | Armazena os 3 CSVs brutos, sem nenhum tratamento |
| Catalogação | AWS Glue Crawler + Data Catalog | Descobre e registra o schema da Bronze |
| Tratamento (Silver) | AWS Glue (PySpark) | Mapeia 421 colunas de negócio entre os 3 anos, remove duplicatas, padroniza tipos |
| Agregação (Gold) | Amazon Athena (CTAS) | Une as 3 Silver e gera 7 tabelas temáticas agregadas |
| Consumo | Power BI | Dashboards executivos a partir da Gold |

## Estrutura do repositório

```
scripts/
  job_02_bronze_para_silver.py   Script Glue (PySpark) — leitura, tratamento e escrita da Silver
  queries_athena_gold.sql        As 7 queries CTAS que geram a camada Gold
docs/
  mapeamento_completo_todas_colunas.csv   De-para das 421 colunas de negócio, entre os 3 anos
diagramas/
  arquitetura.png                Diagrama da arquitetura (feito no Draw.io)
```

## Destaques técnicos

- **Mapeamento semântico entre 3 fontes com schemas diferentes**: cada pergunta da pesquisa mudou de código/nome entre 2023, 2024 e 2025-2026 — o mapeamento foi construído e validado programaticamente contra os dados reais, não por inspeção manual.
- **Correção de um bug de cardinalidade no Glue Crawler**: o crawler não detectava corretamente o cabeçalho dos CSVs brutos, catalogando as colunas com nomes genéricos. A leitura foi ajustada para ocorrer diretamente do S3, contornando o problema.
- **Tratamento de respostas de múltipla escolha em análises agregadas**: campos onde uma célula podia conter múltiplas respostas (ex: `"AWS, Azure"`) são "explodidos" via `UNNEST` no Athena antes da contagem, evitando fragmentação artificial de categorias.

## Fonte dos dados

Os dados brutos usados neste projeto (pesquisa **State of Data Brasil**, por Data Hackers + Bain & Company) **não estão incluídos neste repositório** — são de uso público mas com termos próprios de licenciamento no Kaggle. Para reproduzir o pipeline, baixe os 3 datasets originais diretamente no Kaggle (busque por "State of Data Brazil" + o ano correspondente) e ajuste os caminhos de bucket S3 nos scripts.

## Ambiente

Este projeto foi desenvolvido e executado num ambiente **AWS Academy Learner Lab**. Os nomes de bucket nos scripts foram generalizados (`<seu-bucket-s3>`) para publicação — substitua pelo seu próprio bucket ao reproduzir.
