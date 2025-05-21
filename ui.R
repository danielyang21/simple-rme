library(shiny)
library(shinyMobile)

shinyApp(
  ui = f7Page(
    title = "Tooltip test",
    f7SingleLayout(
      navbar = f7Navbar(title = "Tooltip test"),
      f7Tooltip(
        f7Button(inputId = "btn", label = "Hover me", color = "blue"),
        text = "Tooltip text here!"
      )
    )
  ),
  server = function(input, output, session) {}
)
