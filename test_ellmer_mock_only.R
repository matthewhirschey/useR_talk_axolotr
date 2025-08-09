# Mock test for Ellmer-based auto-EDA (without API calls)
library(tidyverse)

test_auto_eda_ellmer_mock <- function() {
  cat("🔍 Starting Automated Exploratory Data Analysis (Ellmer version)\n")
  cat("Using Claude for code generation and GPT-4o for review\n\n")
  
  cat("📊 Dataset Overview:\n")
  cat("Dataset: iris\n")
  cat("Dimensions: 150 rows x 5 columns\n")
  glimpse(iris)
  
  cat("\n📋 Generating Analysis Plan...\n")
  cat("1. Visualize the distribution of each numeric variable\n")
  cat("2. Create scatter plots to explore relationships between variables\n")
  cat("3. Compare measurements across different species\n")
  cat("4. Check for missing values and data quality issues\n")
  cat("5. Generate summary statistics by species\n\n")
  
  cat("🔧 Task 1: Visualize the distribution of each numeric variable\n")
  cat("  Attempt 1 - Generating code with Ellmer's chat_anthropic()...\n")
  cat("  Reviewing code with Ellmer's chat_openai()...\n")
  cat("  ✓ Code approved. Executing...\n")
  
  # Create a simple histogram
  p1 <- ggplot(iris, aes(x = Sepal.Length)) +
    geom_histogram(bins = 20, fill = "steelblue", color = "white") +
    labs(title = "Distribution of Sepal Length",
         x = "Sepal Length (cm)",
         y = "Count") +
    theme_minimal()
  print(p1)
  
  cat("  ✅ Success!\n\n")
  
  cat("🔧 Task 2: Create scatter plots to explore relationships\n")
  cat("  Attempt 1 - Generating code with Ellmer's chat_anthropic()...\n")
  cat("  Reviewing code with Ellmer's chat_openai()...\n")
  cat("  ✓ Code approved. Executing...\n")
  
  # Create a scatter plot
  p2 <- ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
    geom_point(size = 3, alpha = 0.7) +
    labs(title = "Sepal Length vs Width by Species",
         x = "Sepal Length (cm)",
         y = "Sepal Width (cm)") +
    theme_minimal()
  print(p2)
  
  cat("  ✅ Success!\n\n")
  
  cat("📈 Analysis Complete!\n")
  cat("Successfully completed 2 out of 5 tasks\n")
  cat("Using Ellmer package for LLM interactions\n")
}

# Run the test
test_auto_eda_ellmer_mock()