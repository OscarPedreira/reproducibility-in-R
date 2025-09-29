library(tidymodels)
library(tidyverse)

path_data_raw <- "data/data_raw/"
path_data_processed <- "data/data_processed/"

clean_data <- function(file) {
  data <- read_csv(
    file.path(path_data_raw, "2025-08-MD.csv"),
    name_repair = "universal"
  )

  transformation_dict <- bind_rows(
    data |>
      slice_head(n = 1) |>
      pivot_longer(!sasdate) |>
      transmute(
        series = name,
        transformation = value
      )
  )

  data_cleaned <- data |>
    slice(-1) |>
    transmute(
      Date = dmy(sasdate),
      across(-c(Date, sasdate), as.numeric)
    ) |>
    pivot_longer(-Date, names_to = "series", values_to = "value") |>
    left_join(transformation_dict, by = "series") |>
    mutate(
      transformed_value = case_when(
        transformation == 1 ~ value,
        transformation == 2 ~ value - lag(value),
        transformation == 3 ~ (value - lag(value)) - lag(value - lag(value)),
        transformation == 4 ~ log(value),
        transformation == 5 ~ log(value) - lag(log(value)),
        transformation == 6 ~ (log(value) - lag(log(value))) - lag(log(value) - lag(log(value))),
        transformation == 7 ~ (value / lag(value) - 1) - lag(value / lag(value) - 1)
      ),
      .by = series
    )

  return(data_cleaned)
}

cleaned_data_wide <- clean_data("2025-08-MD.csv") |>
  select(Date, series, transformed_value) |>
  pivot_wider(
    names_from = series,
    values_from = transformed_value
  )


fit_model_pca <- function(data) {
  pca_recipe <- recipe(~., data = data) |>
    update_role(Date, new_role = "id") |>
    step_impute_knn(all_numeric_predictors()) |>
    step_normalize(all_numeric_predictors()) |>
    step_pca(all_numeric_predictors(), num_comp = 8)

  pca_prep <- prep(pca_recipe)
}

fitted_pca <- fit_model_pca(cleaned_data_wide)

make_chart_variance_pcs <- function(data) {
  variance_data <- tidy(data, number = 3, type = "variance")

  variance_data |>
    filter(terms == "variance") |>
    mutate(percent_variance = value / sum(value)) |>
    ggplot(aes(x = component, y = percent_variance)) +
    geom_col(fill = "#0072B2", alpha = 0.8) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(
      title = "Variance Explained by Each Principal Component",
      x = "Principal Component",
      y = "Percent of Total Variance Explained"
    ) +
    theme_minimal()
}

make_chart_variance_pcs(fitted_pca)
