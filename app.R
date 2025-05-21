library(shiny)
library(tidyverse)
library(rvest)
library(xml2)
library(purrr)

xml_to_dataframe <- function(nodeset){
  if(class(nodeset) != 'xml_nodeset'){ stop('Input should be "xml_nodeset" class') }
  lst <- lapply(nodeset, function(x){
    tmp <- xml2::xml_text(xml2::xml_children(x))
    names(tmp) <- xml2::xml_name(xml2::xml_children(x))
    return(as.list(tmp))
  })
  result <- do.call(plyr::rbind.fill, lapply(lst, function(x)
    as.data.frame(x, stringsAsFactors = F)))
  return(dplyr::as.tbl(result))
}

d = xml_children(read_xml('https://nrc-digital-repository.canada.ca/eng/search/atom/?q=*&fc=%2Bcn%3Acrm'))
nrc_dr_all = xml_to_dataframe(d)[-1,-c(1,2)]
nrc_dr_all$name = sapply(str_split(nrc_dr_all$title,":"), function(x) x[1])
nrc_dr_all = nrc_dr_all[!is.na(nrc_dr_all$title),]

crms = sort(nrc_dr_all$name)
names(crms) = crms

#The ui is the front end
ui <- fluidPage(
  
  #App title
  titlePanel("NRC CRM Digital Repository"),
  h6("v2. 2024"),
  textInput("searchCRM", h4("Search CRMs")),
  actionButton("submit","Submit"),
  uiOutput("selectCRM"),
  h4(textOutput('title')),
  htmlOutput('summary'), uiOutput('doi'), htmlOutput('date'), br(),
  fluidRow(column(DT::dataTableOutput('table'), width=12))
)

server <- function(input, output) {
  v <- reactiveValues('data' = nrc_dr_all, 'crms' = crms, 'doi' = NULL, 'abstract' = NULL, 'date' = NULL)
   
  observeEvent(input$submit, {
    req(input$selectCRM)
    req(length(input$selectCRM)>0)
    if(input$searchCRM=='') {v$data = nrc_dr_all}
    if(input$searchCRM=='No results') {v$data = NULL; v$crms = NULL}
    else { 
      phrase = input$searchCRM
      link = paste0('https://nrc-digital-repository.canada.ca/eng/search/atom/?q=',gsub(' ','+',input$searchCRM),'&fc=%2Bcn%3Acrm')
      d = xml_children(read_xml(link))
      df = xml_to_dataframe(d)[-1,-c(1,2)]
      
      df$name = sapply(str_split(df$title,":"), function(x) x[1])
      df = df[!is.na(df$title),]
      v$data = df
      
      crms = sort(df$name)
      names(crms) = crms
      v$crms = crms
    }
  })
  output$selectCRM = renderUI({
    req(v$data)
    selectInput(inputId = "selectCRM", label =   h4("Select a CRM"), 
                choices = v$crms)
  })
  
  output$title   <- renderText({ 
    req(input$selectCRM)
    req(length(input$selectCRM)>0)
    if(input$selectCRM=='No results') return('')
    if(v$data$title[1]=='No results') return('')
    paste(v$data[v$data$name == input$selectCRM, 'title']) 
    })
  output$summary <- renderUI({ 
    req(input$selectCRM)
    req(length(input$selectCRM)>0)
    if(input$selectCRM=='No results') return('')
    if(v$data$title[1]=='No results') return('')
    if(!is.null(v$abstract)) paste(v$abstract) 
    else { paste(v$data[v$data$name == input$selectCRM, 'summary']) }
    })
  output$date <- renderUI({ 
    req(input$selectCRM)
    req(length(input$selectCRM)>0)
    if(input$selectCRM=='No results') return('')
    if(v$data$title[1]=='No results') return('')
    if(!is.null(v$date)) paste('Publication date:',v$date)
  })
  output$doi <- renderUI({ 
    req(input$selectCRM)
    req(length(input$selectCRM)>0)
    if(input$selectCRM=='No results') return('')
    if(v$data$title[1]=='No results') return('')
    if(!is.null(v$doi)) tagList("DOI:", a(paste0(gsub('Resolve DOI:','',v$doi)), href=gsub('Resolve DOI:','',v$doi), target="_blank"))
  })
  output$table <- DT::renderDataTable({
    req(input$selectCRM)
    req(length(input$selectCRM)>0)
    if(identical(input$selectCRM, character(0))) return(data.frame())
    id_txt = v$data$id[v$data$name == input$selectCRM]
    req(nchar(id_txt)>8)
    id = gsub("urn:uuid:","",v$data$id[v$data$name == input$selectCRM])
    if(identical(id, character(0)) | id=='') return(data.frame())
    if(input$selectCRM=='No results') return(data.frame())
    link = paste0('https://nrc-digital-repository.canada.ca/eng/view/object/?id=',id)
    ddf = html_table(html_nodes(read_html(link),'table'))
    if(length(ddf)>0){
      dd_1 = data.frame(ddf[1])
      v$doi = dd_1[dd_1[,'X1']=='DOI',2]
      v$abstract = dd_1[dd_1[,'X1']=='Abstract',2]
      v$date = dd_1[dd_1[,'X1']=='Publication date',2]
    }
    d = ddf[length(ddf)]
    if(grepl('Analyte',paste(d))){ return(data.frame(d)) }
    else { return(NULL) }
  })
}

#Run the app
shinyApp(ui = ui, server = server)