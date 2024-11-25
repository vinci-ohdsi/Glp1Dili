# Settings ---------------------------------------------------------------------
# Use the connnection  details to connect to either the Postgres or SQLite database:
# resultsDatabaseConnectionDetails <- DatabaseConnector::createConnectionDetails(
#   dbms = "sqlite",
#   server = "/Users/msuchard/Dropbox/RSqlLite/Results.sqlite"
# )
resultsDatabaseSchema <- "main"
# Need at least one results folder to know what table structure to create. 
# resultsFolder should at least contain a 'strategusOutput' subfolder:
resultsFolder <- list.dirs(path = "/Users/msuchard/Dropbox/Projects/Glp1Dili/results", full.names = T, recursive = F)[1]

resultsDatabaseConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = "localhost/msuchard",
  user = "msuchard",
  password = ""
)

conn <- DatabaseConnector::connect(resultsDatabaseConnectionDetails)
sql <- paste0("CREATE SCHEMA ", resultsDatabaseSchema, ";")
DatabaseConnector::executeSql(conn, sql)
DatabaseConnector::disconnect(conn)

# Don't make changes below this line -------------------------------------------
analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
  fileName = "inst/fullStudyAnalysisSpecification.json"
)
resultsDataModelSettings <- Strategus::createResultsDataModelSettings(
  resultsDatabaseSchema = resultsDatabaseSchema,
  resultsFolder = file.path(resultsFolder, "strategusOutput")
)
Strategus::createResultDataModel(
  analysisSpecifications = analysisSpecifications,
  resultsDataModelSettings = resultsDataModelSettings,
  resultsConnectionDetails = resultsDatabaseConnectionDetails
)
