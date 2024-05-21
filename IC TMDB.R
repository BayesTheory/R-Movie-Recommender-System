# Carregar bibliotecas
#install.packages(c("ggplot2", "dplyr", "recommenderlab", "knitr"))
#install.packages(c("data.table","reshape2"))
#install.packages(c("scales","tidyverse"))
#https://www.kaggle.com/datasets/rounakbanik/the-movies-dataset

# Carregar bibliotecas
library(dplyr)  # Manipulação de dados
library(ggplot2)  # Visualização de dados
library(knitr)  # Renderização de tabelas
library(recommenderlab)  # Modelagem e recomendação
library(data.table)  # Manipulação de dados eficiente
library(reshape2)  # Manipulação de dados
library(scales)  # Formatação de eixos em gráficos
library(tidyverse)  # Manipulação e visualização de dados


                          ################################ INTRODUÇÃO ################################

# Ler os arquivos TMDB 10K Movie Dataset
movies <- read.csv("movies2.csv",  na="NA", header =TRUE)  # Carregar arquivo de filmes10K LINHAS X 21 COLUNAS
ratings <- read.csv("ratings2.csv",  na="NA", header =TRUE)  # Carregar arquivo de avaliações 100K LINHAS X4 COLUNMS


                          ################################ LIMPAR DADOS ################################

# Verificar dados ausentes
colSums(is.na(movies))

# Remover linhas com dados ausentes
movies <- na.omit(movies)

# Verificar dados ausentes 
colSums(is.na(movies))

# Verificar dados ausentes 
colSums(is.na(ratings))

# Remover linhas com dados ausentes
ratings <- na.omit(ratings)

# Verifica dados ausentes
colSums(is.na(ratings))

# Verificar dados 
ratings[!is.na(ratings)]
movies[!is.na(movies)]

                              ################### ANALISE EXPLORATÓRIA ###################



# Sumário estatístico para dar uma visão geral
glimpse(movies)
summary(movies)
head(movies)
str(movies)

glimpse(ratings)
summary(ratings)
head(ratings)
str(ratings)

# Filmes x Notas
summary(movies$vote_average)
ggplot(aes(x = vote_average), data = movies) +
  geom_histogram(binwidth = 0.1, aes(fill = ..count..)) +
  labs(x = "IMDB Nota", y = "Filmes")

# Filmes x Votos
summary(movies$vote_count)

# Contagem de Votos para Top N filmes
movies %>%
  top_n(20, vote_count) %>%
  ggplot(aes(x = reorder(as.character(original_title), vote_count), y = vote_count)) +
  geom_bar(stat = 'identity', fill = "red") +
  coord_flip(y = c(0, 10000))+labs(x = "Votos", y = "Filmes mais votados")

# Contagem de Votos para filmes
movies %>%
  ggplot(aes(x = vote_count)) +
  geom_histogram(fill = "red", binwidth = 100) +
  scale_x_continuous(breaks = seq(0, 50000, by = 1000), label = comma) +
  coord_cartesian(x = c(0, 4000))+labs(x = "Distribuição de Votos por filmes", y = "Contagem")

# Filmes x ID
generos <- movies %>%
  top_n(100, genres) %>%
  filter(nchar(genres) > 2) %>%
  mutate(genres = gsub("\\[|\\]", "", genres)) %>%
  separate_rows(genres, sep = ",\\s*") %>%
  select(genres) %>%
  mutate_if(is.character, factor)
generos %>%
  group_by(genres) %>%
  count() %>%
  ggplot(aes(x = reorder(genres, n), y = n)) +
  geom_col(fill = "red") +
  coord_flip()+labs(x = "Generos dos Filmes", y = "Filme")



# Filmes x Data Lançamento
movies$release_date <- as.Date(movies$release_date)
movies$Year <- as.factor(format(movies$release_date, "%Y"))
movies$Date <- as.factor(format(movies$release_date, "%d"))
movies$month <- month.abb[(as.factor(format(movies$release_date, "%m")))]
movies %>%
  group_by(month) %>%
  drop_na(month) %>%
  summarise(count = n()) %>%
  arrange(desc(month)) %>%
  ggplot(aes(reorder(month, count), count)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  geom_label(aes(label = count))+labs(y = "Filmes lançados em N Mês", x = "Meses")


########"Filmes mais Caros", x = "Preço"
top_movies <- movies %>%
  mutate(budget = as.numeric(budget)) %>%
  top_n(20, budget) %>%
  arrange(desc(budget))
#####
ggplot(top_movies, aes(x = original_title, y = budget)) +
  geom_bar(stat = "identity", fill = "red", width = 0.5) +
  coord_flip() +
  ylim(0, max(top_movies$budget))+labs(y = "Filmes mais Caros", x = "Preço")
######


# Filmes x Tempo
ggplot(movies, aes(x = runtime)) +labs(y = "Filmes", x = "Tempo de Filme")+
  geom_histogram(binwidth = 5, aes(y = ..density..), fill = "red") + coord_cartesian(x = c(0, 400))




                            ###################### MODELANDO DATA ############################# 


set.seed(999)

# Converter ratings para o formato de dados da biblioteca recommenderlab
ratings_recommenderlab <- as(ratings, "realRatingMatrix")

# Normalizar os dados
normalized_ratings <- normalize(ratings_recommenderlab)

# Exibir número de classificações correspondentes a cada valor de classificação
kable(table(ratings$rating), caption = "Rating frequency")

# Remover classificações com valor 0
ratings <- ratings[ratings$rating != 0, ]

# Histograma das classificações
hist(ratings$rating, main = "Histograma das Notas", xlab = "Notas Valor")

# Limitar os dados com base em limites mínimos
ratings_counts <- table(ratings$userId)
ratings <- ratings[ratings$userId %in% names(ratings_counts[ratings_counts > 10]), ]
movies_counts <- table(ratings$movieId)
ratings <- ratings[ratings$movieId %in% names(movies_counts[movies_counts > 20]), ]
dim(ratings)


# Verificar se o objeto ratings é um realRatingMatrix válido
if (!is(ratings, "realRatingMatrix")) {
  # Converter ratings para o formato de dados da biblioteca recommenderlab
  ratings <- as(ratings, "realRatingMatrix")
}

# Normalizar 
normalized_ratings <- normalize(ratings)
normalized_ratings_vec <- as.vector(normalized_ratings@data)
normalized_ratings_vec <- normalized_ratings_vec[normalized_ratings_vec != 0]
hist(normalized_ratings_vec, main = "Histograma das Normalizada Notas", xlab = "Notas")

recommendation_model = recommenderRegistry$get_entries(dataType = "realRatingMatrix")
names(recommendation_model)

# Dividir os dados em conjuntos de teste e treinamento
train <- 0.9
given <- 10
goodRating <- 0
K <- 20
set.seed(999)

eval_sets <- evaluationScheme(data = ratings, method = "split",
                              train = train, given = given,
                              goodRating = goodRating, k = K)


#  usuário cosseno
similaridade_user <- similarity(ratings[1:4, ], method = "cosine", which = "users")
as.matrix(similaridade_user)

#  filmes cosseno
similaridade_filmes <- similarity(ratings[, 1:4], method = "cosine", which = "items")
as.matrix(similaridade_filmes)


#  usuário pearson
similaridade_user2 <- similarity(ratings[1:4, ], method = "pearson", which = "users")
as.matrix(similaridade_user)

#  filmes pearson
similaridade_filmes2 <- similarity(ratings[, 1:4], method = "pearson", which = "items")
as.matrix(similaridade_filmes)




image(as.matrix(similaridade_user), main = "Similaridade dos usuários cosseno",xlab = "usuários", ylab = "usuários",theme(plot.title = element_text(hjust = 0.5)))
                  
image(as.matrix(similaridade_filmes), main = "Similaridade dos filmes cosseno",xlab = "Filmes", ylab = "Filmes")

image(as.matrix(similaridade_user2), main = "Similaridade dos usuários pearson",xlab = "usuários", ylab = "usuários")

image(as.matrix(similaridade_filmes2), main = "Similaridade dos filmes pearson",xlab = "Filmes", ylab = "Filmes")


#########


set.seed(999)
#  modelo UBCF

eval_recommender_ubcf <- Recommender(data = getData(eval_sets, "train"),
                                     method = "ALS", parameter = NULL)
items_to_recommend <- 50
eval_prediction_ubcf <- predict(object = eval_recommender_ubcf,
                                newdata = getData(eval_sets, "known"),
                                n = items_to_recommend,
                                type = "ratings")
eval_accuracy_ubcf <- calcPredictionAccuracy(x = eval_prediction_ubcf,
                                             data = getData(eval_sets, "unknown"),
                                             byUser = TRUE)
head(eval_accuracy_ubcf)

#  modelo IBCF

eval_recommender_ibcf <- Recommender(data = getData(eval_sets, "train"),
                                     method = "IBCF", parameter = NULL)
items_to_recommend <- 50
eval_prediction_ibcf <- predict(object = eval_recommender_ibcf,
                                newdata = getData(eval_sets, "known"),
                                n = items_to_recommend,
                                type = "ratings")
eval_accuracy_ibcf <- calcPredictionAccuracy(x = eval_prediction_ibcf,
                                             data = getData(eval_sets, "unknown"),
                                             byUser = TRUE)
head(eval_accuracy_ibcf)

#  modelo SVD

eval_recommender_svd <- Recommender(data = getData(eval_sets, "train"),
                                    method = "SVD", parameter = NULL)

items_to_recommend <- 50
eval_prediction_svd <- predict(object = eval_recommender_svd,
                               newdata = getData(eval_sets, "known"),
                               n = items_to_recommend,
                               type = "ratings")
eval_accuracy_svd <- calcPredictionAccuracy(x = eval_prediction_svd,
                                            data = getData(eval_sets, "unknown"),
                                            byUser = TRUE)
head(eval_accuracy_svd)

#  modelo LIBMF
eval_recommender_libmf <- Recommender(data = getData(eval_sets, "train"),
                                      method = "LIBMF", parameter = NULL)
items_to_recommend <- 50
eval_prediction_libmf <- predict(object = eval_recommender_libmf,
                                 newdata = getData(eval_sets, "known"),
                                 n = items_to_recommend,
                                 type = "ratings")
eval_accuracy_libmf <- calcPredictionAccuracy(x = eval_prediction_libmf,
                                              data = getData(eval_sets, "unknown"),
                                              byUser = TRUE)
head(eval_accuracy_libmf)



# modelo ALS
eval_recommender_als <- Recommender(data = getData(eval_sets, "train"),
                                      method = "LIBMF", parameter = NULL)
items_to_recommend <- 50
eval_prediction_als <- predict(object = eval_recommender_als,
                                 newdata = getData(eval_sets, "known"),
                                 n = items_to_recommend,
                                 type = "ratings")
eval_accuracy_als <- calcPredictionAccuracy(x = eval_prediction_als,
                                              data = getData(eval_sets, "unknown"),
                                              byUser = TRUE)
head(eval_accuracy_als)



# Avaliar modelos parâmetros de similaridade

models_to_evaluate <- list(IBCF = list(name = "IBCF", param = list(k = 100,method = "cosine")),
                           UBCF = list(name = "UBCF", param = list(k = 100,method = "cosine")),
                           SVD = list(name = "SVD", param = list()),
                           ALS = list(name = "LIBMF", param = list()))

models_to_evaluate2 <- list(IBCF = list(name = "IBCF", param = list(k = 100,method = "pearson")),
                            UBCF = list(name = "UBCF", param = list(k = 100,method = "pearson")),
                            SVD = list(name = "SVD", param = list()),
                            ALS = list(name = "LIBMF", param = list()))



models_to_evaluate3 <- list(ALS = list(name = "ALS", param = list()))




n_recommendations = c(1, 3, 5, 10, 15, 20, 25)
results = evaluate(x = eval_sets, method = models_to_evaluate, n = n_recommendations)
results2 = evaluate(x = eval_sets, method = models_to_evaluate2, n = n_recommendations)
results3 = evaluate(x = eval_sets, method = models_to_evaluate3, n = n_recommendations)





plot(results, y = "ROC", annotate = 1, legend = "topleft")
title("ROC Curve cosseno")

plot(results, y = "prec/rec", annotate = 1, legend = "topleft")
title("prec/rec cosseno")



plot(results2, y = "ROC", annotate = 1, legend = "topleft")
title("ROC Curve Pearson")

plot(results2, y = "prec/rec", annotate = 1, legend = "topleft")
title("prec/rec Pearson")


 
plot(results3, y = "ROC", annotate = 1, legend = "topleft")
title("ROC Curve Pearson")

plot(results3, y = "prec/rec", annotate = 1, legend = "topleft")
title("prec/rec Pearson")


