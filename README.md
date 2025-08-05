# Building Agentic Workflows in R with axolotr

UseR! 2025 Conference Presentation Materials

## Overview

This repository contains the presentation and code for the UseR! 2025 talk "Building Agentic Workflows in R with axolotr". The talk demonstrates how to leverage Large Language Models (LLMs) in R through the axolotr package to create automated, self-correcting data analysis workflows.

## Files

- `presentation.qmd` - Quarto presentation slides
- `auto_eda.R` - Main script implementing automated exploratory data analysis
- `test_auto_eda.R` - Test script with mock demonstration
- `demo_output.md` - Sample output for backup during live demo
- `custom.scss` - Custom styling for the presentation

## Running the Presentation

1. Install required packages:
```r
install.packages(c("quarto", "tidyverse"))
devtools::install_github("heurekalabsco/axolotr")
```

2. Set up API keys:
```r
library(axolotr)
create_credentials(
  OPENAI_API_KEY = "your_key",
  ANTHROPIC_API_KEY = "your_key"
)
```

3. Render the presentation:
```r
quarto::quarto_render("presentation.qmd")
```

## Using the Auto-EDA Tool

```r
source("auto_eda.R")

# Run on any dataset
auto_eda(your_data, 
         generation_model = "claude",
         review_model = "gpt-4o")

# Or use the demo
demo_auto_eda()
```

## Key Concepts Demonstrated

1. **Agentic Workflows**: Task-specific LLM chains that can self-correct
2. **Multi-Model Usage**: Leveraging different models for different tasks
3. **Error Handling**: Automatic retry with error context
4. **Code Generation & Review**: Two-step process for safer execution

## About

**Author**: Matthew Hirschey  
**Date**: August 9, 2025  
**Conference**: UseR! 2025  
**Duration**: 15-minute talk + 5 minutes Q&A

## License

This project is licensed under the MIT License.