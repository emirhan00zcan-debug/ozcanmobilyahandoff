import { getCities, getDistrictsByCityCode, getNeighbourhoodsByCityCodeAndDistrict } from "turkey-neighbourhoods";

// turkey-neighbourhoods paketi (~24MB açılmış veri) sadece burada, sunucu tarafında
// kullanılır — İl/İlçe seçimi zaten src/lib/data/cities.json ile istemciye gönderiliyor,
// mahalle listesi ise seçilen ilçeye göre bu API'den (bkz. app/api/mahalle/route.ts)
// istek üzerine çekilir; paketin tamamı client bundle'a asla dahil olmaz.
const cityCodeByUpperName = new Map(getCities().map((c) => [c.name.toLocaleUpperCase("tr-TR"), c.code]));

export function getNeighbourhoods(cityName: string, districtName: string): string[] {
  const cityCode = cityCodeByUpperName.get(cityName.toLocaleUpperCase("tr-TR"));
  if (!cityCode) return [];

  const districts = getDistrictsByCityCode(cityCode);
  const district = districts.find((d) => d.toLocaleUpperCase("tr-TR") === districtName.toLocaleUpperCase("tr-TR"));
  if (!district) return [];

  return getNeighbourhoodsByCityCodeAndDistrict(cityCode, district);
}
