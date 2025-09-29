# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(here)
# library(tarchetypes) # Load other packages as needed.

# Set target options:
tar_option_set(
  packages = c("scales", "tidymodels", "tidyverse") # Packages that your targets need for their tasks.
  # format = "qs", # Optionally set the default storage format. qs is fast.
  #
  # Pipelines that take a long time to run may benefit from
  # optional distributed computing. To use this capability
  # in tar_make(), supply a {crew} controller
  # as discussed at https://books.ropensci.org/targets/crew.html.
  # Choose a controller that suits your needs. For example, the following
  # sets a controller that scales up to a maximum of two workers
  # which run as local R processes. Each worker launches when there is work
  # to do and exits if 60 seconds pass with no tasks to run.
  #
  #   controller = crew::crew_controller_local(workers = 2, seconds_idle = 60)
  #
  # Alternatively, if you want workers to run on a high-performance computing
  # cluster, select a controller from the {crew.cluster} package.
  # For the cloud, see plugin packages like {crew.aws.batch}.
  # The following example is a controller for Sun Grid Engine (SGE).
  #
  #   controller = crew.cluster::crew_controller_sge(
  #     # Number of workers that the pipeline can scale up to:
  #     workers = 10,
  #     # It is recommended to set an idle time so workers can shut themselves
  #     # down if they are not running tasks.
  #     seconds_idle = 120,
  #     # Many clusters install R as an environment module, and you can load it
  #     # with the script_lines argument. To select a specific verison of R,
  #     # you may need to include a version string, e.g. "module load R/4.3.2".
  #     # Check with your system administrator if you are unsure.
  #     script_lines = "module load R"
  #   )
  #
  # Set other options as needed.
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
# Define the pipeline
list(
  # Target 1: Track the input data file.
  # tar_file() tells targets to monitor this file for changes.
  tar_file(
    raw_data_file,
    here("data", "2025-08-MD.csv")
  ),

  # Target 2: Clean the raw data.
  # This target depends on raw_data_file. It will only rerun if the file changes.
  tar_target(
    cleaned_long_data,
    clean_data(raw_data_file)
  ),

  # Target 3: Pivot the data to wide format.
  # This depends on the long-format cleaned data.
  tar_target(
    cleaned_wide_data,
    pivot_cleaned_data_wide(cleaned_long_data)
  ),

  # Target 4: Fit the PCA model.
  # This depends on the wide data.
  tar_target(
    fitted_pca_model,
    fit_model_pca(cleaned_wide_data)
  ),

  # Target 5: Create the variance chart object.
  # This depends on the fitted PCA model.
  tar_target(
    variance_chart,
    make_chart_variance_pcs(fitted_pca_model)
  ),

  # Target 6: Save the variance chart to a file (optional)
  tar_file(
    variance_chart_file,
    save_chart(variance_chart, here("outputs", "variance_chart.png"))
  )
)
