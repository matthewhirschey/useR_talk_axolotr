# Sample Auto-EDA Output Structure

When you run `auto_eda(iris)`, it creates the following directory structure:

```
auto_eda_output/
└── iris_20241209_143022/
    ├── dataset.rds              # Original dataset
    ├── data_summary.txt         # Dataset overview
    ├── analysis_plan.txt        # LLM-generated plan
    ├── analysis_summary.md      # Final report
    │
    ├── task_1_code.R           # Generated R code for task 1
    ├── task_1_output.txt       # Console output from task 1
    ├── task_1_plot.png         # Plot from task 1 (if any)
    │
    ├── task_2_code.R           # Generated R code for task 2
    ├── task_2_output.txt       # Console output from task 2
    ├── task_2_plot.png         # Plot from task 2
    │
    ├── task_3_code.R           # etc...
    ├── task_3_output.txt
    │
    ├── task_4_code.R
    ├── task_4_output.txt
    ├── task_4_plot.png
    │
    └── task_5_code.R
        └── task_5_output.txt
```

## Example Files

### task_1_code.R
```r
library(tidyverse)

iris %>%
  group_by(Species) %>%
  summarise(
    across(where(is.numeric), 
           list(mean = mean, 
                median = median, 
                min = min, 
                max = max, 
                sd = sd))
  ) %>%
  print()
```

### task_2_plot.png
A multi-panel plot showing boxplots of all measurements by species

### analysis_summary.md
```markdown
# Auto-EDA Report: iris
Generated on: 2024-12-09 14:30:22

## Summary
- Total tasks: 5
- Successful: 5
- Failed: 0

## Task Details

### Task 1: Generate summary statistics...
- Status: ✅ Success
- Code: `task_1_code.R`
- Output: `task_1_output.txt`

### Task 2: Create boxplots or violin plots...
- Status: ✅ Success
- Code: `task_2_code.R`
- Output: `task_2_output.txt`
- Plot: `task_2_plot.png`

...
```

This structure ensures all generated content is preserved and reusable!