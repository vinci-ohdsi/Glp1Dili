#### Install Strategus ####
# install.packages("usethis")
# usethis::edit_r_environ() #GITHUB_PAT = 'a1b2c3d4e5f6g7h8g9h0ijklmnopqrstuvwxyz'
# install.packages("remotes")
# remotes::install_github("ohdsi/Strategus")
# remotes::install_github("ohdsi/Characterization")
# remotes::install_github("ohdsi/CohortIncidence")
# remotes::install_github("ohdsi/CohortMethod")
# remotes::install_github("ohdsi/SelfControlledCaseSeries")

library(dplyr)
library(Strategus)
rootFolder <- getwd()

timeAtRisks <- tibble(
  label = c("On treatment", "30-day"),
  riskWindowStart  = c(1, 1),
  startAnchor = c("cohort start", "cohort start"),
  riskWindowEnd  = c(0, 31),
  endAnchor = c("cohort end", "cohort start")
)
psArgs <- tibble(
  label = c("Variable matching", "PS stratification")
)
studyStartDate <- '20171201' #YYYYMMDD
studyEndDate <- '20231231'   #YYYYMMDD
# This is lame but has to be done
studyStartDateWithHyphens <- '2017-12-01' #YYYYMMDD
studyEndDateWithHyphens <- '2023-12-31'   #YYYYMMDD


# Probably don't change below this line ----------------------------------------

useCleanWindowForPriorOutcomeLookback <- TRUE # If FALSE, lookback window is all time prior, i.e., including only first events
priorOutcomeLookback365 <- 365
psMatchMaxRatio <- 99 # If bigger than 1, the outcome model will be conditioned on the matched set
# OneToOnePsMatchMaxRatio <- 1 # If bigger than 1, the outcome model will be conditioned on the matched set

# Don't change below this line (unless you know what you're doing) -------------


# Shared Resources -------------------------------------------------------------
# Get the design assets
cmTcList <- CohortGenerator::readCsv("inst/cmTcList.csv")
sccsTList <- CohortGenerator::readCsv("inst/sccsTList.csv")
sccsIList <- CohortGenerator::readCsv("inst/sccsIList.csv")
oList <- CohortGenerator::readCsv("inst/oList.csv")
ncoList <- CohortGenerator::readCsv("inst/negativeControlOutcomes.csv")
excludedCovariateConcepts <- CohortGenerator::readCsv("inst/excludedCovariateConcepts.csv")

# Get the list of cohorts
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server"
)

# OPTIONAL: Create a subset to define the new user cohorts
# More information: https://ohdsi.github.io/CohortGenerator/articles/CreatingCohortSubsetDefinitions.html
# subset1 <- CohortGenerator::createCohortSubsetDefinition(
#   name = "New Users",
#   definitionId = 1,
#   subsetOperators = list(
#     CohortGenerator::createLimitSubset(
#       priorTime = 365,
#       limitTo = "firstEver"
#     )
#   )
# )
# 
# subsetTargetCohortIds <- unique(c(cmTcList$targetCohortId, cmTcList$comparatorCohortId))
# cohortDefinitionSet <- cohortDefinitionSet |>
#   CohortGenerator::addCohortSubsetDefinition(subset1, targetCohortIds = subsetTargetCohortIds)

negativeControlOutcomeCohortSet <- ncoList %>%
  rename(cohortName = "conceptname",
         outcomeConceptId = "conceptid") %>%
  mutate(cohortId = row_number() + 1000,
         outcomeConceptId = trimws(outcomeConceptId))

if (any(duplicated(cohortDefinitionSet$cohortId, negativeControlOutcomeCohortSet$cohortId))) {
  stop("*** Error: duplicate cohort IDs found ***")
}

# CohortGeneratorModule --------------------------------------------------------
cgModuleSettingsCreator <- CohortGeneratorModule$new()
cohortDefinitionShared <- cgModuleSettingsCreator$createCohortSharedResourceSpecifications(cohortDefinitionSet)
negativeControlsShared <- cgModuleSettingsCreator$createNegativeControlOutcomeCohortSharedResourceSpecifications(
  negativeControlOutcomeCohortSet = negativeControlOutcomeCohortSet,
  occurrenceType = "first",
  detectOnDescendants = TRUE
)
cohortGeneratorModuleSpecifications <- cgModuleSettingsCreator$createModuleSpecifications(
  # incremental = TRUE,
  generateStats = TRUE
)

# CharacterizationModule Settings ---------------------------------------------
cModuleSettingsCreator <- CharacterizationModule$new()
characterizationModuleSpecifications <- cModuleSettingsCreator$createModuleSpecifications(
  targetIds = cohortDefinitionSet$cohortId, # NOTE: This is all T/C/I/O
  outcomeIds = oList$outcomeCohortId,
  outcomeWashoutDays = rep(365, length(oList$outcomeCohortId)), #length of washout days should be identical to the outcomeIds
  dechallengeStopInterval = 30,
  dechallengeEvaluationWindow = 30,
  # timeAtRisk = timeAtRisks,
  minPriorObservation = 365,
  covariateSettings = FeatureExtraction::createDefaultCovariateSettings()
)


# CohortIncidenceModule --------------------------------------------------------
ciModuleSettingsCreator <- CohortIncidenceModule$new()
tciIds <- cohortDefinitionSet %>%
  filter(!cohortId %in% oList$outcomeCohortId) %>%
  filter(!cohortId %in% sccsTList$targetCohortId) %>%
  pull(cohortId)
targetList <- lapply(
  tciIds,
  function(cohortId) {
    CohortIncidence::createCohortRef(
      id = cohortId, 
      name = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == cohortId]
    )
  }
)
outcomeList <- lapply(
  seq_len(nrow(oList)),
  function(i) {
    CohortIncidence::createOutcomeDef(
      id = i, 
      name = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == oList$outcomeCohortId[i]], 
      cohortId = oList$outcomeCohortId[i], 
      cleanWindow = oList$cleanWindow[i]
    )
  }
)
tars <- list()
for (i in seq_len(nrow(timeAtRisks))) {
  tars[[i]] <- CohortIncidence::createTimeAtRiskDef(
    id = i, 
    startWith = gsub("cohort ", "", timeAtRisks$startAnchor[i]), 
    endWith = gsub("cohort ", "", timeAtRisks$endAnchor[i]), 
    startOffset = timeAtRisks$riskWindowStart[i],
    endOffset = timeAtRisks$riskWindowEnd[i]
  )
}
analysis1 <- CohortIncidence::createIncidenceAnalysis(
  targets = tciIds,
  outcomes = seq_len(nrow(oList)),
  tars = seq_along(tars)
)
irStudyWindow <- CohortIncidence::createDateRange(
  startDate = studyStartDateWithHyphens,
  endDate = studyEndDateWithHyphens
)
# NOTE: Do we want 10 year age breaks?
irDesign <- CohortIncidence::createIncidenceDesign(
  targetDefs = targetList,
  outcomeDefs = outcomeList,
  tars = tars,
  analysisList = list(analysis1),
  studyWindow = irStudyWindow,
  strataSettings = CohortIncidence::createStrataSettings(
    byYear = TRUE,
    byGender = TRUE,
    byAge = TRUE,
    ageBreaks = seq(0, 110, by = 10)
  )
)
cohortIncidenceModuleSpecifications <- ciModuleSettingsCreator$createModuleSpecifications(
  irDesign = irDesign$toList()
)


# CohortMethodModule -----------------------------------------------------------
cmModuleSettingsCreator <- CohortMethodModule$new()
covariateSettings <- FeatureExtraction::createDefaultCovariateSettings(
  addDescendantsToExclude = TRUE # Keep TRUE because you're excluding concepts
)
outcomeList <- append(
  lapply(seq_len(nrow(oList)), function(i) {
    if (useCleanWindowForPriorOutcomeLookback)
      priorOutcomeLookback <- oList$cleanWindow[i]
    else
      priorOutcomeLookback <- 99999
    CohortMethod::createOutcome(
      outcomeId = oList$outcomeCohortId[i],
      outcomeOfInterest = TRUE,
      trueEffectSize = NA,
      priorOutcomeLookback = priorOutcomeLookback365
    )
  }),
  lapply(negativeControlOutcomeCohortSet$cohortId, function(i) {
    CohortMethod::createOutcome(
      outcomeId = i,
      outcomeOfInterest = FALSE,
      trueEffectSize = 1
    )
  })
)
targetComparatorOutcomesList <- list()
for (i in seq_len(nrow(cmTcList))) {
  targetComparatorOutcomesList[[i]] <- CohortMethod::createTargetComparatorOutcomes(
    targetId = cmTcList$targetCohortId[i],
    comparatorId = cmTcList$comparatorCohortId[i],
    outcomes = outcomeList,
    excludedCovariateConceptIds = c(
      excludedCovariateConcepts$conceptId
    )
  )
}
getDbCohortMethodDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(
  restrictToCommonPeriod = TRUE,
  studyStartDate = studyStartDate,
  studyEndDate = studyEndDate,
  maxCohortSize = 0,
  covariateSettings = covariateSettings
)
createPsArgs = CohortMethod::createCreatePsArgs(
  maxCohortSizeForFitting = 250000,
  errorOnHighCorrelation = TRUE,
  stopOnError = FALSE, # Setting to FALSE to allow Strategus complete all CM operations; when we cannot fit a model, the equipoise diagnostic should fail
  estimator = "att",
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    exclude = c(0), 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    noiseLevel = "silent", 
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE, 
    tolerance = 2e-07, 
    cvRepetitions = 1, 
    startingVariance = 0.01
  )
)
matchOnPsArgs = CohortMethod::createMatchOnPsArgs(
  maxRatio = psMatchMaxRatio,
  caliper = 0.2,
  caliperScale = "standardized logit",
  allowReverseMatch = FALSE,
  stratificationColumns = c()
)
stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(
  numberOfStrata = 5,
  stratificationColumns = c(),
  baseSelection = "all"
)
computeSharedCovariateBalanceArgs = CohortMethod::createComputeCovariateBalanceArgs(
  maxCohortSize = 250000,
  covariateFilter = NULL
)
computeCovariateBalanceArgs = CohortMethod::createComputeCovariateBalanceArgs(
  maxCohortSize = 250000,
  covariateFilter = FeatureExtraction::getDefaultTable1Specifications()
)

fitOutcomeModelArgsMatch <- CohortMethod::createFitOutcomeModelArgs(
  modelType = "cox",
  stratified = psMatchMaxRatio != 1,
  useCovariates = FALSE,
  inversePtWeighting = FALSE,
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE,
    startingVariance = 0.01, 
    tolerance = 2e-07, 
    cvRepetitions = 1, 
    noiseLevel = "quiet"
  )
)

fitOutcomeModelArgsStrat <- CohortMethod::createFitOutcomeModelArgs(
  modelType = "cox",
  stratified = TRUE,
  useCovariates = FALSE,
  inversePtWeighting = FALSE,
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE,
    startingVariance = 0.01, 
    tolerance = 2e-07, 
    cvRepetitions = 1, 
    noiseLevel = "quiet"
  )
)

# fitOutcomeModelArgs = CohortMethod::createFitOutcomeModelArgs(
#   modelType = "cox",
#   stratified = psMatchMaxRatio != 1,
#   useCovariates = FALSE,
#   inversePtWeighting = FALSE,
#   prior = Cyclops::createPrior(
#     priorType = "laplace", 
#     useCrossValidation = TRUE
#   ),
#   control = Cyclops::createControl(
#     cvType = "auto", 
#     seed = 1, 
#     resetCoefficients = TRUE,
#     startingVariance = 0.01, 
#     tolerance = 2e-07, 
#     cvRepetitions = 1, 
#     noiseLevel = "quiet"
#   )
# )
cmAnalysisList <- list()
for (i in seq_len(nrow(timeAtRisks)*nrow(psArgs))) {
  if (i%%2) {k <- 1} else{ k <- 2}#i%%2 should be revised
  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(
    firstExposureOnly = FALSE,
    washoutPeriod = 0,
    removeDuplicateSubjects = "keep first",
    censorAtNewRiskWindow = TRUE,
    removeSubjectsWithPriorOutcome = TRUE,
    priorOutcomeLookback = priorOutcomeLookback365,
    riskWindowStart = timeAtRisks$riskWindowStart[[k]], #i%%2 should be revised
    startAnchor = timeAtRisks$startAnchor[[k]], #i%%2 should be revised
    riskWindowEnd = timeAtRisks$riskWindowEnd[[k]], #i%%2 should be revised
    endAnchor = timeAtRisks$endAnchor[[k]], #i%%2 should be revised
    minDaysAtRisk = 1,
    maxDaysAtRisk = 99999
  )
  #The code should be revised. 
  if(i%%2==1){
    cmAnalysisList[[i]] <- CohortMethod::createCmAnalysis(
      analysisId = i,
      description = sprintf(
        "Cohort method, %s, %s",
        timeAtRisks$label[i],
        "Varaible-ratio matching"
      ),
      getDbCohortMethodDataArgs = getDbCohortMethodDataArgs,
      createStudyPopArgs = createStudyPopArgs,
      createPsArgs = createPsArgs,
      matchOnPsArgs = matchOnPsArgs,
      # stratifyByPsArgs = stratifyByPsArgs,
      computeSharedCovariateBalanceArgs = computeSharedCovariateBalanceArgs,
      computeCovariateBalanceArgs = computeCovariateBalanceArgs,
      fitOutcomeModelArgs = fitOutcomeModelArgsMatch
    )
  }else{
    cmAnalysisList[[i]] <- CohortMethod::createCmAnalysis(
      analysisId = i,
      description = sprintf(
        "Cohort method, %s, %s",
        timeAtRisks$label[i],
        "Stratification"
      ),
      getDbCohortMethodDataArgs = getDbCohortMethodDataArgs,
      createStudyPopArgs = createStudyPopArgs,
      createPsArgs = createPsArgs,
      # matchOnPsArgs = matchOnPsArgs,
      stratifyByPsArgs = stratifyByPsArgs,
      computeSharedCovariateBalanceArgs = computeSharedCovariateBalanceArgs,
      computeCovariateBalanceArgs = computeCovariateBalanceArgs,
      fitOutcomeModelArgs = fitOutcomeModelArgsStrat
    )
  }
}
cohortMethodModuleSpecifications <- cmModuleSettingsCreator$createModuleSpecifications(
  cmAnalysisList = cmAnalysisList,
  targetComparatorOutcomesList = targetComparatorOutcomesList,
  analysesToExclude = NULL,
  refitPsForEveryOutcome = FALSE,
  refitPsForEveryStudyPopulation = FALSE,  
  cmDiagnosticThresholds = CohortMethod::createCmDiagnosticThresholds(
    mdrrThreshold = Inf,
    easeThreshold = 0.25,
    sdmThreshold = 0.1,
    equipoiseThreshold = 0.25, #changed from 0.2 to 0.25
    generalizabilitySdmThreshold = 1 # NOTE using default here
  )
)


# SelfControlledCaseSeriesmodule -----------------------------------------------
sccsModuleSettingsCreator <- SelfControlledCaseSeriesModule$new()
uniqueTargetIds <- sccsTList$targetCohortId

eoList <- list()
for (targetId in uniqueTargetIds) {
  for (outcomeId in oList$outcomeCohortId) {
    eoList[[length(eoList) + 1]] <- SelfControlledCaseSeries::createExposuresOutcome(
      outcomeId = outcomeId,
      exposures = list(
        SelfControlledCaseSeries::createExposure(
          exposureId = targetId,
          trueEffectSize = NA
        )
      )
    )
  }
  for (outcomeId in negativeControlOutcomeCohortSet$cohortId) {
    eoList[[length(eoList) + 1]] <- SelfControlledCaseSeries::createExposuresOutcome(
      outcomeId = outcomeId,
      exposures = list(SelfControlledCaseSeries::createExposure(
        exposureId = targetId, 
        trueEffectSize = 1
      ))
    )
  }
}
sccsAnalysisList <- list()
analysisToInclude <- data.frame()
for (i in seq_len(nrow(sccsIList))) {
  indicationId <- sccsIList$indicationCohortId[i]
  getDbSccsDataArgs <- SelfControlledCaseSeries::createGetDbSccsDataArgs(
    maxCasesPerOutcome = 1000000,
    useNestingCohort = TRUE,
    nestingCohortId = indicationId,
    studyStartDate = studyStartDate,
    studyEndDate = studyEndDate,
    deleteCovariatesSmallCount = 0
  )
  createStudyPopulationArgs = SelfControlledCaseSeries::createCreateStudyPopulationArgs(
    firstOutcomeOnly = TRUE,
    naivePeriod = 365,
    minAge = 18,
    genderConceptIds = c(8507, 8532)
  )
  covarPreExp <- SelfControlledCaseSeries::createEraCovariateSettings(
    label = "Pre-exposure",
    includeEraIds = "exposureId",
    start = -30,
    startAnchor = "era start",
    end = -1,
    endAnchor = "era start",
    firstOccurrenceOnly = FALSE,
    allowRegularization = FALSE,
    profileLikelihood = FALSE,
    exposureOfInterest = FALSE
  )
  calendarTimeSettings <- SelfControlledCaseSeries::createCalendarTimeCovariateSettings(
    calendarTimeKnots = 5,
    allowRegularization = TRUE,
    computeConfidenceIntervals = FALSE
  )
  # seasonalitySettings <- SelfControlledCaseSeries:createSeasonalityCovariateSettings(
  #   seasonKnots = 5,
  #   allowRegularization = TRUE,
  #   computeConfidenceIntervals = FALSE
  # )
  fitSccsModelArgs <- SelfControlledCaseSeries::createFitSccsModelArgs(
    prior = Cyclops::createPrior("laplace", useCrossValidation = TRUE), 
    control = Cyclops::createControl(
      cvType = "auto", 
      selectorType = "byPid", 
      startingVariance = 0.1, 
      seed = 1, 
      resetCoefficients = TRUE, 
      noiseLevel = "quiet")
  )
  for (j in seq_len(nrow(timeAtRisks))) {
    covarExposureOfInt <- SelfControlledCaseSeries::createEraCovariateSettings(
      label = "Main",
      includeEraIds = "exposureId",
      start = timeAtRisks$riskWindowStart[j],
      startAnchor = gsub("cohort", "era", timeAtRisks$startAnchor[j]),
      end = timeAtRisks$riskWindowEnd[j],
      endAnchor = gsub("cohort", "era", timeAtRisks$endAnchor[j]),
      firstOccurrenceOnly = FALSE,
      allowRegularization = FALSE,
      profileLikelihood = TRUE,
      exposureOfInterest = TRUE
    )
    createSccsIntervalDataArgs <- SelfControlledCaseSeries::createCreateSccsIntervalDataArgs(
      eraCovariateSettings = list(covarPreExp, covarExposureOfInt),
      # seasonalityCovariateSettings = seasonalityCovariateSettings,
      calendarTimeCovariateSettings = calendarTimeSettings
    )
    description <- "SCCS"
    description <- sprintf("%s, having %s - male, female, age >= %s", description, cohortDefinitionSet %>% 
                             filter(cohortId == indicationId) %>%
                             pull(cohortName), createStudyPopulationArgs$minAge)
    description <- sprintf("%s, %s", description, timeAtRisks$label[j])
    sccsAnalysisList[[length(sccsAnalysisList) + 1]] <- SelfControlledCaseSeries::createSccsAnalysis(
      analysisId = length(sccsAnalysisList) + 1,
      description = description,
      getDbSccsDataArgs = getDbSccsDataArgs,
      createStudyPopulationArgs = createStudyPopulationArgs,
      createIntervalDataArgs = createSccsIntervalDataArgs,
      fitSccsModelArgs = fitSccsModelArgs
    )
  }
}
selfControlledModuleSpecifications <- sccsModuleSettingsCreator$createModuleSpecifications(
  sccsAnalysisList = sccsAnalysisList,
  exposuresOutcomeList = eoList,
  combineDataFetchAcrossOutcomes = FALSE,
  sccsDiagnosticThresholds = SelfControlledCaseSeries::createSccsDiagnosticThresholds(
    mdrrThreshold = Inf,
    easeThreshold = 0.25,
    timeTrendPThreshold = 0.05,
    preExposurePThreshold = 0.05
  )
)

# Combine across modules -------------------------------------------------------
analysisSpecifications <- Strategus::createEmptyAnalysisSpecificiations() |>
  Strategus::addSharedResources(cohortDefinitionShared) |> 
  Strategus::addSharedResources(negativeControlsShared) |>
  Strategus::addModuleSpecifications(cohortGeneratorModuleSpecifications) |>
  Strategus::addModuleSpecifications(characterizationModuleSpecifications) %>%
  Strategus::addModuleSpecifications(cohortIncidenceModuleSpecifications) %>%
  Strategus::addModuleSpecifications(cohortMethodModuleSpecifications) %>%
  Strategus::addModuleSpecifications(selfControlledModuleSpecifications)

if (!dir.exists(rootFolder)) {
  dir.create(rootFolder, recursive = TRUE)
}
ParallelLogger::saveSettingsToJson(analysisSpecifications, file.path(rootFolder, "inst/fullStudyAnalysisSpecification.json"))