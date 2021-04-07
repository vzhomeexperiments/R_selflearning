# 20210324 Task Scheduling Automation from R
# https://cran.r-project.org/web/packages/taskscheduleR/readme/README.html
#
# =====================================
# Script to deploy lazytrading tasks automatically
library(taskscheduleR)
library(secret)
# =====================================
# Common setup & secure password management
# =====================================
path_user <- normalizePath(Sys.getenv('PATH_DSS_Repo'), winslash = '/')
who_user <-  normalizePath(Sys.getenv('USERPROFILE'), winslash = '/')
# create your private/public keys (e.g. in R Studio)
path_keys <- file.path(who_user, ".ssh")
# secret::create_vault(file.path(who_user, "vault"))
# secret::add_user(email = "vlad",
#                  public_key = file.path(path_keys, 'id_rsa.pub'),
#                  vault = file.path(who_user, "vault"))
# secret::add_secret("pwrd", "", "vlad",
#                     vault = file.path(who_user, "vault"))
# secret::add_secret("user", "", "vlad",
#                     vault = file.path(who_user, "vault"))
password <- secret::get_secret("pwrd",
                               key = file.path(path_keys, 'id_rsa'),
                               vault = file.path(who_user, "vault"))
usr <- secret::get_secret("user",
                          key = file.path(path_keys, 'id_rsa'),
                          vault = file.path(who_user, "vault"))
## don't like to bother with security?
# usr <- ""
# password <- ""
extra_parameters <- paste0("/RU ", usr, " ", "/RP ",password)
# =====================================
# Task: automate script collect data
# =====================================
script_name <- '04_CollectDataM60.R'
path_script <- file.path(path_user, "R_selflearning", "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_collect")

## Setup task
taskscheduler_create(taskname = "dss_aml_collect", rscript = path_script,
                     schedule = "DAILY",
                     starttime = "00:01",
                     days = c("MON", "TUE", "WED", "THU", "FRI"),
                     schtasks_extra = extra_parameters)

# =====================================
# Task: automate script force model build
# =====================================
script_name <- '05_ForceModelUpdateM60.R'
path_script <- file.path(path_user, "R_selflearning", "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_new_build")

## Setup task
taskscheduler_create(taskname = "dss_aml_new_build", rscript = path_script,
                     schedule = "ONCE",
                     starttime = format(Sys.time() + 62, "%H:%M"),
                     schtasks_extra = extra_parameters)

# =====================================
# Task: automate script ai model build test
# =====================================
script_name <- '06_TestBuildTestModelM60.R'
path_script <- file.path(path_user, "R_selflearning", "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_test_build")

## Setup task
taskscheduler_create(taskname = "dss_aml_test_build", rscript = path_script,
                     schedule = "WEEKLY",
                     starttime = "01:01",
                     days = "SAT",
                     schtasks_extra = extra_parameters)

# =====================================
# Task: automate script ai SCR_AML_Score
# =====================================
script_name <- '07_ScoreDataM60.R'
path_script <- file.path(path_user, "R_selflearning", "_PROD", script_name)

## Delete task
taskscheduler_delete("dss_aml_score")

## Setup task
taskscheduler_create(taskname = "dss_aml_score", rscript = path_script,
                     schedule = "HOURLY",
                     starttime = "00:10",
                     days = c("MON", "TUE", "WED", "THU", "FRI"),
                     schtasks_extra = extra_parameters)

# =====================================
# Delete all tasks
# =====================================
taskscheduler_delete("dss_aml_collect")
taskscheduler_delete("dss_aml_new_build")
taskscheduler_delete("dss_aml_test_build")
taskscheduler_delete("dss_aml_score")
# =====================================
# All tasks
# =====================================
all <- taskscheduler_ls()

