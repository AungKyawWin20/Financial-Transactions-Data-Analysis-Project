library(dplyr)
library(jsonlite)
library(ggplot2)

merchant_codes <- fromJSON("D:/Education/Data Science/Programming with R/FinalProject/mcc_codes.json")
head(merchant_codes)

#Convert to df

mcc_df = as.data.frame(do.call(rbind, merchant_codes))
head(mcc_df)

# no columns names and codes are set as index

mcc_df <- mcc_df %>% rename(
  full_description = V1)

summary(mcc_df)

#start data cleaning

mcc_df <- na.omit(mcc_df)
mcc_df <- mcc_df %>% mutate_all(~ifelse(is.na(.), 0, .))
mcc_df <- mcc_df %>% distinct()
summary(mcc_df)

#checking other files data

cards_data <- cards_data
summary(cards_data)

mcc_df
