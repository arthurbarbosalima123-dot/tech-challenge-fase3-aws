-- =========================================================================
-- TECH CHALLENGE FASE 3 - QUERIES ATHENA (CAMADA GOLD)
-- Database: state_of_data_db
-- Fonte: 3 tabelas Silver (state_of_data_2023 / 2024 / 2025-2026), já
--        tratadas pelo job_02_bronze_para_silver.py (421 colunas, tipos
--        padronizados, duplicatas removidas)
-- Ordem de execução: rodar 1 por vez, sempre a query 1 primeiro (as
--        demais 5 dependem da tabela gold_perfil_mercado já existir)
-- =========================================================================


-- 1) TABELA BASE: uniao das 3 Silver, alimenta todas as demais tabelas Gold
CREATE TABLE gold_perfil_mercado
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/perfil-mercado/'
) AS
SELECT * FROM state_of_data_2023_a55fdebc115899c8fe9c18c50cbc2efe
UNION ALL
SELECT * FROM state_of_data_2024_d9037220c36716802aa8603f0e2c0751
UNION ALL
SELECT * FROM state_of_data_2025_2026_f09553f3570277390f11a9615b491b36;


-- 2) DIVERSIDADE E GENERO: perfil demografico por ano
CREATE TABLE gold_diversidade_genero
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/diversidade-genero-v2/'
) AS
SELECT ano_pesquisa, genero, cor_raca_etnia, pcd, senioridade, COUNT(*) as total_profissionais
FROM gold_perfil_mercado
GROUP BY ano_pesquisa, genero, cor_raca_etnia, pcd, senioridade
ORDER BY ano_pesquisa, total_profissionais DESC;


-- 3) TECNOLOGIAS: cloud e linguagem preferida, cada uma em tabela própria
-- (dividida em 2 porque cada campo, em ao menos um ano da pesquisa, permitia
-- resposta múltipla numa célula só, ex: "AWS, Azure" -- agrupar direto
-- fragmentava a contagem real por tecnologia. A solução usa UNNEST para
-- "explodir" cada resposta múltipla em uma linha por tecnologia mencionada,
-- e um CASE WHEN para normalizar grafia inconsistente entre anos
-- (ex: "SQL"/"sql"/"Sql", "PySpark"/"Pyspark", "Databricks"/"Datadricks").

CREATE TABLE gold_tecnologias_cloud
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/tecnologias-cloud/'
) AS
SELECT
    ano_pesquisa,
    senioridade,
    CASE
        WHEN lower(trim(tech)) = 'cloud própria' THEN 'Cloud Própria'
        WHEN lower(trim(tech)) = 'datadricks' THEN 'Databricks'
        WHEN lower(trim(tech)) = 'databriks' THEN 'Databricks'
        WHEN lower(trim(tech)) = 'digital ocean' THEN 'Digital Ocean'
        ELSE trim(tech)
    END AS cloud,
    COUNT(*) as total_profissionais
FROM gold_perfil_mercado
CROSS JOIN UNNEST(split(cloud_preferida, ',')) AS t(tech)
WHERE cloud_preferida IS NOT NULL
GROUP BY
    ano_pesquisa, senioridade,
    CASE
        WHEN lower(trim(tech)) = 'cloud própria' THEN 'Cloud Própria'
        WHEN lower(trim(tech)) = 'datadricks' THEN 'Databricks'
        WHEN lower(trim(tech)) = 'databriks' THEN 'Databricks'
        WHEN lower(trim(tech)) = 'digital ocean' THEN 'Digital Ocean'
        ELSE trim(tech)
    END
ORDER BY ano_pesquisa, total_profissionais DESC;


CREATE TABLE gold_tecnologias_linguagem
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/tecnologias-linguagem/'
) AS
SELECT
    ano_pesquisa,
    senioridade,
    CASE
        WHEN lower(trim(tech)) = 'sql' THEN 'SQL'
        WHEN lower(trim(tech)) = 'go' THEN 'Go'
        WHEN lower(trim(tech)) = 'sas' THEN 'SAS'
        WHEN lower(trim(tech)) = 'pyspark' THEN 'PySpark'
        WHEN lower(trim(tech)) = 'dax' THEN 'DAX'
        WHEN lower(trim(tech)) = 'spark' THEN 'Spark'
        WHEN lower(trim(tech)) = 'javascript' THEN 'JavaScript'
        ELSE trim(tech)
    END AS linguagem,
    COUNT(*) as total_profissionais
FROM gold_perfil_mercado
CROSS JOIN UNNEST(split(linguagem_preferida, ',')) AS t(tech)
WHERE linguagem_preferida IS NOT NULL
GROUP BY
    ano_pesquisa, senioridade,
    CASE
        WHEN lower(trim(tech)) = 'sql' THEN 'SQL'
        WHEN lower(trim(tech)) = 'go' THEN 'Go'
        WHEN lower(trim(tech)) = 'sas' THEN 'SAS'
        WHEN lower(trim(tech)) = 'pyspark' THEN 'PySpark'
        WHEN lower(trim(tech)) = 'dax' THEN 'DAX'
        WHEN lower(trim(tech)) = 'spark' THEN 'Spark'
        WHEN lower(trim(tech)) = 'javascript' THEN 'JavaScript'
        ELSE trim(tech)
    END
ORDER BY ano_pesquisa, total_profissionais DESC;


-- 4) MODELO DE TRABALHO: atual vs ideal, por senioridade
CREATE TABLE gold_modelo_trabalho
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/modelo-trabalho/'
) AS
SELECT ano_pesquisa, modelo_trabalho_atual, modelo_trabalho_ideal, senioridade, COUNT(*) as total_profissionais
FROM gold_perfil_mercado
WHERE modelo_trabalho_atual IS NOT NULL
GROUP BY ano_pesquisa, modelo_trabalho_atual, modelo_trabalho_ideal, senioridade
ORDER BY ano_pesquisa, total_profissionais DESC;


-- 5) REMUNERACAO: faixa salarial por UF, senioridade e cargo
CREATE TABLE gold_remuneracao
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/remuneracao/'
) AS
SELECT ano_pesquisa, uf_onde_mora, senioridade, cargo_atual, faixa_salarial, COUNT(*) as total_profissionais
FROM gold_perfil_mercado
WHERE faixa_salarial IS NOT NULL
GROUP BY ano_pesquisa, uf_onde_mora, senioridade, cargo_atual, faixa_salarial
ORDER BY ano_pesquisa, uf_onde_mora, senioridade;


-- 6) ADOCAO DE IA: uso de LLM/ChatGPT e prioridade estrategica da empresa
CREATE TABLE gold_adocao_ia
WITH (
    format = 'PARQUET',
    external_location = 's3://<seu-bucket-s3>/Gold/adocao-ia/'
) AS
SELECT ano_pesquisa, usa_chatgpt_llm, ia_generativa_prioridade_empresa, senioridade, cargo_atual, COUNT(*) as total_profissionais
FROM gold_perfil_mercado
WHERE usa_chatgpt_llm IS NOT NULL OR ia_generativa_prioridade_empresa IS NOT NULL
GROUP BY ano_pesquisa, usa_chatgpt_llm, ia_generativa_prioridade_empresa, senioridade, cargo_atual
ORDER BY ano_pesquisa, total_profissionais DESC;
