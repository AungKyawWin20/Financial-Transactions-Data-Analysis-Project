# Financial Transactions Analysis & Credit Limit Prediction

Analyze, visualize, and predict financial behaviors using real-world transaction data. This R project uncovers insights into spending patterns, debt, credit utilization, and demographic trends, and predicts credit limits with machine learning.

## 🚀 Project Highlights

- **Comprehensive Data Analysis:** Explore user spending, debt, and credit utilization.
- **Feature Engineering:** Create meaningful features like income bins, credit score ranges, and debt-to-income ratios.
- **Interactive Visualizations:** Generate bar charts, scatter plots, time series, and interactive maps.
- **Machine Learning:** Predict credit limits using Random Forest regression.
- **Actionable Insights:** Correlate financial behaviors with demographics for deeper understanding.

## Project Overview

This R project analyzes financial transaction data to extract meaningful insights about spending patterns, debt, credit utilization, and demographic correlations. It also includes a predictive model to estimate credit limits using Random Forest regression.

## Data Sources
`transactions_data.csv` - Contains transaction details (amount, date, payment method, etc.).

`mcc_codes.json` - Contains merchant category codes and business types.

`users_data.csv` - Contains user demographics and financial data.

`cards_data.csv` - Contains credit card details such as credit limit and credit score.

## Project Steps

### 1. Data Preprocessing
- Load datasets using fread() and read.csv().

- Convert data types and handle missing values.

- Clean numeric columns by removing currency symbols ($, ,, -).

- Convert categorical data into factors.

### 2. Data Wrangling & Feature Engineering
- Merge datasets based on `client_id` and `mcc_code`.

- Create new features:

  - Income Bins (Low, Middle, Upper Middle, High).

  - Credit Score Ranges (Low, Medium, High).

  - Debt-to-Income Ratio.

  - Age Groups (Young Adult, Adult, Older People).

### 3. Exploratory Data Analysis (EDA)
- Identify top merchant cities by transaction count.

- Analyze average spending by income level and credit score.

- Assess correlation between financial variables (e.g., credit score vs. debt).

- Conduct linear regression analysis.

### 4. Data Visualization
- Bar Charts & Scatter Plots (using `ggplot2` and `ggthemes`).

- Time Series Analysis (transaction trends over time).

- Interactive Maps (using `leaflet` to visualize user locations and income levels).

### 5. Credit Limit Prediction

- Stratified sampling of user, transaction, and card data.

- Train a Random Forest Regression Model using:

  - Features: `yearly_income`, `credit_score`, `current_age`, `total_debt`, `avg_spending`

  - Target: `credit_limit`

  - Evaluate the model using RMSE and correlation analysis.

## Installation & Dependencies

```
install.packages(c("dplyr", "ggplot2", "rjson", "plotrix", "car", "data.table",
                   "ggthemes", "lubridate", "leaflet", "scales", "randomForest",
                   "caret", "Metrics"))
```
Load them in your R session:
```
library(dplyr)
library(ggplot2)
library(rjson)
library(plotrix)
library(car)
library(data.table)
library(ggthemes)
library(lubridate)
library(leaflet)
library(scales)
library(randomForest)
library(caret)
library(Metrics)
```
## How to Run the Project

1. **Clone or download** this repository.
2. Place all datasets (`transactions_data.csv`, `users_data.csv`, `cards_data.csv`, `mcc_codes.json`) in your working directory.
3. Run the main script:  
   `Final_Project_Financial_transaction.R`  
   *(or knit `FinalProject.Rmd` for a full report)*

## Results & Insights

- Discover top spending cities and user segments
- Visualize correlations between income, debt, and credit scores
- Predict credit limits with robust machine learning models

See the final report and presentation for detailed findings.


## Future Improvements
- Explore deep learning methods for credit limit prediction.

- Include additional demographic and behavioral data.

- Build an interactive dashboard for real-time financial insights.
