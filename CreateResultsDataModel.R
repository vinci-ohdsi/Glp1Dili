################################################################################
# INSTRUCTIONS: The code below assumes you have access to a PostgreSQL database
# and permissions to create tables in an existing schema specified by the
# resultsDatabaseSchema parameter.
# 
# See the Working with results section
# of the UsingThisTemplate.md for more details.
# 
# More information about working with results produced by running Glp1Dili 
# is found at:
# https://ohdsi.github.io/Glp1Dili/articles/WorkingWithResults.html
# ##############################################################################

# Code for creating the result schema and tables in a PostgreSQL database
resultsDatabaseSchema <- "results"
analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
  fileName = "inst/sampleStudy/sampleStudyAnalysisSpecification.json"
)

resultsDatabaseConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = Sys.getenv("OHDSI_RESULTS_DATABASE_SERVER"),
  user = Sys.getenv("OHDSI_RESULTS_DATABASE_USER"),
  password = Sys.getenv("OHDSI_RESULTS_DATABASE_PASSWORD")
)

# Create results data model -------------------------

# Use the 1st results folder to define the results data model
resultsFolder <- list.dirs(path = "results", full.names = T, recursive = F)[1]
resultsDataModelSettings <- Glp1Dili::createResultsDataModelSettings(
  resultsDatabaseSchema = resultsDatabaseSchema,
  resultsFolder = file.path(resultsFolder, "strategusOutput")
)

Glp1Dili::createResultDataModel(
  analysisSpecifications = analysisSpecifications,
  resultsDataModelSettings = resultsDataModelSettings,
  resultsConnectionDetails = resultsDatabaseConnectionDetails
)
