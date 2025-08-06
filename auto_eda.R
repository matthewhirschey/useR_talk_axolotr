# Auto-EDA: Automated Exploratory Data Analysis using LLMs
# This script demonstrates agentic workflows in R by using multiple LLMs
# to automatically generate, review, and execute data analysis code.

# Load required packages
library(axolotr)  # For unified LLM access
library(tidyverse)  # For data manipulation and visualization

# Get all installed packages on the system
# This allows the LLM to use any package the user has already installed,
# avoiding bias towards specific packages while still informing the LLM
# about what's available without requiring installation
get_installed_packages <- function() {
  # Get the names of all installed packages
  # This returns a character vector of package names
  installed <- rownames(installed.packages())
  return(installed)
}

# Safely evaluate generated code and capture all outputs
# This function is critical for the agentic workflow - it allows us to:
# 1. Execute potentially unsafe LLM-generated code in a controlled manner
# 2. Capture all outputs (text, plots) for later inspection
# 3. Handle errors gracefully and feed them back to the LLM
safe_eval_with_capture <- function(code_string, output_dir, task_num) {
  # First, validate that we actually have code to execute
  # LLMs sometimes return empty responses or just whitespace
  if (is.null(code_string) || stringr::str_trim(code_string) == "") {
    return(list(success = FALSE, result = NULL, error = "Generated code is empty"))
  }
  
  # Save the generated code to a file for:
  # 1. Reproducibility - users can re-run the analysis later
  # 2. Debugging - if something goes wrong, the code is preserved
  # 3. Learning - users can see what code the LLM generated
  code_file <- file.path(output_dir, stringr::str_glue("task_{task_num}_code.R"))
  writeLines(code_string, code_file)
  
  # Set up file paths for capturing outputs
  # We capture both text output (from print statements, summaries, etc.)
  # and graphical output (plots) separately
  output_file <- file.path(output_dir, stringr::str_glue("task_{task_num}_output.txt"))
  plot_file <- file.path(output_dir, stringr::str_glue("task_{task_num}_plot.png"))
  
  # Use tryCatch to handle any errors that occur during code execution
  # This is essential for the error-correcting loop - we need to capture
  # errors and pass them back to the LLM for fixing
  tryCatch({
    # Redirect all text output to a file using sink()
    # This captures print statements, summaries, etc.
    sink(output_file)
    # Ensure we stop sinking even if an error occurs
    on.exit(sink(), add = TRUE)
    
    # Set up plot capture if the code appears to create plots
    # We look for "ggplot" in the code as a heuristic
    # The regex also catches print(ggplot_object) patterns
    if (stringr::str_detect(code_string, "ggplot|print\\(.*ggplot")) {
      # Create a PNG device to capture the plot
      grDevices::png(plot_file, width = 800, height = 600)
      # Ensure we close the device even if an error occurs
      on.exit(grDevices::dev.off(), add = TRUE)
    }
    
    # Execute the code by sourcing the file
    # local = TRUE: Run in a local environment to avoid polluting global env
    # echo = FALSE: Don't print the code itself, just run it
    source(code_file, local = TRUE, echo = FALSE)
    
    list(
      success = TRUE, 
      result = "Code executed successfully", 
      error = NULL,
      code_file = code_file,
      output_file = output_file,
      plot_file = if(file.exists(plot_file)) plot_file else NULL
    )
  }, error = function(e) {
    list(
      success = FALSE, 
      result = NULL, 
      error = as.character(e),
      code_file = code_file,
      output_file = NULL,
      plot_file = NULL
    )
  })
}

# Clean up LLM responses to extract just the executable R code
# LLMs often return code wrapped in markdown code blocks (```r ... ```)
# or with explanatory text. This function extracts just the code.
clean_code <- function(raw_response) {
  # Start with the raw response
  code <- raw_response
  
  # Check if the response contains markdown code fences
  # LLMs often wrap code in ```r or just ```
  if (stringr::str_detect(code, "```")) {
    # Extract content between code fences
    # The regex matches ```r or ```R (optional) followed by newline,
    # then captures everything until the closing ```
    code <- code |>
      stringr::str_extract("```[rR]?\\s*\n([\\s\\S]*?)```") |>
      stringr::str_remove("```[rR]?\\s*\n") |>  # Remove opening fence
      stringr::str_remove("```$")  # Remove closing fence
  }
  
  # Trim whitespace
  code <- stringr::str_trim(code)
  
  # Return NULL if empty
  if (code == "" || is.na(code)) {
    return(NULL)
  }
  
  return(code)
}

# Generate an analysis plan based on the dataset structure
# This is the "thinking" phase where the LLM analyzes what would be
# most valuable to explore given the data's characteristics
generate_eda_plan <- function(data_summary, model = "claude") {
  # Construct a prompt that gives the LLM context about the data
  # and asks for specific, actionable analysis tasks
  prompt <- stringr::str_c(
    "Based on this dataset summary:\n",
    data_summary,
    "\n\nCreate a plan for exploratory data analysis. ",
    "List 3-5 specific analysis tasks that would be most informative. ",
    "Be concise and specific. Format as a numbered list."
  )
  
  # Send the prompt to the specified model and return the response
  axolotr::ask(prompt, model = model)
}

# Generate R code to perform a specific analysis task
# This is the core of the agentic workflow - the LLM acts as a code generator
# that can adapt based on previous errors (error-correcting loop)
generate_analysis_code <- function(task, data_name, previous_error = NULL, model = "claude", installed_packages = NULL) {
  # Inform the LLM about available packages to encourage their use
  # This prevents unnecessary package installations while giving the LLM
  # freedom to use any installed package (not just a curated list)
  # We don't show all packages (too many) but inform the LLM they exist
  package_info <- if (!is.null(installed_packages) && length(installed_packages) > 0) {
    stringr::str_c(
      "This system has ", length(installed_packages), " R packages installed.\n",
      "Common packages like tidyverse, ggplot2, dplyr, etc. are available.\n",
      "Feel free to use any standard R packages you need.\n",
      "For any package that might not be installed, use this pattern:\n"
    )
  } else {
    "For any packages beyond tidyverse, use this pattern:\n"
  }
  
  # Construct a detailed prompt that guides the LLM to generate
  # high-quality, executable R code
  prompt <- stringr::str_c(
    "Generate R code to perform this analysis task on the dataset '", data_name, "':\n",
    task, "\n\n",
    "Requirements:\n",
    "- Use tidyverse functions where appropriate\n",
    "- Include necessary library() calls at the beginning\n",
    "- ", package_info,
    "  if (!require(packagename, quietly = TRUE)) {\n",
    "    install.packages('packagename')\n",
    "    library(packagename)\n",
    "  }\n",
    "- Create informative visualizations with ggplot2 where applicable\n",
    "- For any plots, ensure they are displayed with print() if needed\n",
    "- Add clear titles and labels\n",
    "- Return ONLY executable R code, no explanations or markdown\n",
    "- Do not include any markdown code fences\n"
  )
  
  # If this is a retry after an error, include the error message
  # This is key to the error-correcting loop - the LLM learns from
  # previous failures and adjusts its code accordingly
  if (!is.null(previous_error)) {
    prompt <- stringr::str_c(
      prompt,
      "\nThe previous attempt failed with this error:\n",
      previous_error,
      "\nPlease fix the code to avoid this error.",
      "\nIf the error is about a missing package, use the require() pattern shown above."
    )
  }
  
  response <- axolotr::ask(prompt, model = model)
  clean_code(response)
}

# Review generated code for safety and correctness
# This implements a multi-model approach where one model generates
# and another model reviews, similar to pair programming
# The reviewer focuses only on critical issues to avoid being overly pedantic
review_code <- function(code, task, model = "gpt-4o") {
  # Handle edge case where no code was generated
  if (is.null(code) || code == "") {
    return("NEEDS_REVISION: No code was generated")
  }
  
  # Construct a prompt that asks for focused code review
  # We explicitly tell the reviewer to ignore minor issues
  # to prevent endless revision loops over style preferences
  prompt <- stringr::str_c(
    "Review this R code for CRITICAL issues only:\n",
    "Task: ", task, "\n\n",
    "Code:\n", code, "\n\n",
    "Check for:\n",
    "1. Syntax errors that would prevent execution\n",
    "2. Dangerous operations (file deletion, system commands, etc.)\n",
    "3. Infinite loops or operations that would hang\n",
    "\n",
    "IGNORE minor issues like:\n",
    "- Code style or redundancy\n",
    "- Suboptimal approaches (as long as they work)\n",
    "- Missing features (if core task is accomplished)\n",
    "\n",
    "Reply with 'APPROVED' if the code is safe to run and will accomplish the basic task.\n",
    "Only reply 'NEEDS_REVISION: [reason]' for CRITICAL issues that prevent execution."
  )
  
  axolotr::ask(prompt, model = model)
}

# Create a markdown summary report of all analyses performed
# This provides a high-level overview of what was attempted,
# what succeeded, and where to find the detailed outputs
create_summary_report <- function(output_dir, data_name, tasks, results, successful_analyses, total_tasks) {
  # Create the report file path
  report_file <- file.path(output_dir, "analysis_summary.md")
  
  report_lines <- c(
    stringr::str_glue("# Auto-EDA Report: {data_name}"),
    stringr::str_glue("Generated on: {Sys.time()}"),
    "",
    "## Summary",
    stringr::str_glue("- Total tasks: {total_tasks}"),
    stringr::str_glue("- Successful: {successful_analyses}"),
    stringr::str_glue("- Failed: {total_tasks - successful_analyses}"),
    "",
    "## Task Details",
    ""
  )
  
  # Add details for each task
  for (i in seq_along(tasks)) {
    task <- tasks[i] |> stringr::str_remove("^[0-9]\\. ")
    result <- results[[i]]
    
    report_lines <- c(
      report_lines,
      stringr::str_glue("### Task {i}: {task}"),
      stringr::str_glue("- Status: {if(result$success) '✅ Success' else '❌ Failed'}"),
      if(!is.null(result$code_file)) stringr::str_glue("- Code: `{basename(result$code_file)}`") else NULL,
      if(!is.null(result$output_file)) stringr::str_glue("- Output: `{basename(result$output_file)}`") else NULL,
      if(!is.null(result$plot_file)) stringr::str_glue("- Plot: `{basename(result$plot_file)}`") else NULL,
      if(!is.null(result$error)) stringr::str_glue("- Error: {result$error}") else NULL,
      ""
    )
  }
  
  writeLines(report_lines, report_file)
  report_file
}

# Main function: Automated Exploratory Data Analysis
# This orchestrates the entire agentic workflow:
# 1. Analyze the dataset structure
# 2. Generate an analysis plan
# 3. For each task: generate code, review it, execute it
# 4. Handle errors with retry logic
# 5. Save all outputs for reproducibility
auto_eda <- function(data,                      # The dataset to analyze
                    max_attempts = 3,           # Max retries per task (error-correcting loop)
                    generation_model = "claude", # Model for generating code
                    review_model = "gpt-4o",     # Model for reviewing code  
                    output_dir = NULL,          # Where to save outputs
                    debug = FALSE,              # Show generated code?
                    auto_install = TRUE) {      # Allow automatic package installation
  
  cat("🔍 Starting Automated Exploratory Data Analysis\n")
  cat("Using", generation_model, "for code generation and", review_model, "for review\n")
  cat("Auto-install packages:", if(auto_install) "enabled" else "disabled", "\n\n")
  
  data_name <- deparse(substitute(data))
  
  # Create output directory
  if (is.null(output_dir)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_dir <- file.path("auto_eda_output", stringr::str_glue("{data_name}_{timestamp}"))
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  cat("📁 Output directory:", output_dir, "\n\n")
  
  # Save the dataset for reference
  data_file <- file.path(output_dir, "dataset.rds")
  saveRDS(data, data_file)
  
  cat("📊 Dataset Overview:\n")
  data_summary <- capture.output({
    cat("Dataset:", data_name, "\n")
    cat("Dimensions:", nrow(data), "rows x", ncol(data), "columns\n")
    dplyr::glimpse(data)
  })
  data_summary <- data_summary |> stringr::str_c(collapse = "\n")
  cat(data_summary, "\n\n")
  
  # Save data summary
  writeLines(data_summary, file.path(output_dir, "data_summary.txt"))
  
  # Get all installed packages to inform the LLM
  # This avoids package bias while still helping the LLM make informed choices
  installed_packages <- get_installed_packages()
  if (debug) {
    cat("📦 Total installed packages:", length(installed_packages), "\n\n")
  }
  
  cat("📋 Generating Analysis Plan...\n")
  analysis_plan <- generate_eda_plan(data_summary, model = generation_model)
  cat(analysis_plan, "\n\n")
  
  # Save analysis plan
  writeLines(analysis_plan, file.path(output_dir, "analysis_plan.txt"))
  
  tasks <- analysis_plan |>
    stringr::str_split("\n") |>
    purrr::pluck(1) |>
    stringr::str_subset("^[0-9]\\.")
  
  if (length(tasks) == 0) {
    cat("⚠️  No tasks found in the analysis plan. Please check the LLM response.\n")
    return(invisible(NULL))
  }
  
  successful_analyses <- 0
  task_results <- list()
  
  tasks |>
    purrr::imap(function(task_raw, i) {
      task <- task_raw |> stringr::str_remove("^[0-9]\\. ")
      cat("\n🔧 Task", i, ":", task, "\n")
      
      error_msg <- NULL
      result <- list(success = FALSE)
      
      for (attempt in 1:max_attempts) {
        cat("  Attempt", attempt, "- Generating code...\n")
        
        # Generate code for this task, passing along any previous error messages
        # and the list of installed packages
        code <- generate_analysis_code(task, data_name, error_msg, 
                                     model = generation_model, 
                                     installed_packages = installed_packages)
        
        if (is.null(code)) {
          cat("  ❌ No code generated\n")
          error_msg <- "No code was generated by the model"
          if (attempt < max_attempts) {
            cat("  Trying again...\n")
          }
          next
        }
        
        if (debug) {
          cat("  📝 Generated code:\n")
          cat(code, "\n")
        }
        
        cat("  Reviewing code with", review_model, "...\n")
        review <- review_code(code, task, model = review_model)
        
        if (!stringr::str_detect(review, stringr::regex("APPROVED", ignore_case = TRUE))) {
          cat("  ❌ Code review failed:", review, "\n")
          error_msg <- review
          next
        }
        
        cat("  ✓ Code approved. Executing...\n")
        
        result <- safe_eval_with_capture(code, output_dir, i)
        
        if (result$success) {
          cat("  ✅ Success!\n")
          if (!is.null(result$output_file)) {
            cat("  📄 Output saved to:", basename(result$output_file), "\n")
          }
          if (!is.null(result$plot_file)) {
            cat("  📊 Plot saved to:", basename(result$plot_file), "\n")
          }
          successful_analyses <<- successful_analyses + 1
          break
        } else {
          cat("  ❌ Error:", result$error, "\n")
          error_msg <- result$error
          if (attempt < max_attempts) {
            cat("  Regenerating code to fix error...\n")
          }
        }
      }
      
      if (!result$success) {
        cat("  ⚠️  Failed after", max_attempts, "attempts\n")
      }
      
      task_results[[i]] <<- result
    })
  
  # Create summary report
  report_file <- create_summary_report(
    output_dir, data_name, tasks, task_results, 
    successful_analyses, length(tasks)
  )
  
  cat("\n📈 Analysis Complete!\n")
  cat("Successfully completed", successful_analyses, "out of", length(tasks), "tasks\n")
  cat("\n📁 All outputs saved to:", output_dir, "\n")
  cat("📋 Summary report:", basename(report_file), "\n")
  
  invisible(list(
    output_dir = output_dir,
    successful = successful_analyses,
    total = length(tasks),
    results = task_results
  ))
}

# Demo function to showcase the auto-EDA capabilities
# Uses the built-in mtcars dataset as an example
demo_auto_eda <- function() {
  cat("Demo: Running auto-EDA on mtcars dataset\n")
  cat(stringr::str_dup("=", 50), "\n\n")
  
  # Run auto-EDA with default settings
  # This demonstrates the multi-model approach:
  # - Claude generates creative analysis code  
  # - GPT-4 reviews for safety and correctness
  auto_eda(mtcars, generation_model = "claude", review_model = "gpt-4o")
}

# Print helpful messages when the script is sourced
cat("Auto-EDA script loaded successfully!\n")
cat("Usage: auto_eda(your_dataset)\n")
cat("Demo: demo_auto_eda()\n")

# This script demonstrates key concepts in agentic workflows:
# 1. Multi-model collaboration (generation + review)
# 2. Error-correcting loops with retry logic
# 3. Safe execution of LLM-generated code
# 4. Comprehensive output capture for reproducibility
# 5. Unbiased package usage - LLM can use any installed package