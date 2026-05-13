# Veri Klasörü — Veri Sözlüğü

Bu klasör, projede kullanılan tüm veri dosyalarını içerir. Dosyalar
`R/01_simulate_data.R` scripti tarafından **yeniden üretilebilir biçimde**
oluşturulmuştur (`set.seed(2026)`).

> **Not:** Veriler, Türkiye'nin gerçek elektrik tüketim ve makroekonomik
> dinamiklerine (mevsimsellik, gün içi profiller, kur–enflasyon
> ilişkileri, COVID-19 etkisi) sadık kalınarak simüle edilmiştir. EPİAŞ,
> TCMB ve TÜİK resmi sitelerinden indirilen CSV dosyaları, aşağıdaki
> kolon şeması korunarak bu klasördeki dosyaların yerine konabilir;
> rapor (`proje.qmd`) yeniden render edildiğinde tüm analizler aynen
> çalışacaktır.

## Dosyaları Oluştur

```r
source("R/02_paketler.R")     # paketleri yükle
source("R/01_simulate_data.R") # 5 CSV dosyasını üret
```

---

## 1. `elektrik_saatlik.csv`

**Kapsam:** 2023-01-01 — 2024-12-31, saatlik (17.544 satır)

| Kolon | Tür | Açıklama |
|---|---|---|
| `tarih_saat` | datetime | Saat damgası |
| `tarih` | date | Gün |
| `saat` | int | 0-23 |
| `tuketim_mwh` | num | Saatlik tüketim |
| `uretim_mwh` | num | Saatlik toplam üretim |
| `dogalgaz_mwh`, `komur_mwh`, `hidro_mwh`, `ruzgar_mwh`, `gunes_mwh`, `diger_mwh` | num | Kaynak bazlı üretim |
| `ptf_tl_mwh` | num | Piyasa Takas Fiyatı |

## 2. `elektrik_gunluk.csv`

**Kapsam:** 2018-01-01 — 2025-04-30, günlük (~2.677 satır)

## 3. `tcmb_aylik.csv`

USD/TRY, EUR/TRY, TÜFE, Politika Faizi, Reel Efektif Kur (88 ay)

## 4. `tuik_aylik.csv`

Sanayi Üretim Endeksi, sektörel tüketim, nüfus, işsizlik (88 ay)

## 5. `birlestirilmis_aylik.csv`

Üç kaynağın aylık seviyede birleştirilmiş hâli — modelleme aşamasında
kullanılır.

---

## Veri Kaynakları

| Kaynak | URL |
|---|---|
| EPİAŞ Şeffaflık | https://seffaflik.epias.com.tr/transparency/ |
| TCMB EVDS | https://evds2.tcmb.gov.tr/ |
| TÜİK | https://data.tuik.gov.tr/ |
