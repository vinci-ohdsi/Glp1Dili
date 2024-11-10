################################################################################
# INSTRUCTIONS: This script assumes you have cohorts you would like to use in an
# ATLAS instance. Please note you will need to update the baseUrl to match
# the settings for your enviroment. You will also want to change the 
# CohortGenerator::saveCohortDefinitionSet() function call arguments to identify
# a folder to store your cohorts. This code will store the cohorts in 
# "inst/sampleStudy" as part of the template for reference. You should store
# your settings in the root of the "inst" folder and consider removing the 
# "inst/sampleStudy" resources when you are ready to release your study.
# 
# See the Download cohorts section
# of the UsingThisTemplate.md for more details.
# ##############################################################################

# remotes::install_github("OHDSI/ROhdsiWebApi")
library(dplyr)
# baseUrl <- "https://atlas-demo.ohdsi.org/WebAPI"
baseUrl <- Sys.getenv("Glp1DiliAtlas")
# Use this if your WebAPI instance has security enables
# ROhdsiWebApi::authorizeWebApi(
#   baseUrl = baseUrl,
#   authMethod = "windows"
# )
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl = baseUrl,
  cohortIds = c(
    467, # GLP1R user (vs DPP4i)
    468, # DPP4 user (vs GLP1Ra)
    475, # GLP1R user (vs SGLT2i)
    477, # SGLT2i user (vs GLR1Ra)
    469, # All events of Acute Liver Injury, NO viral hepatitis or alcoholic hepatic failure
    470, # Newly developed abnormal liver test 
    471, #GLP1R exposure
    472, #DPP4i exposure
    479, #SGLT2i exposure
    473 #indication (type 2 DM)
  ),
  generateStats = TRUE
)

# Rename cohorts
cohortDefinitionSet[cohortDefinitionSet$cohortId == 467,]$cohortName <- "GLP1R user (vs DPP4i)"
cohortDefinitionSet[cohortDefinitionSet$cohortId == 468,]$cohortName <- "DPP4 user (vs GLP1Ra)"
cohortDefinitionSet[cohortDefinitionSet$cohortId == 475,]$cohortName <- "GLP1R user (vs SGLT2i)"
cohortDefinitionSet[cohortDefinitionSet$cohortId == 477,]$cohortName <- "SGLT2i user (vs GLR1Ra)"

#### Re-number cohorts####
# GLP1Ra vs DPP4i
cohortDefinitionSet[cohortDefinitionSet$cohortId == 467,]$cohortId <- 11
cohortDefinitionSet[cohortDefinitionSet$cohortId == 468,]$cohortId <- 12

# GLP1Ra vs DPP4i
cohortDefinitionSet[cohortDefinitionSet$cohortId == 475,]$cohortId <- 21
cohortDefinitionSet[cohortDefinitionSet$cohortId == 477,]$cohortId <- 22

cohortDefinitionSet[cohortDefinitionSet$cohortId == 469,]$cohortId <- 101
cohortDefinitionSet[cohortDefinitionSet$cohortId == 470,]$cohortId <- 102

cohortDefinitionSet[cohortDefinitionSet$cohortId == 471,]$cohortId <- 201
cohortDefinitionSet[cohortDefinitionSet$cohortId == 472,]$cohortId <- 202
cohortDefinitionSet[cohortDefinitionSet$cohortId == 473,]$cohortId <- 301

# Save the cohort definition set
# NOTE: Update settingsFileName, jsonFolder and sqlFolder
# for your study.
CohortGenerator::saveCohortDefinitionSet(
  cohortDefinitionSet = cohortDefinitionSet,
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server",
)

# Download and save the covariates to exclude
covariatesToExcludeConceptSet <- ROhdsiWebApi::getConceptSetDefinition(
  conceptSetId = 436,
  baseUrl = baseUrl
) %>%
  ROhdsiWebApi::resolveConceptSet(
    baseUrl = baseUrl
  ) %>%
  ROhdsiWebApi::getConcepts(
    baseUrl = baseUrl
  ) # %>%
#   rename(outcomeConceptId = "conceptId",
#          cohortName = "conceptName") %>%
#   mutate(cohortId = row_number() + 100) %>%
#   select(cohortId, cohortName, outcomeConceptId)

# NOTE: Update file location for your study.
CohortGenerator::writeCsv(
  x = covariatesToExcludeConceptSet,
  file = "inst/excludedCovariateConcepts.csv",
  warnOnFileNameCaseMismatch = F
)

# Download and save the negative control outcomes
negativeControlOutcomeCohortSet <- ROhdsiWebApi::getConceptSetDefinition(
  conceptSetId = 437,
  baseUrl = baseUrl
) %>%
  ROhdsiWebApi::resolveConceptSet(
    baseUrl = baseUrl
  ) %>%
  ROhdsiWebApi::getConcepts(
    baseUrl = baseUrl
  ) %>%
  rename(outcomeConceptId = "conceptId",
         cohortName = "conceptName") %>%
  mutate(cohortId = row_number() + 10000) %>%
  select(cohortId, cohortName, outcomeConceptId)

# NOTE: Update file location for your study.
CohortGenerator::writeCsv(
  x = negativeControlOutcomeCohortSet,
  file = "inst/negativeControlOutcomes.csv",
  warnOnFileNameCaseMismatch = F
)
