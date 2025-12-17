#' Predict cardiovascular disease risk category
#'
#' This function applies the trained Random Forest model used in the Shiny app
#' to new patient data and returns a **risk category label**
#' (High Risk / Low Risk), not probabilities.
#'
#' @param new_data A data.frame containing patient features with columns:
#' age (days), gender, height, weight, ap_hi, ap_lo,
#' cholesterol, gluc, smoke, alco, active.
#'
#' @return A factor vector with levels c("Low Risk", "High Risk").
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   age = 18250,
#'   gender = 1,
#'   height = 165,
#'   weight = 70,
#'   ap_hi = 120,
#'   ap_lo = 80,
#'   cholesterol = 1,
#'   gluc = 1,
#'   smoke = 0,
#'   alco = 0,
#'   active = 1
#' )
#' predict_cvd(df)
#' }
#'
#' @export
predict_cvd <- function(new_data) {

  stopifnot(is.data.frame(new_data))

  # Load bundled model
  bundle_path <- system.file("extdata", "model_bundle.rds", package = "cardioPredictR")
  if (bundle_path == "") stop("Model bundle not found.")

  bundle <- readRDS(bundle_path)

  df <- new_data

  # ----------------------------
  # Feature engineering (same as Shiny)
  # ----------------------------
  df <- df |>
    dplyr::mutate(
      gender = factor(gender, levels = bundle$factor_levels$gender),
      cholesterol = factor(cholesterol, levels = bundle$factor_levels$cholesterol),
      gluc = factor(gluc, levels = bundle$factor_levels$gluc),
      smoke = factor(smoke, levels = bundle$factor_levels$smoke),
      alco = factor(alco, levels = bundle$factor_levels$alco),
      active = factor(active, levels = bundle$factor_levels$active),
      BMI = weight / ((height / 100)^2),
      pulse_pressure = ap_hi - ap_lo,
      high_bp_flag = factor(
        ifelse(ap_hi >= 140 | ap_lo >= 90, 1, 0),
        levels = bundle$factor_levels$high_bp_flag
      )
    )

  # Ensure column order
  df <- df[, bundle$feature_names, drop = FALSE]

  # ----------------------------
  # Prediction
  # ----------------------------
  # ---- Prediction ----
  if (!requireNamespace("ranger", quietly = TRUE)) {
    stop("Package 'ranger' is required but not installed.")
  }

  pred <- stats::predict(bundle$model, data = df)

  # ranger-style probability matrix
  prob_cvd <- if (is.matrix(pred$predictions)) {
    pred$predictions[, "CVD"]
  } else {
    pred$predictions
  }

  factor(
    ifelse(prob_cvd >= 0.5, "High Risk", "Low Risk"),
    levels = c("Low Risk", "High Risk")
  )
}
