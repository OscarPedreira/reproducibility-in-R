clean_data <- function(raw_data_path) {
  data <- read_csv(
    raw_data_path,
    show_col_types = FALSE,
    name_repair = "universal"
  )

  transformation_dict <- data |>
    slice_head(n = 1) |>
    pivot_longer(!sasdate, names_to = "series", values_to = "transformation") |>
    select(series, transformation)

  data_cleaned <- data |>
    slice(-1) |>
    transmute(
      Date = dmy(sasdate),
      across(-sasdate, as.numeric)
    ) |>
    pivot_longer(-Date, names_to = "series", values_to = "value") |>
    left_join(transformation_dict, by = "series") |>
    mutate(
      transformed_value = case_when(
        transformation == 1 ~ value,
        transformation == 2 ~ value - lag(value),
        transformation == 3 ~ (value - lag(value)) - lag(value - lag(value)),
        transformation == 4 ~ suppressWarnings(log(value)),
        transformation == 5 ~ suppressWarnings(log(value)) - lag(suppressWarnings(log(value))),
        transformation == 6 ~ (suppressWarnings(log(value)) - lag(suppressWarnings(log(value)))) -
          lag(suppressWarnings(log(value)) - lag(suppressWarnings(log(value)))),
        transformation == 7 ~ (value / lag(value) - 1) - lag(value / lag(value) - 1)
      ),
      .by = series
    )

  return(data_cleaned)
}

pivot_cleaned_data_wide <- function(cleaned_data_long) {
  cleaned_data_long |>
    select(Date, series, transformed_value) |>
    pivot_wider(
      names_from = series,
      values_from = transformed_value
    )
}

fit_model_pca <- function(data_wide, num_comp = 8, neighbors = 5) {
  pca_recipe <- recipe(~., data = data_wide) |>
    update_role(Date, new_role = "id") |>
    step_impute_knn(all_numeric_predictors(), neighbors = neighbors) |>
    step_normalize(all_numeric_predictors()) |>
    step_pca(all_numeric_predictors(), num_comp = num_comp)
  prep(pca_recipe)
}

make_chart_variance_pcs <- function(fitted_pca_model) {
  variance_data <- tidy(fitted_pca_model, number = 3, type = "variance")

  variance_data |>
    filter(terms == "variance") |>
    mutate(percent_variance = value / sum(value)) |>
    ggplot(aes(x = component, y = percent_variance)) +
    geom_col(fill = "#0072B2", alpha = 0.8) +
    scale_y_continuous(labels = percent_format()) +
    labs(
      title = "Variance Explained by Each Principal Component",
      x = "Principal Component",
      y = "Percent of Total Variance Explained"
    ) +
    theme_minimal()
}

save_chart <- function(chart_object, path) {
  ggsave(
    filename = path,
    plot = chart_object,
    width = 8,
    height = 6,
    bg = "white"
  )

  return(path)
}
