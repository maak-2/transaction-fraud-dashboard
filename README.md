# Transaction and Fraud Analytics Dashboard (R Shiny)

## Project Title
Interactive R Shiny Dashboard for Transaction and Fraud Analysis

---

## Description
This project presents a fully interactive R Shiny dashboard used to analyse financial transaction data and investigate fraud patterns. 
It supports real-time filtering, KPI calculation, time-series visualisation, customer behaviour analysis, and merchant/country-level insights. 
The application is built with clean and well-documented R code suitable for academic, professional, and portfolio use.

---

## Project Overview
The Transaction and Fraud Analytics Dashboard provides an end-to-end analytical interface for exploring transaction-level datasets.  
It allows users to investigate transactional patterns, monitor fraud behaviour, and drill into customer-level metrics through an intuitive, dynamic dashboard.

The dashboard enables users to:
- Analyse daily transaction trends  
- Detect anomalies and fraudulent activity  
- Compare activity across countries, channels, and merchant categories  
- Understand customer characteristics such as account age and transaction frequency  
- Access a fully filter-aware dataset via an interactive data table  


---

## Data Source
this data was gotten from kaggle
[Download here](https://www.kaggle.com/datasets/umuttuygurr/e-commerce-fraud-detection-dataset)

**File:** `transactions.csv`  
**Type:** Transaction-level financial dataset 

### Dataset Columns
- `transaction_time`: Timestamp of the transaction  
- `amount`: Transaction amount  
- `country`: Customer country  
- `channel`: Web or app channel  
- `merchant_category`: Category of merchant  
- `total_transactions_user`: Total number of transactions by the user  
- `account_age_days`: Age of the customer’s account  
- `is_fraud`: Fraud flag (0 or 1)  

---

## Tech Stack
- R  
- Shiny  
- dplyr  
- ggplot2  
- lubridate  
- scales  
- DT  

---
