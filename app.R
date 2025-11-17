###########################
# 1. Load Required Packages
###########################

# Shiny for the web app
library(shiny)

# dplyr & lubridate for data wrangling and dates
library(dplyr)
library(lubridate)

# ggplot2 for plotting
library(ggplot2)

# scales for pretty formatting of currency and percentages
library(scales)

# DT for interactive data tables
library(DT)


########################################
# Load the Data from transactions.csv
########################################

# NOTE: Making sure "transactions.csv" is in the same folder as this app.R file.

transactions_raw <- read.csv(
  "transactions.csv",
  stringsAsFactors = FALSE
)

# Taking a quick look at the structure in the console when developing


########################################
# Data Cleaning & Feature Setup
########################################

transactions <- transactions_raw %>%
  mutate(
    # Convert transaction_time from text to POSIXct datetime
    transaction_time = ymd_hms(transaction_time, tz = "UTC"),
    
    # Extract just the date for daily summaries
    date = as.Date(transaction_time)
  )

# For drop-down filters, it's nice to have sorted unique values
country_choices  <- sort(unique(transactions$country))
channel_choices  <- sort(unique(transactions$channel))
category_choices <- sort(unique(transactions$merchant_category))

# Get min and max dates for the date range filter
min_date <- min(transactions$date, na.rm = TRUE)
max_date <- max(transactions$date, na.rm = TRUE)


##################
# Define the UI
##################

ui <- fluidPage(
  
  # The title that appears at the top of the app
  titlePanel("Transaction & Fraud Analytics Dashboard"),
  
  # Sidebar + main panel layout
  sidebarLayout(
    
    #################
    # Sidebar UI
    #################
    sidebarPanel(
      h4("Filters"),
      
      # Date range input for transaction_date
      dateRangeInput(
        inputId = "date_range",
        label = "Transaction Date Range",
        start = min_date,
        end   = max_date,
        min   = min_date,
        max   = max_date
      ),
      
      # Drop-down to filter by country
      selectInput(
        inputId = "country",
        label = "Country",
        choices = c("All" = "all", country_choices),
        selected = "all"
      ),
      
      # Drop-down to filter by channel (e.g. web / app)
      selectInput(
        inputId = "channel",
        label = "Channel",
        choices = c("All" = "all", channel_choices),
        selected = "all"
      ),
      
      # Drop-down to filter by merchant category
      selectInput(
        inputId = "category",
        label = "Merchant Category",
        choices = c("All" = "all", category_choices),
        selected = "all"
      ),
      
      # Option to show all transactions or only the ones flagged as fraud
      radioButtons(
        inputId = "fraud_filter",
        label = "Transaction Type",
        choices = c(
          "All transactions" = "all",
          "Fraud only"       = "fraud"
        ),
        selected = "all"
      ),
      
      hr(),
      helpText("Data source: transactions.csv")
    ),
    
    ################
    # Main Panel
    ################
    mainPanel(
      tabsetPanel(
        
        # Tab 1: Overview with KPIs and time series plots
        tabPanel(
          "Overview",
          br(),
          
          # KPI Cards
          fluidRow(
            column(
              width = 3,
              wellPanel(
                h5("Total Transactions"),
                strong(textOutput("kpi_transactions"))
              )
            ),
            column(
              width = 3,
              wellPanel(
                h5("Total Amount"),
                strong(textOutput("kpi_amount"))
              )
            ),
            column(
              width = 3,
              wellPanel(
                h5("Avg Transaction Value"),
                strong(textOutput("kpi_avg_amount"))
              )
            ),
            column(
              width = 3,
              wellPanel(
                h5("Fraud Rate"),
                strong(textOutput("kpi_fraud_rate"))
              )
            )
          ),
          
          br(),
          
          # Time series plots
          fluidRow(
            column(
              width = 6,
              h4("Transactions Over Time"),
              plotOutput("plot_txn_time")
            ),
            column(
              width = 6,
              h4("Fraud Count Over Time"),
              plotOutput("plot_fraud_time")
            )
          )
        ),
        
        # Tab 2: Category & Country breakdowns
        tabPanel(
          "By Category & Country",
          br(),
          fluidRow(
            column(
              width = 6,
              h4("Total Amount by Merchant Category"),
              plotOutput("plot_amount_by_category")
            ),
            column(
              width = 6,
              h4("Fraud Rate by Country"),
              plotOutput("plot_fraud_by_country")
            )
          )
        ),
        
        # Tab 3: Customer profile distributions
        tabPanel(
          "Customer Profile",
          br(),
          fluidRow(
            column(
              width = 6,
              h4("Distribution of Account Age (days)"),
              plotOutput("plot_account_age")
            ),
            column(
              width = 6,
              h4("Transactions per User (field in dataset)"),
              plotOutput("plot_txn_per_user")
            )
          )
        ),
        
        # Tab 4: Data table
        tabPanel(
          "Data Table",
          br(),
          DTOutput("table_transactions")
        )
      )
    )
  )
)


#####################
# Define the Server
#####################

server <- function(input, output, session) {
  
  #########################################################
  # Reactive filtered dataset
  #########################################################
  
  filtered_data <- reactive({
    # Start with the full dataset
    df <- transactions
    
    # 1) Filter by date range
    df <- df %>%
      filter(
        date >= input$date_range[1],
        date <= input$date_range[2]
      )
    
    # 2) Filter by country if user did not select "All"
    if (input$country != "all") {
      df <- df %>% filter(country == input$country)
    }
    
    # 3) Filter by channel if user did not select "All"
    if (input$channel != "all") {
      df <- df %>% filter(channel == input$channel)
    }
    
    # 4) Filter by merchant category if user did not select "All"
    if (input$category != "all") {
      df <- df %>% filter(merchant_category == input$category)
    }
    
    # 5) If "Fraud only" is selected, keep only rows where is_fraud == 1
    if (input$fraud_filter == "fraud") {
      df <- df %>% filter(is_fraud == 1)
    }
    
    # Always return the final filtered result
    df
  })
  
  
  ############################
  #KPI Outputs (Overview)
  ############################
  
  # Total number of transactions after filters
  output$kpi_transactions <- renderText({
    n <- nrow(filtered_data())
    format(n, big.mark = ",")
  })
  
  # Total transaction amount after filters
  output$kpi_amount <- renderText({
    total_amount <- sum(filtered_data()$amount, na.rm = TRUE)
    dollar(total_amount)
  })
  
  # Average transaction value after filters
  output$kpi_avg_amount <- renderText({
    avg_amount <- mean(filtered_data()$amount, na.rm = TRUE)
    dollar(avg_amount)
  })
  
  # Proportion of transactions that are fraud
  output$kpi_fraud_rate <- renderText({
    df <- filtered_data()
    if (nrow(df) == 0) {
      return("0%")
    }
    
    fraud_rate <- mean(df$is_fraud == 1, na.rm = TRUE)
    percent(fraud_rate)
  })
  
  
  ######################################
  # Time Series Plots (Overview tab)
  ######################################
  
  # Plot: number of transactions per day
  output$plot_txn_time <- renderPlot({
    df_daily <- filtered_data() %>%
      group_by(date) %>%
      summarise(
        transactions = n(),
        .groups = "drop"
      )
    
    # If no data (e.g. filters are too restrictive), don't plot
    if (nrow(df_daily) == 0) {
      return(NULL)
    }
    
    ggplot(df_daily, aes(x = date, y = transactions)) +
      geom_line() +
      geom_point() +
      labs(
        x = "Date",
        y = "Number of Transactions"
      ) +
      theme_minimal()
  })
  
  # Plot: fraud count per day
  output$plot_fraud_time <- renderPlot({
    df_daily_fraud <- filtered_data() %>%
      group_by(date) %>%
      summarise(
        fraud_count = sum(is_fraud == 1),
        .groups = "drop"
      )
    
    if (nrow(df_daily_fraud) == 0) {
      return(NULL)
    }
    
    ggplot(df_daily_fraud, aes(x = date, y = fraud_count)) +
      geom_line() +
      geom_point() +
      labs(
        x = "Date",
        y = "Fraudulent Transactions"
      ) +
      theme_minimal()
  })
  
  
  ####################################################
  # Plots by Category and Country (2nd tab)
  ####################################################
  
  # Plot: total amount by merchant category
  output$plot_amount_by_category <- renderPlot({
    df_category <- filtered_data() %>%
      group_by(merchant_category) %>%
      summarise(
        total_amount = sum(amount, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      arrange(desc(total_amount))
    
    if (nrow(df_category) == 0) {
      return(NULL)
    }
    
    ggplot(df_category,
           aes(
             x = reorder(merchant_category, total_amount),
             y = total_amount
           )) +
      geom_col() +
      coord_flip() +
      labs(
        x = "Merchant Category",
        y = "Total Amount"
      ) +
      scale_y_continuous(labels = dollar) +
      theme_minimal()
  })
  
  # Plot: fraud rate by country
  output$plot_fraud_by_country <- renderPlot({
    df_country <- filtered_data() %>%
      group_by(country) %>%
      summarise(
        transactions = n(),
        fraud_rate = mean(is_fraud == 1),
        .groups = "drop"
      ) %>%
      # You can also filter out countries with very few transactions
      filter(transactions > 0)
    
    if (nrow(df_country) == 0) {
      return(NULL)
    }
    
    ggplot(df_country,
           aes(
             x = reorder(country, fraud_rate),
             y = fraud_rate
           )) +
      geom_col() +
      coord_flip() +
      labs(
        x = "Country",
        y = "Fraud Rate"
      ) +
      scale_y_continuous(labels = percent) +
      theme_minimal()
  })
  
  
  ##########################################
  # Customer Profile Plots (3rd tab)
  ##########################################
  
  # Distribution of account_age_days
  output$plot_account_age <- renderPlot({
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      return(NULL)
    }
    
    ggplot(df, aes(x = account_age_days)) +
      geom_histogram(bins = 30) +
      labs(
        x = "Account Age (days)",
        y = "Count of Transactions"
      ) +
      theme_minimal()
  })
  
  # Distribution of total_transactions_user
  output$plot_txn_per_user <- renderPlot({
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      return(NULL)
    }
    
    ggplot(df, aes(x = total_transactions_user)) +
      geom_histogram(bins = 30) +
      labs(
        x = "Total Transactions Per User (field)",
        y = "Count of Records"
      ) +
      theme_minimal()
  })
  
  
  ############################
  # Data Table (4th tab)
  ############################
  
  output$table_transactions <- renderDT({
    df <- filtered_data()
    
    datatable(
      df,
      options = list(
        pageLength = 20,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
}

##########################
# Run the Shiny App
##########################
shinyApp(ui = ui, server = server)
