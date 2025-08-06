# Test script for auto_eda function
# This script tests the function with a small dataset

# Load required libraries
library(axolotr)
library(tidyverse)

# Source the auto_eda function
source("auto_eda.R")

# Test with iris dataset (smaller than mtcars, good for quick demo)
cat("Testing auto_eda with iris dataset\n")

# You can test with different model combinations
auto_eda(iris, max_attempts = 2, generation_model = "claude", review_model = "gpt-4o")

# # For a quick test without API calls, here's a mock version
# test_auto_eda_mock <- function() {
#   cat("🔍 Starting Automated Exploratory Data Analysis\n")
#   cat("Using claude for code generation and gpt-4o for review\n\n")
#
#   cat("📊 Dataset Overview:\n")
#   cat("Dataset: iris\n")
#   cat("Dimensions: 150 rows x 5 columns\n")
#   glimpse(iris)
#
#   cat("\n📋 Generating Analysis Plan...\n")
#   cat("1. Visualize the distribution of each numeric variable\n")
#   cat("2. Create scatter plots to explore relationships between variables\n")
#   cat("3. Compare measurements across different species\n")
#   cat("4. Check for missing values and data quality issues\n")
#   cat("5. Generate summary statistics by species\n\n")
#
#   cat("🔧 Task 1: Visualize the distribution of each numeric variable\n")
#   cat("  Attempt 1 - Generating code...\n")
#   cat("  Reviewing code with gpt-4o...\n")
#   cat("  ✓ Code approved. Executing...\n")
#
#   # Create a simple histogram
#   p1 <- ggplot(iris, aes(x = Sepal.Length)) +
#     geom_histogram(bins = 20, fill = "steelblue", color = "white") +
#     labs(title = "Distribution of Sepal Length",
#          x = "Sepal Length (cm)",
#          y = "Count") +
#     theme_minimal()
#   print(p1)
#
#   cat("  ✅ Success!\n\n")
#
#   cat("🔧 Task 2: Create scatter plots to explore relationships\n")
#   cat("  Attempt 1 - Generating code...\n")
#   cat("  Reviewing code with gpt-4o...\n")
#   cat("  ✓ Code approved. Executing...\n")
#
#   # Create a scatter plot
#   p2 <- ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
#     geom_point(size = 3, alpha = 0.7) +
#     labs(title = "Sepal Length vs Width by Species",
#          x = "Sepal Length (cm)",
#          y = "Sepal Width (cm)") +
#     theme_minimal()
#   print(p2)
#
#   cat("  ✅ Success!\n\n")
#
#   cat("📈 Analysis Complete!\n")
#   cat("Successfully completed 2 out of 5 tasks\n")
# }
#
# # Run the mock test
# test_auto_eda_mock()
