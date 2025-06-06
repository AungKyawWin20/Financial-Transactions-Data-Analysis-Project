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

#Transactions CSV File
transactions =fread("transactions_data.csv")
#Merchant Categories JSON File
merchant_categories = fromJSON(file = "mcc_codes.json")
mcc_df <- data.frame(mcc_code = names(merchant_categories), business_type = unlist(merchant_categories), stringsAsFactors = FALSE)

#users Data CSV File
user_data = read.csv("users_data.csv")

#Card Data CSV File
card_data = read.csv("cards_data.csv")

#Exploring Datasets
summary(transactions)
head(transactions)

summary(user_data)
head(user_data)

summary(card_data)
head(card_data)

#Checking for missing values
colSums(is.na(transactions)) #For Transactions File

colSums(is.na(user_data)) #For User Data File

colSums(is.na(card_data)) #For  Card Data File

#Data Wrangling Process
#Clean Up Process For Transactions CSV File
transactions$amount = gsub("[$,-]", "", transactions$amount) #Removing the $ sign and minus sign from the "amount" column
transactions$amount = as.numeric(transactions$amount) #Converting the column into numerics
transactions$use_chip = as.factor(transactions$use_chip) #Converting the transaction type into factors

#Clean Up Process For User Data CSV File
user_data$yearly_income = gsub("[$,]", "", user_data$yearly_income) #Removing the $ sign
user_data$yearly_income = as.numeric(user_data$yearly_income) #Converting into a numeric

user_data$total_debt = gsub("[$,]", "", user_data$total_debt) #Removing the $ sign
user_data$total_debt = as.numeric(user_data$total_debt) #Converting into a numeric

head(user_data)


#Clean Up Process For Merchant Categories JSON File
mcc_df$mcc_code = as.integer(mcc_df$mcc_code) #Converting the mcc code into integers

str(mcc_df) #Rechecking to see changes were made correctly

#Clean Up Process For Card Data CSV File
card_data$credit_limit = gsub("[$,]", "", card_data$credit_limit) #Removing the $sign
card_data$credit_limit = as.numeric(card_data$credit_limit)

#Verifying changes
head(transactions$amount)
head(user_data)
head(card_data)
head(mcc_df)

#Merging all the datasets by common keys
data1 = transactions %>%
  inner_join(user_data, by = c("client_id" = "id")) #Joining User Data into Transaction Data

data2 = transactions %>%
  inner_join(card_data, by = "client_id") #Joining Card Data into Transaction Data

data3 = data1 %>%
  inner_join(mcc_df, by = c("mcc" = "mcc_code")) #Joining Merchant Category Into Transaction Data and User Data

data4 = user_data %>%
  inner_join(card_data, by = c("id" = "client_id")) # Joining User Data and Card Data CSV Files

data4 = data4 %>%
  mutate(credit_utilization = (total_debt / credit_limit) * 100)

data3 = na.omit(data3) #Omitting null values
head(data3) #Checking if changes were made

data3 <- data3 %>%
  mutate(
    # Creating income bins based on yearly_income
    income_bin = cut(yearly_income,
                     breaks = c(0, 30000, 70000, 150000, Inf),
                     labels = c("Low", "Middle", "Upper Middle", "High"), 
                     right = FALSE), # Ensures bins are inclusive of the left side
    
    # Creating credit score categories based on credit_score
    credit_score_range = case_when(
      credit_score < 600 ~ "Low",
      credit_score >= 600 & credit_score < 700 ~ "Medium",
      credit_score >= 700 ~ "High",
      TRUE ~ NA_character_ # Ensures NA values are handled if any
    ),
    
    # Creating Debt To Income Ratio column
    debt_to_income = total_debt / yearly_income,
    
    # Categorizing users into age groups
    age_group = case_when(
      current_age <= 25 ~ "Young Adult",
      current_age > 25 & current_age <= 45 ~ "Adult",
      current_age > 45 ~ "Older People"
    )
  )

#Converting date to a propoer format and grouping by month
transactions1 <- transactions %>%
  mutate(transaction_month = floor_date(as.Date(date, format = "%Y-%m-%d"), "month")) %>%
  group_by(transaction_month) %>%
  summarize(total_amount = sum(amount, na.rm = TRUE))

#Stratified Random Sampling Dataset
set.seed(123) #To reproduce the same results

sampled_data = data3 %>%
  group_by(income_bin) %>%
  sample_frac(1300000 / nrow(data3)) %>% #Using 10% of the dataset
  ungroup()

summary(sampled_data)

#Findings
#Summarizing the transactions count by merchant city and selecting the top 10 cities
top_cities = transactions %>%
  filter(merchant_city != "ONLINE") %>% # Exclude transactions with "online" as the merchant city
  group_by(merchant_city) %>%
  summarize(transaction_count = n()) %>%
  arrange(desc(transaction_count)) %>%
  slice_head(n = 10)

#Creating a Bar plot to visualize
ggplot(top_cities, aes(x = reorder(merchant_city, transaction_count), y = transaction_count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Top 10 Merchant Cities by Transaction Count", x = "Merchant City", y = "Transaction Count") +
  theme_economist()

#Average Spending By Income Bracket
avg_spending = data3 %>%
  group_by(income_bin) %>%
  summarize(average_spending = mean(amount, na.rm = TRUE))

ggplot(avg_spending, aes(x = income_bin, y = average_spending, fill = income_bin)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  labs(
    title = "Average Spending by Income Bracket",
    x = "Income Bracket",
    y = "Average Spending"
  ) +
  theme_economist() +
  scale_fill_brewer(palette = "Set3")

#Average Spending by Credit Score Range
avg_spending_by_CreditScore = data3 %>%
  group_by(credit_score_range) %>%
  summarize(average_spending = mean(amount, na.rm = TRUE))

ggplot(avg_spending_by_CreditScore, aes(x = credit_score_range, y = average_spending, fill = credit_score_range)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  labs(
    title = "Average Spending by Credit Score Range",
    x = "Credit Score Range",
    y = "Average Spending"
  ) +
  theme_economist() +
  scale_fill_brewer(palette = "Set2")

#Linear regression to assess the relationship between credit score and spending amount
lm_credit_score = lm(amount~credit_score, data = sampled_data)
summary(lm_credit_score)


# Plotting the linear regression between Credit Score and transaction amount
ggplot(sampled_data, aes(x = credit_score, y = amount)) +
  geom_point(alpha = 0.4) +  # Scatter plot of the data points
  geom_smooth(method = "lm", color = "blue", se = FALSE) +  # Adding the regression line
  labs(
    title = "Relationship between Credit Score and Spending",
    x = "Credit Score",
    y = "Transaction Amount"
  ) +
  theme_economist()

#Relationship Between Age and Average Debt
avg_debt_by_age = data3 %>%
  group_by(current_age) %>%
  summarize(average_debt = mean(total_debt, na.rm = TRUE))

ggplot(avg_debt_by_age, aes(x = current_age, y = average_debt)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", color = "blue") +
  labs(
    title = "Relationship between Age and Average Debt",
    x = "Average Age",
    y = "Average Debt"
  ) +
  theme_economist()

#Average Debt by Age Group
avg_debt_and_age = data3 %>%
  mutate(age_bin = cut(current_age, breaks = seq(20,100,15))) %>%
  group_by(age_bin) %>%
  summarize(avg_debt = mean(total_debt, na.rm = TRUE))

ggplot(avg_debt_and_age, aes(x = age_bin, y = avg_debt)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Average Debt By Age Group", x = "Age Group", y = "Average Debt") +
  theme_economist()


#Correlation coefficient between credit limit and credit score
correlation <- cor(data4$credit_score, data4$credit_limit, use = "complete.obs")

# Print the correlation result
print(paste("Correlation between Credit Score and Credit Limit: ", round(correlation, 2)))

ggplot(data4, aes(x = credit_limit, y = credit_score)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Relationship between Credit Limit and Credit Score",
    subtitle = paste("Correlation: ", round(correlation, 2)),
    x = "Credit Limit",
    y = "Credit Score"
  ) +
  theme_economist()

#Correlation Between Income and Credit Limit
# Step 1: Calculate the correlation between yearly income and credit limit
correlation_income_limit <- cor(data4$yearly_income, data4$credit_limit, use = "complete.obs")

#Building a simple linear regression
lm_income_creditlimit = lm(credit_limit ~ yearly_income, data = data4)
summary(lm_income_creditlimit)

#Evaluating the regression
par(mar = c(5, 4, 4, 2) + 0.1)
plot(lm_income_creditlimit)

# Step 2: Create a scatter plot
ggplot(data4, aes(x = yearly_income, y = credit_limit)) +
  geom_point(alpha = 0.3, color = "black") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Relationship between Yearly Income and Credit Limit",
    subtitle = paste("Correlation: ", round(correlation_income_limit, 2)),
    x = "Yearly Income",
    y = "Credit Limit"
  ) +
  theme_economist()

#Relationship between Number of Cards and Total Debt
debt_by_cards <- sampled_data %>%
  group_by(num_credit_cards) %>%
  summarize(
    avg_total_debt = mean(total_debt, na.rm = TRUE)
  )

lm_debt_cards = lm(avg_total_debt ~  num_credit_cards, data = debt_by_cards)
summary(lm_debt_cards)

plot(lm_debt_cards)

ggplot(debt_by_cards, aes(x = num_credit_cards, y = avg_total_debt)) +
  geom_point(color = "darkblue", size = 3, alpha = 0.6) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Relationship between Number of Cards and Total Debt",
    x = "Number of Credit Cards",
    y = "Average Total Debt"
  ) +
  theme_economist()

# Create interactive map
leaflet(users_data) %>%
  addTiles() %>%
  addCircleMarkers(
    ~longitude, ~latitude,
    color = ~colorQuantile("YlOrRd", yearly_income)(yearly_income),
    popup = ~paste(
      "Income:", scales::dollar(yearly_income),
      "<br>Credit Score:", credit_score
    )
  )

top_5_users <- user_data %>%
  arrange(desc(yearly_income)) %>%
  head(5)

# Create interactive map for top 5 users
leaflet(top_5_users) %>%
  addTiles() %>%
  addCircleMarkers(
    ~longitude, ~latitude,
    color = ~colorQuantile("YlOrRd", yearly_income)(yearly_income),
    popup = ~paste(
      "Income:", dollar(yearly_income),
      "<br>Credit Score:", credit_score
    )
  )

# Fit the linear regression model for credit score and yearly income
model <- lm(credit_score ~ yearly_income, data = user_data)

# View the summary of the model
summary(model)
correlation <- cor(user_data$credit_score, user_data$yearly_income)
correlation

ggplot(user_data, aes(x = yearly_income, y = credit_score)) +
  geom_point(alpha = 0.5) +  # Scatter plot of the data
  geom_smooth(method = "lm", color = "blue") +  # Add regression line
  labs(title = "Linear Regression: Credit Score vs. Yearly Income",
       x = "Yearly Income",
       y = "Credit Score") +
  theme_economist()

#The number of transactions for each type and payment method
top_transactions <- data3 %>%
  group_by(use_chip, business_type) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  group_by(use_chip) %>%
  slice_head(n = 5)

ggplot(top_transactions, aes(x = reorder(business_type, -count), y = count, fill = use_chip)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Top 5 Transaction Types by Payment Method", x = "Transaction Type", y = "Count", color = "Payment Method") +
  theme_economist() +
  theme(axis.text.x = element_text(angle = 70, hjust=1, vjust=1))

#TimeSeriesAnalysis of Payment Methods
data3$date <- as.Date(data3$date)
time_series_data <- data3 %>%
  group_by(date, use_chip) %>%
  summarise(total_amount = sum(amount), .groups = 'drop')

ggplot(time_series_data, aes(x = date, y = total_amount, color = use_chip, group = use_chip)) +
  geom_line(size = 0.2) +
  labs(title = "Time Series Analysis of Payment Methods", x = "Date", y = "Total Amount", color = "Payment Methods") +
  theme_economist() +
  theme(axis.text.x = element_text(angle = 45, hjust=1, vjust=1))

#Credit Limit Prediction Model
# Step 1: Stratified Sampling for Each Dataset
# Sample 10% of `transactions` based on `user_id`
set.seed(123)  # For reproducibility
transaction_sample <- transactions %>%
  group_by(client_id) %>%
  slice_sample(prop = 0.1)

# Sample 10% of `card_data` based on `user_id`
card_sample <- card_data %>%
  group_by(client_id) %>%
  slice_sample(prop = 0.3)

# Sample 10% of `user_data` based on `user_id`
user_sample <- user_data %>%
  group_by(current_age) %>%
  slice_sample(prop = 0.3)

# Step 2: Merge the Sampled Datasets
# Merge the sampled data using `user_id` as the key
sampled_data <- transaction_sample %>%
  left_join(card_sample, by = "client_id") %>%
  left_join(user_sample, by = c("client_id" = "id"))

# Step 3: Preprocessing - Create 'average_spending' and drop unnecessary columns
# Calculate average spending from transactions
avg_spending <- transaction_sample %>%
  group_by(client_id) %>%
  summarize(avg_spending = mean(amount))

# Add the average spending column to the merged dataset
sampled_data <- sampled_data %>%
  left_join(avg_spending, by = "client_id") %>%
  select(client_id, yearly_income, credit_score, current_age, total_debt, avg_spending, credit_limit)

features = c("yearly_income", "credit_score", "current_age","total_debt", "avg_spending")
target = "credit_limit"

# Step 4: Train-Test Split
# Remove rows with missing values
sampled_data <- na.omit(sampled_data)

# Split into training (80%) and testing (20%) sets
set.seed(123)
train_index <- createDataPartition(sampled_data$credit_limit, p = 0.8, list = FALSE)
train_data <- sampled_data[train_index, ]
test_data <- sampled_data[-train_index, ]

# Step 5: Train the Random Forest Regressor
rf_model <- randomForest(credit_limit ~ yearly_income + credit_score + current_age + total_debt + avg_spending, 
                         data = train_data, 
                         ntree = 100, 
                         importance = TRUE)

# Step 6: Evaluate the Model
# Predict on the test set
predictions <- predict(rf_model, test_data)

# Calculate RMSE for model evaluation
rmse <- sqrt(mean((predictions - test_data$credit_limit)^2))
print(paste("RMSE:", rmse))

# Step 7: Feature Importance
print(importance(rf_model))

# Combine actual and predicted credit limits into a single data frame
results <- data.frame(
  Actual = test_data$credit_limit,
  Predicted = predictions
)

# Scatter plot for Actual vs Predicted
ggplot(results, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.6, color = "blue") +  # Points for predictions
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +  # Line of perfect prediction
  labs(
    title = "Predicted vs Actual Credit Limits",
    x = "Actual Credit Limit",
    y = "Predicted Credit Limit"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))  # Center the title

mae <- mae(test_data$credit_limit, predictions)
rmse <- rmse(test_data$credit_limit, predictions)

# R² calculation
actual_mean <- mean(test_data$credit_limit)
ss_total <- sum((test_data$credit_limit - actual_mean)^2)
ss_residual <- sum((test_data$credit_limit - predictions)^2)
r2 <- 1 - (ss_residual / ss_total)

# Print the metrics
cat("Evaluation Metrics:\n")
cat("Mean Absolute Error (MAE):", round(mae, 2), "\n")
cat("Root Mean Squared Error (RMSE):", round(rmse, 2), "\n")
cat("R² Score:", round(r2, 2), "\n")

