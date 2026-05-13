# =============================================================================
# 02_paketler.R
# -----------------------------------------------------------------------------
# Projenin gerektirdiği R paketleri. İlk render'dan önce bu scripti çalıştırın:
#   source("R/02_paketler.R")
# =============================================================================

paketler <- c(
  "tidyverse", "lubridate", "readr", "skimr",
  "ggplot2", "patchwork", "scales", "viridis",
  "GGally", "corrplot",
  "forecast", "tseries", "zoo",
  "tidymodels", "ranger", "xgboost", "vip",
  "FactoMineR", "factoextra",
  "knitr", "kableExtra", "broom"
)

eksik <- paketler[!paketler %in% rownames(installed.packages())]
if (length(eksik) > 0) {
  message("Eksik paketler yükleniyor: ", paste(eksik, collapse = ", "))
  install.packages(eksik, dependencies = TRUE)
} else {
  message("Tüm paketler zaten yüklü.")
}
