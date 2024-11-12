# -------------------------------------------------------
#                     PLEASE READ
# -------------------------------------------------------
#
# You must call "renv::restore()" and follow the prompts
# to install all of the necessary R libraries to run this
# project. This is a one-time operation that you must do
# before running any code.
#
# !!! PLEASE RESTART R AFTER RUNNING renv::restore() !!!
#
# -------------------------------------------------------
#renv::restore()

# ENVIRONMENT SETTINGS NEEDED FOR RUNNING Glp1Dili ------------
Sys.setenv("_JAVA_OPTIONS"="-Xmx4g") # Sets the Java maximum heap space to 4GB
Sys.setenv("VROOM_THREADS"=1) # Sets the number of threads to 1 to avoid deadlocks on file system
# Sys.setenv(JAVA_HOME=)
Sys.setenv(DATABASECONNECTOR_JAR_FOLDER="C:/Db")

databaseName <- "VA-OMOP"
workDatabaseSchema <- 'VINCI_OMOP.scratch.msuchard'
cdmDatabaseSchema <- 'CDW_OMOP.OMOPV5'
outputLocation <- 'D:/OHDSI/MAS/output'
minCellCount <- 10
cohortTableName <- "glp1_dili"

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "sql server",
  server = "vhacdwdwhdbs102"
)

##=========== END OF INPUTS ==========
analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
  fileName = "inst/fullStudyAnalysisSpecification.json"
)

executionSettings <- Strategus::createCdmExecutionSettings(
  workDatabaseSchema = workDatabaseSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTableName),
  workFolder = file.path(outputLocation, databaseName, "strategusWork"),
  resultsFolder = file.path(outputLocation, databaseName, "strategusOutput"),
  minCellCount = minCellCount
)

if (!dir.exists(file.path(outputLocation, databaseName))) {
  dir.create(file.path(outputLocation, databaseName), recursive = T)
}
ParallelLogger::saveSettingsToJson(
  object = executionSettings,
  fileName = file.path(outputLocation, databaseName, "executionSettings.json")
)

## VA SPECIFIC CODE START ---------
library(Strategus)

CohortGeneratorModule$set(
  "public", "execute", 
  function(connectionDetails, analysisSpecifications, executionSettings) {
    super$.validateCdmExecutionSettings(executionSettings)
    super$execute(connectionDetails, analysisSpecifications, executionSettings)
    
    jobContext <- private$jobContext
    cohortDefinitionSet <- super$.createCohortDefinitionSetFromJobContext()
    
    message("Running VA-specific refactoring")
    if (TRUE) {
      for (i in 1:nrow(cohortDefinitionSet)) {
        newSql <- VaTools::translateToCustomVaSqlText(cohortDefinitionSet$sql[i], NULL)         
        cohortDefinitionSet$sql[i] <- newSql
      }
    }    
    
    negativeControlOutcomeSettings <- private$.createNegativeControlOutcomeSettingsFromJobContext()
    resultsFolder <- jobContext$moduleExecutionSettings$resultsSubFolder
    if (!dir.exists(resultsFolder)) {
      dir.create(resultsFolder, recursive = TRUE)
    }
    
    CohortGenerator::runCohortGeneration(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = jobContext$moduleExecutionSettings$cdmDatabaseSchema,
      cohortDatabaseSchema = jobContext$moduleExecutionSettings$workDatabaseSchema,
      cohortTableNames = jobContext$moduleExecutionSettings$cohortTableNames,
      cohortDefinitionSet = cohortDefinitionSet,
      negativeControlOutcomeCohortSet = negativeControlOutcomeSettings$cohortSet,
      occurrenceType = negativeControlOutcomeSettings$occurrenceType,
      detectOnDescendants = negativeControlOutcomeSettings$detectOnDescendants,
      outputFolder = resultsFolder,
      databaseId = jobContext$moduleExecutionSettings$cdmDatabaseMetaData$databaseId,
      minCellCount = jobContext$moduleExecutionSettings$minCellCount,
      incremental = jobContext$moduleExecutionSettings$incremental,
      incrementalFolder = jobContext$moduleExecutionSettings$workSubFolder
    )
    
    private$.message(paste("Results available at:", resultsFolder))
  },
  overwrite = TRUE
)

# Stand-alone execution the CG Module             
cgModule <- CohortGeneratorModule$new()
cgModule$execute(
  connectionDetails = connectionDetails,
  analysisSpecifications = analysisSpecifications,
  executionSettings = executionSettings
)

# Remove CG module from the analysis specification
analysisSpecifications$moduleSpecifications <- analysisSpecifications$moduleSpecifications[2:5]

# Note that given the redefinition of `CohortGeneratorModule` there is no need to
# separate out its execution as is done above.

## VA SPECIFIC CODE END ---------

Strategus::execute(
  analysisSpecifications = analysisSpecifications,
  executionSettings = executionSettings,
  connectionDetails = connectionDetails
)
