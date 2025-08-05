# Building Agentic Workflows in R with axolotr

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D%204.1.0-blue)](https://www.r-project.org/)
[![Conference](https://img.shields.io/badge/UseR!-2025-green)](https://user2025.r-project.org/)

Materials for the UseR! 2025 conference presentation demonstrating how to build autonomous, self-correcting data analysis workflows using Large Language Models (LLMs) through the axolotr package.

## 🎯 Overview

This repository showcases practical agentic workflows in R, where multiple LLMs collaborate to:
- Generate exploratory data analysis plans
- Write and execute R code autonomously
- Self-correct when errors occur
- Review code for safety and correctness
- Save all outputs for reproducibility

**Conference Details:**
- **Date:** August 9, 2025
- **Time:** 14:45–16:00
- **Duration:** 15-minute talk + 5 minutes Q&A
- **Speaker:** Matthew Hirschey, Duke University

## 🚀 Quick Start

### Prerequisites

```r
# Install required packages
install.packages("tidyverse")
devtools::install_github("heurekalabsco/axolotr")
```

### Set up API Keys

```r
library(axolotr)

# Create .Renviron file with your API keys
create_credentials(
  OPENAI_API_KEY = "your_openai_key",
  ANTHROPIC_API_KEY = "your_anthropic_key",
  # Optional: Add other providers
  GOOGLE_GEMINI_API_KEY = "your_google_key",
  GROQ_API_KEY = "your_groq_key"
)

# Restart R session after setting credentials
```

### Run the Auto-EDA Demo

```r
# Load the auto-EDA tool
source("auto_eda.R")

# Run on any dataset
auto_eda(iris)

# Or with custom settings
auto_eda(
  mtcars,
  generation_model = "claude",    # Model for code generation
  review_model = "gpt-4o",        # Model for code review
  max_attempts = 3,               # Retry attempts on error
  debug = TRUE                    # Show generated code
)
```

## 📂 Repository Structure

```
useR_talk_axolotr/
├── auto_eda.R                 # Main auto-EDA implementation
├── presentation.qmd           # Quarto presentation slides
├── test_auto_eda.R           # Test script with examples
├── demo_output.md            # Sample output for backup
├── sample_output_structure.md # Shows output file organization
├── custom.scss               # Presentation styling
└── README.md                 # This file
```

## 🔧 Key Features

### 1. **Multi-Model Collaboration**
- Uses Claude for creative code generation
- Uses GPT-4 for code review and validation
- Easily switch between providers

### 2. **Error-Correcting Loops**
```r
# Automatically retries with error context
for (attempt in 1:max_attempts) {
  code <- generate_code(task, error_msg)
  result <- safe_eval(code)
  if (result$success) break
  error_msg <- result$error
}
```

### 3. **Comprehensive Output Saving**
```
auto_eda_output/
└── iris_20250809_143022/
    ├── analysis_summary.md    # Summary report
    ├── task_1_code.R         # Generated code
    ├── task_1_output.txt     # Console output
    ├── task_1_plot.png       # Visualizations
    └── ...
```

### 4. **Smart Package Management**
- Automatically installs missing packages
- Informs LLM about available packages
- Uses `require()` pattern for safe loading

## 🎓 Learning Objectives

After exploring this repository, you'll understand:

1. **Agentic Workflows** - Task-specific LLM chains vs full autonomous agents
2. **Error Handling** - How to build self-correcting systems
3. **Multi-Model Usage** - Leveraging different models' strengths
4. **Production Patterns** - Saving outputs, handling dependencies

## 📊 Example Output

Running `auto_eda(iris)` will:

1. Generate an analysis plan
2. Create summary statistics grouped by species
3. Build visualizations (boxplots, density plots)
4. Perform correlation analysis
5. Run PCA for dimensionality reduction
6. Save all code and outputs to timestamped directory

## 🛠️ Customization

### Use Different Models

```r
# Use Gemini for generation, Claude for review
auto_eda(data, generation_model = "gemini", review_model = "claude")

# Use Groq for fast inference
auto_eda(data, generation_model = "llama3-70b-8192")
```

### Control Package Installation

```r
# Disable automatic package installation
auto_eda(data, auto_install = FALSE)
```

### Custom Output Directory

```r
# Save to specific location
auto_eda(data, output_dir = "my_analysis/experiment_1")
```

## 📚 Resources

- **axolotr Package**: [github.com/heurekalabsco/axolotr](https://github.com/heurekalabsco/axolotr)
- **Presentation Slides**: Run `quarto render presentation.qmd`
- **Conference Website**: [user2025.r-project.org](https://user2025.r-project.org/)

## 🤝 Contributing

Feel free to:
- Open issues for bugs or suggestions
- Fork and submit pull requests
- Share your own agentic workflow examples

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- The axolotr package developers
- UseR! 2025 conference organizers
- Duke University Center for Computational Thinking

---

**Contact:**
- Matthew Hirschey
- Associate Professor, Duke University
- Director, Center for Computational Thinking
- GitHub: [@matthewhirschey](https://github.com/matthewhirschey)
- Email: matthew.hirschey@duke.edu