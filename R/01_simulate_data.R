# =============================================================================
# 01_simulate_data.R
# -----------------------------------------------------------------------------
# Türkiye Elektrik / Enerji Verileri için yeniden üretilebilir sentetik veri
# üretimi (EPİAŞ + TCMB + TÜİK formatlarında).
#
# Gerçek veri kullanılmak istendiğinde aşağıdaki kolon isimleri korunarak
# data/ klasöründeki CSV dosyaları değiştirilirse rapor (proje.qmd) hiçbir
# değişiklik gerektirmeden tekrar render olabilir.
#
# Üretilen dosyalar:
#   data/elektrik_saatlik.csv : Saatlik tüketim, üretim ve PTF (EPİAŞ tarzı)
#   data/elektrik_gunluk.csv  : Günlük tüketim, üretim, kaynak kırılımı
#   data/tcmb_aylik.csv       : Aylık USD/TRY, EUR/TRY, TÜFE, politika faizi
#   data/tuik_aylik.csv       : Aylık sanayi üretim endeksi, sektörel tüketim
#   data/birlestirilmis_aylik.csv : Üç kaynağın birleştirilmiş aylık seti
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(readr)
  library(tibble)
})

set.seed(2026)

# Windows ve Linux uyumlu Türkçe gün adları için yardımcı
tr_gun_adlari <- c("Pazartesi","Salı","Çarşamba","Perşembe",
                   "Cuma","Cumartesi","Pazar")

if (!dir.exists("data")) dir.create("data", recursive = TRUE)

# -----------------------------------------------------------------------------
# 1. SAATLİK ELEKTRİK VERİSİ (EPİAŞ Şeffaflık tarzı)
# -----------------------------------------------------------------------------
saat_seq <- seq(
  from = as.POSIXct("2023-01-01 00:00:00", tz = "Europe/Istanbul"),
  to   = as.POSIXct("2024-12-31 23:00:00", tz = "Europe/Istanbul"),
  by   = "hour"
)

n_h <- length(saat_seq)
ay_sayisi <- as.numeric(difftime(saat_seq, min(saat_seq), units = "days")) / 30

trend       <- 35000 + 60 * ay_sayisi
mevsim_yil  <- 5500 * sin(2 * pi * (yday(saat_seq) - 200) / 365) +
               3000 * cos(2 * pi * (yday(saat_seq) - 30)  / 365)
hafta_eff   <- ifelse(wday(saat_seq, week_start = 1) %in% 6:7, -3500, 800)
saat_eff    <- 5500 * sin(2 * pi * (hour(saat_seq) - 7) / 24) +
               2200 * sin(4 * pi * (hour(saat_seq) - 5) / 24)

tatil_gun <- as.Date(c("2023-01-01","2023-04-23","2023-05-01","2023-05-19",
                       "2023-07-15","2023-08-30","2023-10-29","2023-12-31",
                       "2024-01-01","2024-04-23","2024-05-01","2024-05-19",
                       "2024-07-15","2024-08-30","2024-10-29"))
tatil_eff <- ifelse(as.Date(saat_seq) %in% tatil_gun, -2800, 0)

gurultu <- rnorm(n_h, 0, 700)

tuketim_mw <- pmax(15000, trend + mevsim_yil + hafta_eff + saat_eff +
                            tatil_eff + gurultu)
toplam_uretim <- tuketim_mw * 1.03

dogalgaz <- toplam_uretim * (0.22 + rnorm(n_h, 0, 0.02))
komur    <- toplam_uretim * (0.34 + rnorm(n_h, 0, 0.02))
hidro    <- toplam_uretim * (0.20 + 0.05 * sin(2 * pi * yday(saat_seq) / 365) +
                             rnorm(n_h, 0, 0.015))
ruzgar   <- toplam_uretim * (0.10 + 0.04 * sin(2 * pi * (hour(saat_seq) - 14) / 24) +
                             rnorm(n_h, 0, 0.02))
gunes    <- toplam_uretim * pmax(0, (0.07 *
                              pmax(0, sin(pi * (hour(saat_seq) - 6) / 12)) *
                              (1 + 0.3 * sin(2 * pi * (yday(saat_seq) - 80) / 365))) +
                             rnorm(n_h, 0, 0.005))
diger    <- pmax(0, toplam_uretim - (dogalgaz + komur + hidro + ruzgar + gunes))

ptf_base <- 1500 + 0.05 * tuketim_mw - 0.04 * (ruzgar + gunes + hidro)
ptf_artis <- ifelse(year(saat_seq) == 2024, 1.55, 1.0)
ptf <- pmax(200, (ptf_base + rnorm(n_h, 0, 180)) * ptf_artis)

elektrik_saatlik <- tibble(
  tarih_saat   = saat_seq,
  tarih        = as.Date(saat_seq),
  saat         = hour(saat_seq),
  tuketim_mwh  = round(tuketim_mw, 1),
  uretim_mwh   = round(toplam_uretim, 1),
  dogalgaz_mwh = round(dogalgaz, 1),
  komur_mwh    = round(komur, 1),
  hidro_mwh    = round(hidro, 1),
  ruzgar_mwh   = round(ruzgar, 1),
  gunes_mwh    = round(gunes, 1),
  diger_mwh    = round(diger, 1),
  ptf_tl_mwh   = round(ptf, 2)
)
write_csv(elektrik_saatlik, "data/elektrik_saatlik.csv")

# -----------------------------------------------------------------------------
# 2. GÜNLÜK ELEKTRİK VERİSİ (2018-2025)
# -----------------------------------------------------------------------------
gun_seq <- seq(as.Date("2018-01-01"), as.Date("2025-04-30"), by = "day")
n_g <- length(gun_seq)
ay_g <- as.numeric(gun_seq - min(gun_seq)) / 30

trend_g  <- 800000 + 1500 * ay_g
mevsim_g <- 130000 * sin(2 * pi * (yday(gun_seq) - 200) / 365) +
            70000  * cos(2 * pi * (yday(gun_seq) - 30) / 365)
hafta_g  <- ifelse(wday(gun_seq, week_start = 1) %in% 6:7, -85000, 20000)
covid_g  <- ifelse(gun_seq >= as.Date("2020-03-15") &
                   gun_seq <= as.Date("2020-06-15"), -110000, 0)
gurultu_g <- rnorm(n_g, 0, 18000)

tuketim_mwh_g <- pmax(450000, trend_g + mevsim_g + hafta_g + covid_g + gurultu_g)
uretim_mwh_g  <- tuketim_mwh_g * 1.03

elektrik_gunluk <- tibble(
  tarih = gun_seq,
  yil   = year(gun_seq),
  ay    = month(gun_seq),
  gun_haftasi = factor(tr_gun_adlari[wday(gun_seq, week_start = 1)],
                       levels = tr_gun_adlari),
  tuketim_mwh  = round(tuketim_mwh_g, 0),
  uretim_mwh   = round(uretim_mwh_g, 0),
  dogalgaz_mwh = round(uretim_mwh_g * (0.23 + rnorm(n_g, 0, 0.025)), 0),
  komur_mwh    = round(uretim_mwh_g * (0.34 + rnorm(n_g, 0, 0.02)), 0),
  hidro_mwh    = round(uretim_mwh_g * (0.21 + 0.06 * sin(2 * pi * yday(gun_seq)/365) +
                                       rnorm(n_g, 0, 0.02)), 0),
  ruzgar_mwh   = round(uretim_mwh_g * (0.10 + rnorm(n_g, 0, 0.02)), 0),
  gunes_mwh    = round(uretim_mwh_g * pmax(0, 0.05 *
                       (1 + 0.4 * sin(2 * pi * (yday(gun_seq) - 80) / 365)) +
                       rnorm(n_g, 0, 0.01)), 0),
  ptf_ortalama_tl_mwh = round(pmax(200,
                                   (1300 + 0.0003 * tuketim_mwh_g +
                                    rnorm(n_g, 0, 200)) *
                                   (1 + 0.45 * (year(gun_seq) - 2018) / 7)), 2),
  ortalama_sicaklik_c = round(15 + 12 * sin(2 * pi * (yday(gun_seq) - 100) / 365) +
                              rnorm(n_g, 0, 2.5), 1)
)
write_csv(elektrik_gunluk, "data/elektrik_gunluk.csv")

# -----------------------------------------------------------------------------
# 3. TCMB VERİSİ (Aylık)
# -----------------------------------------------------------------------------
ay_seq <- seq(as.Date("2018-01-01"), as.Date("2025-04-01"), by = "month")
n_a <- length(ay_seq)
t <- seq_along(ay_seq)

usd_try <- 3.8 * exp(0.025 * t) * (1 + rnorm(n_a, 0, 0.04))
usd_try[ay_seq >= as.Date("2021-12-01") & ay_seq <= as.Date("2022-02-01")] <-
  usd_try[ay_seq >= as.Date("2021-12-01") & ay_seq <= as.Date("2022-02-01")] * 1.4

eur_try <- usd_try * (1.10 + rnorm(n_a, 0, 0.03))

tufe_yillik <- 12 + 5 * t + rnorm(n_a, 0, 4)
tufe_yillik[ay_seq >= as.Date("2022-01-01") & ay_seq <= as.Date("2023-12-01")] <-
  tufe_yillik[ay_seq >= as.Date("2022-01-01") & ay_seq <= as.Date("2023-12-01")] + 30
tufe_yillik <- pmin(85, pmax(8, tufe_yillik))

politika_faizi <- 8 + 0.4 * t + rnorm(n_a, 0, 2)
politika_faizi[ay_seq >= as.Date("2023-06-01")] <-
  politika_faizi[ay_seq >= as.Date("2023-06-01")] + 25
politika_faizi <- pmin(50, pmax(5, politika_faizi))

tcmb_aylik <- tibble(
  tarih = ay_seq,
  yil   = year(ay_seq),
  ay    = month(ay_seq),
  usd_try        = round(usd_try, 4),
  eur_try        = round(eur_try, 4),
  tufe_yillik    = round(tufe_yillik, 2),
  politika_faizi = round(politika_faizi, 2),
  reel_efektif_kur = round(80 - 0.3 * t + rnorm(n_a, 0, 4), 2)
)
write_csv(tcmb_aylik, "data/tcmb_aylik.csv")

# -----------------------------------------------------------------------------
# 4. TÜİK VERİSİ (Aylık)
# -----------------------------------------------------------------------------
sue_trend <- 100 + 0.4 * t
sue_mevsim <- 6 * sin(2 * pi * (month(ay_seq) - 4) / 12)
sue_covid <- ifelse(ay_seq >= as.Date("2020-03-01") &
                    ay_seq <= as.Date("2020-07-01"), -25, 0)
sanayi_uretim <- sue_trend + sue_mevsim + sue_covid + rnorm(n_a, 0, 3)

toplam_aylik_tuketim <- 24500 + 80 * t + 3500 * sin(2 * pi * (month(ay_seq) - 7) / 12) +
                        rnorm(n_a, 0, 800)

tuik_aylik <- tibble(
  tarih = ay_seq,
  yil   = year(ay_seq),
  ay    = month(ay_seq),
  sanayi_uretim_endeksi = round(sanayi_uretim, 1),
  toplam_tuketim_gwh    = round(toplam_aylik_tuketim, 1),
  sanayi_tuketim_gwh    = round(toplam_aylik_tuketim * 0.42 + rnorm(n_a, 0, 200), 1),
  konut_tuketim_gwh     = round(toplam_aylik_tuketim * 0.24 + rnorm(n_a, 0, 150), 1),
  ticarethane_gwh       = round(toplam_aylik_tuketim * 0.16 + rnorm(n_a, 0, 100), 1),
  resmi_daire_gwh       = round(toplam_aylik_tuketim * 0.05 + rnorm(n_a, 0, 50), 1),
  diger_gwh             = round(toplam_aylik_tuketim * 0.13 + rnorm(n_a, 0, 80), 1),
  nufus_milyon          = round(81 + 0.012 * t + rnorm(n_a, 0, 0.05), 3),
  issizlik_orani        = round(11 - 0.04 * t + 1.2 * sin(2 * pi * month(ay_seq)/12) +
                                rnorm(n_a, 0, 0.6), 2)
)
write_csv(tuik_aylik, "data/tuik_aylik.csv")

# -----------------------------------------------------------------------------
# 5. BİRLEŞTİRİLMİŞ AYLIK VERİ
# -----------------------------------------------------------------------------
elektrik_aylik <- elektrik_gunluk %>%
  mutate(yil_ay = floor_date(tarih, "month")) %>%
  group_by(yil_ay) %>%
  summarise(
    toplam_tuketim_mwh    = sum(tuketim_mwh),
    ortalama_ptf_tl_mwh   = mean(ptf_ortalama_tl_mwh),
    ortalama_sicaklik_c   = mean(ortalama_sicaklik_c),
    yenilenebilir_orani   = mean((hidro_mwh + ruzgar_mwh + gunes_mwh) / uretim_mwh),
    .groups = "drop"
  ) %>%
  rename(tarih = yil_ay)

birlestirilmis_aylik <- elektrik_aylik %>%
  inner_join(tcmb_aylik, by = "tarih") %>%
  inner_join(tuik_aylik %>% select(-yil, -ay), by = "tarih") %>%
  mutate(yil = year(tarih), ay = month(tarih))

write_csv(birlestirilmis_aylik, "data/birlestirilmis_aylik.csv")

cat("Tüm veri dosyaları 'data/' klasörüne yazıldı.\n")
cat("Saatlik:", nrow(elektrik_saatlik), "| Günlük:", nrow(elektrik_gunluk),
    "| Aylık:", nrow(birlestirilmis_aylik), "\n")
