# Sistema de Recomendação de Filmes em R com recommenderlab

Este repositório contém scripts em R para construir, analisar e comparar diferentes algoritmos de sistemas de recomendação de filmes, utilizando principalmente a biblioteca `recommenderlab`. As análises são realizadas sobre dois datasets populares: MovieLens e um dataset derivado do TMDB.

## Objetivo

O objetivo principal é explorar e avaliar a performance de vários métodos de recomendação, incluindo:
*   **Filtragem Colaborativa Baseada no Usuário (UBCF):** Recomenda itens com base em usuários com gostos similares [6].
*   **Filtragem Colaborativa Baseada no Item (IBCF):** Recomenda itens similares àqueles que o usuário já gostou [6].
*   **Fatoração de Matrizes (SVD, LIBMF, ALS):** Métodos que decompõem a matriz usuário-item para encontrar fatores latentes e prever avaliações [4].

A comparação é feita utilizando métricas como Curvas ROC e Precisão/Recall.

## Datasets Utilizados

Este projeto utiliza dois conjuntos de dados (incluídos como arquivos `.csv` no repositório):

1.  **MovieLens:** Um dataset clássico para pesquisa em sistemas de recomendação (provavelmente uma versão como 100k ou similar) [4, 5, 8].
    *   `movies.csv`
    *   `ratings.csv`
2.  **TMDB (The Movie Database) - Derivado:** Um dataset maior com informações de filmes e avaliações.
    *   `movies2.csv`
    *   `ratings2.csv`

## Conteúdo do Repositório

*   **`IC MOVIELENS.R`**: Script R que realiza análise exploratória, pré-processamento, modelagem (UBCF, IBCF, SVD, LIBMF) e avaliação no dataset MovieLens.
*   **`IC TMDB.R`**: Script R com fluxo semelhante ao anterior, mas aplicado ao dataset derivado do TMDB.
*   **`movies.csv`, `ratings.csv`**: Arquivos de dados do MovieLens.
*   **`movies2.csv`, `ratings2.csv`**: Arquivos de dados derivados do TMDB.
*   **`README.md`**: Este arquivo.

## Metodologia

Ambos os scripts seguem passos similares:
1.  **Carregamento de Bibliotecas:** Importa as bibliotecas necessárias em R.
2.  **Carregamento e Limpeza dos Dados:** Lê os arquivos CSV, trata valores ausentes (NA).
3.  **Análise Exploratória de Dados (EDA):** Visualiza a distribuição das notas, contagem de votos, gêneros, datas de lançamento, etc., usando `ggplot2`.
4.  **Pré-processamento para `recommenderlab`:** Converte os dataframes de avaliações para o formato `realRatingMatrix`, normaliza as notas e filtra usuários/itens com poucas avaliações.
5.  **Cálculo de Similaridade:** Explora similaridade entre usuários e itens usando cosseno e Pearson.
6.  **Construção e Treinamento dos Modelos:** Define um esquema de avaliação (`evaluationScheme`) e treina múltiplos modelos (`Recommender`) como UBCF, IBCF, SVD, LIBMF, ALS [5].
7.  **Avaliação dos Modelos:** Utiliza a função `evaluate` para comparar os modelos com base em métricas como ROC e Precisão/Recall, gerando gráficos comparativos [8].

## Tecnologias Utilizadas

*   **Linguagem:** R
*   **Bibliotecas Principais:**
    *   `recommenderlab`: Para modelagem e avaliação de sistemas de recomendação [5].
    *   `dplyr`, `data.table`, `reshape2`, `tidyr`: Para manipulação de dados.
    *   `ggplot2`: Para visualização de dados.
    *   `knitr`: Para formatação de tabelas (usado nos scripts).
    *   `scales`: Para formatação de eixos em gráficos.

## Pré-requisitos

*   **R:** Instalado em sua máquina (versão 3.x ou 4.x).
*   **RStudio (Recomendado):** Um IDE popular para R que facilita a execução e visualização.

## Instalação das Dependências

Antes de executar os scripts, você precisa instalar as bibliotecas R necessárias. Abra o R ou RStudio e execute o seguinte comando no console:

