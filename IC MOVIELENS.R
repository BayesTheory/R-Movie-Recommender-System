# Carregar bibliotecas
#install.packages(c("ggplot2", "dplyr", "recommenderlab", "knitr"))
#install.packages(c("data.table","reshape2"))
#install.packages(c("scales","tidyverse"))
#https://www.kaggle.com/datasets/ayushimishra2809/movielens-dataset?select=ratings.csv

# Carregar bibliotecas
library(dplyr)  # Manipulação de dados
library(ggplot2)  # Visualização de dados
library(knitr)  # Renderização de tabelas
library(recommenderlab)  # Modelagem e recomendação
library(data.table)  # Manipulação de dados eficiente
library(reshape2)  # Manipulação de dados
library(scales)  # Formatação de eixos em gráficos
library(tidyverse)  # Manipulação e visualização de dados

################# INTRODUÇÃO #######################

#Ler os arquivos MOvieLens 10K Movie Dataset
#Avaliação: 4x105k
#Filmes: 3x10k

#MOVIELENS 
movies <- read.csv("movies.csv",  na="NA", header =TRUE) 
ratings <- read.csv("ratings.csv",  na="NA", header =TRUE) 

movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(movieId),
                                           title = as.character(title),
                                           genres = as.character(genres))

################# LIMPAR DATA #####################

colSums(is.na(movies))
movies<- na.omit(movies)
colSums(is.na(movies))

colSums(is.na(ratings))
ratings<- na.omit(ratings)
colSums(is.na(ratings))

ratings[!is.na(ratings)]
movies[!is.na(movies)]


################### ANALISE EXPLORATÓRIA ###################

#Sumário estatistico para dar uma visão geral 

glimpse(movies)
summary(movies)
head(movies)
str(movies)

glimpse(ratings)
summary(ratings)
head(ratings)
str(ratings)

# Quantidade de Filmes x Notas
summary(ratings$rating)
ggplot(aes(x=rating), data = ratings) + geom_histogram(binwidth = 0.1, aes(fill = ..count..)) +labs(x = "IMDB Score", y = "Count of Movies")
#Media 3.5


#fIlmes feitos em X Anos
# Converter timestamp em ano
ratings$year <- as.numeric(format(as.POSIXct(ratings$timestamp, origin = "1976-01-01", tz = "UTC"), format = "%Y"))
# Criar histograma dos anos
ggplot(data = ratings, aes(x = year)) +
  geom_histogram(fill = "red", binwidth = 0.1, stat = "count") +
  labs(x = "Year", y = "Count")


#DATA DOS FILMES X NOTAS
#JEITO 1 LENTO
ggplot(data = ratings) +
  geom_jitter(aes(x = rating, y = year), color = "blue") +
  labs(x = "Rating", y = "Year")
#JEITO 2 
ggplot(data = ratings) +
  geom_bin2d(aes(x = rating, y = year), bins = 20) +
  labs(x = "Rating", y = "Year")



#USER X VOTOS
ratings %>% group_by(userId) %>%
  summarise(n=n()) %>%
  arrange(n) %>%
  head()
ratings %>% group_by(userId) %>%
  summarise(n=n()) %>%
  ggplot(aes(n)) +
  geom_histogram(fill = "red") +
  scale_x_log10() + 
  ggtitle("Usuarios que Votaram") 



#Filmes x Generos

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
  coord_flip()




###################### MODELANDO DATA ############################# 


set.seed(999)

# Converter ratings para o formato de dados da biblioteca recommenderlab
ratings_recommenderlab <- as(ratings, "realRatingMatrix")


# Normalizar os dados
normalized_ratings <- normalize(ratings_recommenderlab)

# Remover classificações com valor 0
ratings <- ratings[ratings$rating != 0, ]

# Histograma das classificações
hist(ratings$rating, main = "Histogram of Ratings", xlab = "Rating Value")

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

# Normalizar os dados
normalized_ratings <- normalize(ratings)
normalized_ratings_vec <- as.vector(normalized_ratings@data)
normalized_ratings_vec <- normalized_ratings_vec[normalized_ratings_vec != 0]
hist(normalized_ratings_vec, main = "Notas normalizadas", xlab = "Notas")





# Dividir os dados em conjuntos de teste e treinamento
train <- 0.9
given <- 10
goodRating <- 0
k <- 5

eval_sets <- evaluationScheme(data = ratings, method = "split",
                              train = percent_train, given = given,
                              goodRating = goodRating, k = k)






# Similaridade usuário cosseno
similaridade_user <- similarity(ratings[1:4, ], method = "cosine", which = "users")
as.matrix(similaridade_user)

# Similaridade filmes cosseno
similaridade_filmes <- similarity(ratings[, 1:4], method = "cosine", which = "items")
as.matrix(similaridade_filmes)

similaridade_user2 <- similarity(ratings[1:4, ], method = "pearson", which = "users")
as.matrix(similaridade_user)

# Similaridade filmes cosseno
similaridade_filmes2 <- similarity(ratings[, 1:4], method = "pearson", which = "items")
as.matrix(similaridade_filmes)

image(as.matrix(similaridade_user), main = "Similaridade dos usuários cosseno")
image(as.matrix(similaridade_filmes), main = "Similaridade dos filmes cosseno")
image(as.matrix(similaridade_user2), main = "Similaridade dos usuários pearson")
image(as.matrix(similaridade_filmes2), main = "Similaridade dos filmes pearson")






##########################

# Construir modelo UBCF
eval_recommender_ubcf <- Recommender(data = getData(eval_sets, "train"),
                                     method = "UBCF", parameter = NULL)
items_to_recommend <- 10
eval_prediction_ubcf <- predict(object = eval_recommender_ubcf,
                                newdata = getData(eval_sets, "known"),
                                n = items_to_recommend,
                                type = "ratings")
eval_accuracy_ubcf <- calcPredictionAccuracy(x = eval_prediction_ubcf,
                                             data = getData(eval_sets, "unknown"),
                                             byUser = TRUE)
head(eval_accuracy_ubcf)



# Construir modelo IBCF
eval_recommender_ibcf <- Recommender(data = getData(eval_sets, "train"),
                                     method = "IBCF", parameter = NULL)
items_to_recommend <- 10
eval_prediction_ibcf <- predict(object = eval_recommender_ibcf,
                                newdata = getData(eval_sets, "known"),
                                n = items_to_recommend,
                                type = "ratings")
eval_accuracy_ibcf <- calcPredictionAccuracy(x = eval_prediction_ibcf,
                                             data = getData(eval_sets, "unknown"),
                                             byUser = TRUE)
head(eval_accuracy_ibcf)



# Construir modelo SVD
eval_recommender_svd <- Recommender(data = getData(eval_sets, "train"),
                                    method = "SVD", parameter = NULL)

items_to_recommend <- 10
eval_prediction_svd <- predict(object = eval_recommender_svd,
                               newdata = getData(eval_sets, "known"),
                               n = items_to_recommend,
                               type = "ratings")
eval_accuracy_svd <- calcPredictionAccuracy(x = eval_prediction_svd,
                                            data = getData(eval_sets, "unknown"),
                                            byUser = TRUE)
head(eval_accuracy_svd)



# Construir modelo LIBMF
eval_recommender_libmf <- Recommender(data = getData(eval_sets, "train"),
                                      method = "LIBMF", parameter = NULL)
items_to_recommend <- 10
eval_prediction_libmf <- predict(object = eval_recommender_libmf,
                                 newdata = getData(eval_sets, "known"),
                                 n = items_to_recommend,
                                 type = "ratings")
eval_accuracy_libmf <- calcPredictionAccuracy(x = eval_prediction_libmf,
                                              data = getData(eval_sets, "unknown"),
                                              byUser = TRUE)
head(eval_accuracy_libmf)





# Avaliar modelos usando diferentes parâmetros de similaridade

models_to_evaluate <- list(IBCF = list(name = "IBCF", param = list(k = 100)),
                           UBCF = list(name = "UBCF", param = list(k = 100)),
                           SVD = list(name = "SVD", param = list()),
                           LIBMF = list(name = "LIBMF", param = list()))

models_to_evaluate2 <- list(IBCF = list(name = "IBCF", param = list(k = 50)),
                            UBCF = list(name = "UBCF", param = list(k = 50)),
                            SVD = list(name = "SVD", param = list()),
                            LIBMF = list(name = "LIBMF", param = list()))




n_recommendations = c(1, 3, 5, 10, 15, 20, 25, 30)
results = evaluate(x = eval_sets, method = models_to_evaluate, n = n_recommendations)

n_recommendations2 = c(1, 3, 5, 10, 15, 20, 25, 30)
results2 = evaluate(x = eval_sets, method = models_to_evaluate2, n = n_recommendations)





plot(results, y = "ROC", annotate = 1, legend = "topleft")
title("ROC Curve")

plot(results, y = "prec/rec", annotate = 1, legend = "topleft")
title("prec/rec")


plot(results2, y = "ROC", annotate = 1, legend = "topleft")
title("ROC Curve")

plot(results2, y = "prec/rec", annotate = 1, legend = "topleft")
title("ROC Curve")









