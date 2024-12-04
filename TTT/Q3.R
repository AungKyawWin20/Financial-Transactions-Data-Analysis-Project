library(dplyr)
library(ggplot2)
library(jsonlite)
library(ggthemes)

data <- transactions_data
#head(data)
mcc <- read_json("D:/Education/Data Science/Programming with R/FinalProject/mcc_codes.json") %>% 
  as.data.frame() %>% 
  stack() %>% 
  mutate(ind=gsub("\\X", "", ind)) %>% 
  rename(mcc=ind, transaction_type=values)

#Since there are a lot to process I will segment the data

df_selected <- data %>% select(date, amount, use_chip, merchant_city, mcc)

#Joining mcc data set with this

df_selected$mcc <- as.character(df_selected$mcc)
df_selected <- left_join(df_selected, mcc, by = "mcc")

#Cleaning the amount column

df_selected$amount <- gsub("\\$", "", df_selected$amount)  # Remove dollar signs
df_selected$amount <- gsub("^-", "", df_selected$amount) 
df_selected$amount <- gsub("-", "", df_selected$amount)

df_selected$amount <- as.numeric(df_selected$amount)

#Changing the "Chip Transaction" to "Online Transaction" for data consistency

df_selected <- df_selected %>% 
  mutate(use_chip = ifelse(use_chip == "Chip Transaction", "Online Transaction", use_chip))

#Is there a difference in spending behavior 
#between online (chip-based) and in-store (swipe-based) transactions?

# Calculating summary statistics for each transaction type
chip_based_stats <- df_selected %>% filter(use_chip == "Online Transaction") %>%
  summarise(
    count = n(),
    total_amount = sum(amount, na.rm = TRUE),
    mean_amount = mean(amount, na.rm = TRUE),
    median_amount = median(amount, na.rm = TRUE),
    std_amount = sd(amount, na.rm = TRUE)
  )

swipe_based_stats <- df_selected %>% filter(use_chip == "Swipe Transaction") %>%
  summarise(
    count = n(),
    total_amount = sum(amount, na.rm = TRUE),
    mean_amount = mean(amount, na.rm = TRUE),
    median_amount = median(amount, na.rm = TRUE),
    std_amount = sd(amount, na.rm = TRUE)
  )

chip_based_stats
swipe_based_stats

#The number of transactions for each type and payment method
top_transactions <- df_selected %>%
  group_by(use_chip, transaction_type) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  group_by(use_chip) %>%
  slice_head(n = 5)

ggplot(top_transactions, aes(x = reorder(transaction_type, -count), y = count, fill = use_chip)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Top 5 Transaction Types by Payment Method", x = "Transaction Type", y = "Count", color = "Payment Method") +
  theme_economist() +
  theme(axis.text.x = element_text(angle = 70, hjust=1, vjust=1))

# Payment Method Based on Merchant City
payment_by_location <- df_selected %>%
  group_by(use_chip, merchant_city) %>%
  summarise(count = n(), .groups = 'drop') %>%
  arrange(desc(count)) %>%
  group_by(use_chip) %>%
  slice_max(count, n = 5) %>%
  ungroup() %>% 
  arrange(desc(count))

ggplot(payment_by_location, aes(x = reorder(merchant_city, -count), y = count, fill = use_chip)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Top 5 Cities by Payment Method", x = "Merchant City", y = "Total Transactions", color = "Payment Methods") +
  theme_economist() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust=1)) +
  facet_wrap(~ use_chip, scales = "free_y", ncol = 1)

#TimeSeriesAnalysis on Payment Method Overtime
df_selected$date <- as.Date(df_selected$date)

time_series_data <- df_selected %>%
  group_by(date, use_chip) %>%
  summarise(total_amount = sum(amount), .groups = 'drop')

ggplot(time_series_data, aes(x = date, y = total_amount, color = use_chip, group = use_chip)) +
  geom_line(size = 0.2) +
  labs(title = "Time Series Analysis of Payment Methods", x = "Date", y = "Total Amount", color = "Payment Methods") +
  theme_economist() +
  theme(axis.text.x = element_text(angle = 45, hjust=1, vjust=1))




