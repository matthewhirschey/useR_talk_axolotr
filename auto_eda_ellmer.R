# Auto-EDA using Ellmer: Automated Exploratory Data Analysis using LLMs
# This script demonstrates agentic workflows in R using the Ellmer package
# to automatically generate, review, and execute data analysis code.

# Load required packages
if (!require(ellmer, quietly = TRUE)) {
  install.packages("ellmer", repos = "https://cloud.r-project.org/")
  library(ellmer)
}
library(tidyverse)  # For data manipulation and visualization

# Get all installed packages on the system
get_installed_packages <- function() {
  installed <- rownames(installed.packages())
  return(installed)
}

# Safely evaluate generated code and capture all outputs
safe_eval_with_capture <- function(code_string, output_dir, task_num) {
  if (is.null(code_string) || stringr::str_trim(code_string) == "") {
    return(list(success = FALSE, result = NULL, error = "Generated code is empty"))
  }
  
  code_file <- file.path(output_dir, stringr::str_glue("task_{task_num}_code.R"))
  writeLines(code_string, code_file)
  
  output_file <- file.path(output_dir, stringr::str_glue("task_{task_num}_output.txt"))
  plot_file <- file.path(output_dir, stringr::str_glue("task_{task_num}_plot.png"))
  
  tryCatch({
    sink(output_file)
    on.exit(sink(), add = TRUE)
    
    if (stringr::str_detect(code_string, "ggplot|print\\(.*ggplot")) {
      grDevices::png(plot_file, width = 800, height = 600)
      on.exit(grDevices::dev.off(), add = TRUE)
    }
    
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
clean_code <- function(raw_response) {
  code <- raw_response
  
  if (stringr::str_detect(code, "```")) {
    code <- code |>
      stringr::str_extract("```[rR]?\\s*\n([\\s\\S]*?)```") |>
      stringr::str_remove("```[rR]?\\s*\n") |>
      stringr::str_remove("```$")
  }
  
  code <- stringr::str_trim(code)
  
  if (code == "" || is.na(code)) {
    return(NULL)
  }
  
  return(code)
}

# Helper function to send prompts to LLMs using Ellmer
send_to_llm <- function(prompt, model = "claude") {
  # Create appropriate chat interface based on model selection
  if (model == "claude") {
    # Use chat_anthropic from ellmer (chat_claude is deprecated)
    chat <- chat_anthropic(echo = "none")
  } else if (model %in% c("gpt-4o", "gpt-4", "gpt-3.5-turbo")) {
    # Use chat_openai from ellmer
    chat <- chat_openai(model = model, echo = "none")
  } else if (model == "gemini") {
    # Use chat_gemini from ellmer
    chat <- chat_gemini(echo = "none")
  } else if (model == "ollama") {
    # Use chat_ollama for local models
    chat <- chat_ollama(echo = "none")
  } else {
    # Default to Claude
    warning(paste("Unknown model:", model, "- defaulting to Claude"))
    chat <- chat_anthropic(echo = "none")
  }
  
  # Send the prompt and get response
  # Ellmer returns the response directly from the chat method
  response <- chat$chat(prompt)
  
  return(response)
}

# Generate an analysis plan based on the dataset structure
generate_eda_plan <- function(data_summary, model = "claude") {
  prompt <- stringr::str_c(
    "Based on this dataset summary:\n",
    data_summary,
    "\n\nCreate a plan for exploratory data analysis. ",
    "List 3-5 specific analysis tasks that would be most informative. ",
    "Be concise and specific. Format as a numbered list."
  )
  
  send_to_llm(prompt, model = model)
}

# Generate R code to perform a specific analysis task
generate_analysis_code <- function(task, data_name, previous_error = NULL, model = "claude", installed_packages = NULL) {
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
  
  if (!is.null(previous_error)) {
    prompt <- stringr::str_c(
      prompt,
      "\nThe previous attempt failed with this error:\n",
      previous_error,
      "\nPlease fix the code to avoid this error.",
      "\nIf the error is about a missing package, use the require() pattern shown above."
    )
  }
  
  response <- send_to_llm(prompt, model = model)
  clean_code(response)
}

# Review generated code for safety and correctness
review_code <- function(code, task, model = "gpt-4o") {
  if (is.null(code) || code == "") {
    return("NEEDS_REVISION: No code was generated")
  }
  
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
  
  send_to_llm(prompt, model = model)
}

# Create a markdown summary report of all analyses performed
create_summary_report <- function(output_dir, data_name, tasks, results, successful_analyses, total_tasks) {
  report_file <- file.path(output_dir, "analysis_summary.md")
  
  report_lines <- c(
    stringr::str_glue("# Auto-EDA Report (Ellmer): {data_name}"),
    stringr::str_glue("Generated on: {Sys.time()}"),
    stringr::str_glue("Powered by: Ellmer package"),
    "",
    "## Summary",
    stringr::str_glue("- Total tasks: {total_tasks}"),
    stringr::str_glue("- Successful: {successful_analyses}"),
    stringr::str_glue("- Failed: {total_tasks - successful_analyses}"),
    "",
    "## Task Details",
    ""
  )
  
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

# Main function: Automated Exploratory Data Analysis using Ellmer
auto_eda_ellmer <- function(data,
                           max_attempts = 3,
                           generation_model = "claude",
                           review_model = "gpt-4o",
                           output_dir = NULL,
                           debug = FALSE,
                           auto_install = TRUE) {
  
  cat("🔍 Starting Automated Exploratory Data Analysis (Ellmer version)\n")
  cat("Using", generation_model, "for code generation and", review_model, "for review\n")
  cat("Powered by: Ellmer package for LLM interactions\n")
  cat("Auto-install packages:", if(auto_install) "enabled" else "disabled", "\n\n")
  
  data_name <- deparse(substitute(data))
  
  # Create output directory
  if (is.null(output_dir)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_dir <- file.path("auto_eda_ellmer_output", stringr::str_glue("{data_name}_{timestamp}"))
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

# Demo function to showcase the auto-EDA capabilities using Ellmer
demo_auto_eda_ellmer <- function() {
  cat("Demo: Running auto-EDA on mtcars dataset using Ellmer\n")
  cat(stringr::str_dup("=", 50), "\n\n")
  
  # Run auto-EDA with Ellmer
  # This demonstrates the multi-model approach using Ellmer:
  # - Claude generates creative analysis code  
  # - GPT-4 reviews for safety and correctness
  auto_eda_ellmer(mtcars, generation_model = "claude", review_model = "gpt-4o")
}

# Print helpful messages when the script is sourced
cat("Auto-EDA script (Ellmer version) loaded successfully!\n")
cat("Usage: auto_eda_ellmer(your_dataset)\n")
cat("Demo: demo_auto_eda_ellmer()\n")
cat("\nThis version uses the Ellmer package for LLM interactions\n")
cat("Ellmer supports: Claude, OpenAI, Gemini, Ollama, and many more providers\n")