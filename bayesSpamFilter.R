library(dplyr)
library(stringr)
library(tidyr)
library(rsample)
library(yardstick)

# Functions
# Converts a string into a list of words
tokenizer <- function(msg) {
  token_vector <- msg %>% str_replace_all("(https|http|www)+\\p{P}+(\\w)+\\p{P}+\\w+", "_url_") %>%
    str_replace_all("\\b(\\d{7,})\\b", "_longnum_") %>%
    str_replace_all("[\\p{P}]?[^_a-zA-Z\\s]", "") %>% str_to_lower() %>% str_split(" ")
  
  token_vector
}

# Computes the proportion of a word in the given category.
word_probabilities <- function(word_n, category_n, smooth = 1) {
  prob <- (word_n + smooth) / (category_n + smooth)
  prob
}

# Takes a message and returns the prediction
classification <- function(msg, vocab, ham_p = 0.5, spam_p = 0.5) {
  msg_vector <- tokenizer(msg) %>% unlist()
  
  # Gets the list containing ham_prop and spam_prop for each word in the message
  props <- sapply(msg_vector, function(x) {
    vocab %>% filter(word == x) %>% select(ham_prop, spam_prop)
  })
  
  if (!is.null(dim(props))) {
    # Computes P(W|H)P(H)
    ham_prob <- prod(unlist(as.numeric(props[1, ])), na.rm = TRUE)
    ham_prob <- ham_p * ham_prob
    
    # Computes P(W|S)P(S)
    spam_prob <- prod(unlist(as.numeric(props[2, ])), na.rm = TRUE)
    spam_prob <- spam_p * spam_prob
    
    # Makes the prediction
    if (ham_prob > spam_prob) {
      prediction <- "ham"
    } else {
      prediction <- "spam"
    }
  } else {
    prediction <- "unknown"
  }
  
  prediction
}

# Use new data to update vocab probabilities
training <- function(messages, results, vocab) {
  for (i in 1:length(messages)) {
    msg_vector <- tokenizer(messages[i]) %>% unlist()
    msg_vector[nchar(msg_vector) > 1 & msg_vector %in% c("the", "an", "to", "etc", "and", "for", "of")]
    
    # Creates vectors with new and old words in the message
    is_known <- msg_vector %in% vocab$word
    new_words <- msg_vector[!is_known]
    old_words <- msg_vector[is_known]
    
    label <- ifelse(results[i] == "spam", "spam", "ham")
    
    word_n[label] <- word_n[label] + length(msg_vector)
    
    label_c <- paste0(label, "_c")
    
    # Increments the ham or spam counter of the words already present in the vocabulary
    for (word in old_words) {
      vocab[vocab$word == word, label_c] <- vocab[vocab$word == word, label_c] + 1
    }
    
    # Creates new rows in the vocabulary for each of the new words
    for (word in unique(new_words)) {
      ifelse(results[i] == "spam", word_n["spam"] <- word_n["spam"] + sum(new_words == word), word_n["ham"] <- word_n["ham"] + sum(new_words == word))
      
      new_row <- list(word = word, ham_c = 0, spam_c = 0)
      new_row[[label_c]] <- sum(new_words == word)
      
      ham_prop <- word_probabilities(new_row$ham_c, word_n["ham"])
      spam_prop <- word_probabilities(new_row$spam_c, word_n["spam"])
      
      new_row <- append(new_row, c(ham_prop,  spam_prop))
      
      names(new_row) <- c("word", "ham_c", "spam_c", "ham_prop", "spam_prop")
      
      vocab <- rbind(vocab, new_row)
    }
    
    # Recomputes the probabilities for each word
    vocab <- vocab %>% mutate(ham_prop = word_probabilities(ham_c, word_n["ham"])) %>%
      mutate(spam_prop = word_probabilities(spam_c, word_n["spam"]))
  }
  
  vocab
}

# Retrieve data from csv files and create data frames

# Datasets links:
# emails.csv: https://www.kaggle.com/datasets/balaka18/email-spam-classification-dataset-csv
# spam.csv: https://www.kaggle.com/datasets/uciml/sms-spam-collection-dataset?rvi=1

vocab_data <- as_tibble(read.csv("C:/Users/andre/Desktop/Informatica/R/emails.csv"))

sms_data <- as_tibble(read.csv("C:/Users/andre/Desktop/Informatica/R/spam.csv"))
sms_data <- sms_data %>% unite(col = "msg", 2:5, na.rm = TRUE) %>% rename("label" = v1)

split <- initial_split(sms_data, strata = label)
training_data <- rsample::training(split)
testing_data <- rsample::testing(split)

rm(split)

vocab_data <- vocab_data[, 2:ncol(vocab_data)]

vocab_data$Prediction[vocab_data$Prediction == 0] <- "ham"
vocab_data$Prediction[vocab_data$Prediction == 1] <- "spam"

# Create vocabulary
word <- c()
ham_prop <- c()
ham_c <- c()
spam_prop <- c()
spam_c <- c()

for (i in 1:(ncol(vocab_data) - 1)) {
  word <- append(word, colnames(vocab_data[i]))
  
  ham_c <- append(ham_c, sum(vocab_data[vocab_data$Prediction == "ham", i]))
  
  spam_c <- append(spam_c, sum(vocab_data[vocab_data$Prediction == "spam", i]))
}

word_n <- c("ham" = sum(ham_c), "spam" = sum(spam_c))

ham_prop <- sapply(ham_c, function(x) word_probabilities(x, word_n["ham"]))
spam_prop <- sapply(spam_c, function(x) word_probabilities(x, word_n["spam"]))

vocab <- as_tibble(data.frame(word, ham_c, spam_c, ham_prop, spam_prop))

rm(i, word, ham_c, spam_c, ham_prop, spam_prop)

levels <- c("ham", "spam")

# Test on training_data
spam_TrainingClassification <- sapply(training_data$msg, function(x) {
  classification(x, vocab, ham_p = 0.87, spam_p = 0.13)
}, USE.NAMES = FALSE)

mean(spam_TrainingClassification == training_data$label)

# Creates a new dataframe in order to apply metrics function
pretraining_performance <- training_data %>% mutate(label = factor(label, labels = levels), pred = factor(spam_TrainingClassification, levels = levels))

# Print filter performance before training
cat("---- Pre training performance ----\n")
print(yardstick::metrics(pretraining_performance, label, pred))

cat("---- Confusion matrix ----\n")
table(paste("actual", pretraining_performance$label), paste("pred", pretraining_performance$pred))


# Training
trained_vocab <- training(training_data$msg, training_data$label, vocab, ham_p = 0.87, spam_p = 0.13)

# Test on testing_data
spam_TestingClassification <- sapply(testing_data$msg, function(x) {
  classification(x, trained_vocab)
}, USE.NAMES = FALSE)

mean(spam_TestingClassification == testing_data$label)

# Creates a new dataframe in order to apply metrics function
testing_performance <- testing_data %>% mutate(label = factor(label, labels = levels), pred = factor(spam_TestingClassification, levels = levels))

# Print filter performance after training
cat("---- Post training performance ----\n")
print(yardstick::metrics(testing_performance, label, pred))

cat("---- Confusion matrix ----\n")
table(paste("actual", testing_performance$label), paste("pred", testing_performance$pred))
