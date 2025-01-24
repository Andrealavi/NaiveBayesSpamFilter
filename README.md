# Adaptive Naive Bayes Spam Classifier

This project implements an adaptive Naive Bayes classifier for spam detection, demonstrating its flexibility in handling different types of messages (emails and SMS). The implementation showcases how the classifier can adapt its filtering capabilities when exposed to new types of data.

## Project Overview

The project focuses on the adaptability of Naive Bayes classifiers in the context of spam detection. It implements a classifier that:

1. Initially trains on email data
2. Tests performance on SMS spam detection
3. Adapts through additional training on SMS data
4. Demonstrates improved performance on SMS spam detection after adaptation

This approach highlights one of the key strengths of Naive Bayes classifiers: their ability to adapt and improve with exposure to new types of data while maintaining their fundamental probabilistic principles.

## Implementation Details

The classifier is implemented in R and includes several key components:

- Text preprocessing and tokenization
- Probability calculations with Laplace smoothing
- Adaptive training functionality
- Performance evaluation metrics

### Key Functions

- `tokenizer()`: Converts messages into word tokens, handling URLs and special characters
- `word_probabilities()`: Computes word probabilities with smoothing
- `classification()`: Performs message classification using Naive Bayes
- `training()`: Updates the classifier's vocabulary and probabilities with new data

## Datasets

The project uses two different datasets to demonstrate the classifier's adaptability:

1. Email Dataset (`emails.csv`):
   - Source: [Email Spam Classification Dataset](https://www.kaggle.com/datasets/balaka18/email-spam-classification-dataset-csv)
   - Direct link: `https://www.kaggle.com/datasets/balaka18/email-spam-classification-dataset-csv`
   - Used for initial training
   - Binary classification (spam/ham)

2. SMS Dataset (`spam.csv`):
   - Source: [SMS Spam Collection Dataset](https://www.kaggle.com/datasets/uciml/sms-spam-collection-dataset?rvi=1)
   - Direct link: `https://www.kaggle.com/datasets/uciml/sms-spam-collection-dataset?rvi=1`
   - Used for adaptation testing and secondary training
   - Binary classification (spam/ham)

Note: You'll need to create a Kaggle account and accept the dataset terms to download these files.

## Theoretical Background

The implementation is based on the Naive Bayes algorithm, which uses Bayes' theorem with the "naive" assumption of conditional independence between features. For a detailed explanation of the theoretical foundations, including formulas and concepts, please refer to the `Naive_Bayes_Classifiers.pdf` presentation included in this repository.

## Requirements

- R programming environment
- Required R packages:
  - dplyr
  - stringr
  - tidyr
  - rsample
  - yardstick

## Usage

1. Clone the repository
2. Download the datasets from the provided Kaggle links
3. Update the file paths in the script to point to your downloaded datasets
4. Run the script to see the classifier's performance before and after adaptation

## Results

The script outputs performance metrics at two stages:
1. After initial training (pre-adaptation)
2. After SMS training (post-adaptation)

Performance metrics include:
- Accuracy
- Precision
- Recall
- F1 Score
- Confusion Matrix
