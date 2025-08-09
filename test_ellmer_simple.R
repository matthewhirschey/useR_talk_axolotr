# Simple test of Ellmer integration
library(ellmer)

# Test the send_to_llm function directly
test_ellmer_api <- function() {
  cat("Testing Ellmer API integration...\n")
  
  # Create a simple chat
  chat <- chat_anthropic(echo = "none")
  
  # Send a simple prompt
  prompt <- "Say 'Hello from Ellmer' and nothing else."
  response <- chat$chat(prompt)
  
  cat("Response received:", response, "\n")
  
  if (grepl("Hello from Ellmer", response, ignore.case = TRUE)) {
    cat("✅ Test passed!\n")
  } else {
    cat("❌ Test failed - unexpected response\n")
  }
}

# Run the test (uncomment to use)
# test_ellmer_api()