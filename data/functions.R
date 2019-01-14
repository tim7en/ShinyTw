
cleanText <- function (x){
  # extract text
  x_text <- x$text
  # convert all text to lower case
  x_text <- tolower(x_text)
  # Replace blank space ("rt")
  x_text <- gsub("rt", "", x_text)
  # Replace @UserName
  x_text <- gsub("@\\w+", "", x_text)
  # Remove punctuation
  x_text <- gsub("[[:punct:]]", "", x_text)
  # Remove links
  x_text <- gsub("http\\w+", "", x_text)
  # Remove tabs
  x_text <- gsub("[ |\t]{2,}", "", x_text)
  # Remove blank spaces at the beginning
  x_text <- gsub("^ ", "", x_text)
  # Remove blank spaces at the end
  x_text <- gsub(" $", "", x_text)
  return (x_text)
}