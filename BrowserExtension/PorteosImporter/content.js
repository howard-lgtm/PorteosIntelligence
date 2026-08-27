/**
 * Porteos Importer — content.js (v5.0)
 *
 * Supported sites:
 *   USA      — Zillow, Realtor.com, Redfin, Trulia
 *   Portugal — Idealista.pt, Casa SAPO, RE/MAX Portugal, Imovirtual
 *   Spain    — Idealista.com, Fotocasa
 *   Sweden   — Hemnet, Booli
 *
 * Architecture: each site has its own init function. Data is collected at
 * button-click time (not injection time) so React/Next.js hydration delays
 * are not an issue. All price parsing handles EU (1.350.000) and US (1,350,000)
 * formats. sqft → m² conversion: ÷ 10.764.
 */

(function () {
  "use strict";

  const SERVER_URL = "http://localhost:9000/api/deals";

  // ── Shared utilities ───────────────────────────────────────────────────────

  function trySelect(...selectors) {
    for (const sel of selectors) {
      try {
        const el = document.querySelector(sel);
        if (el && el.textContent.trim()) return el.textContent.trim();
      } catch { /* skip invalid selector */ }
    }
    return "";
  }

  function parseNumber(str) { return parsePrice(str); }

  /** Handles EU thousands (1.350.000 / 1 350 000), US (1,350,000), and decimals. */
  function parsePrice(raw) {
    if (!raw) return 0;
    let s = String(raw).replace(/[^\d.,\s]/g, "").trim();
    if (!s) return 0;
    s = s.replace(/\s/g, "");
    const hasComma = s.includes(",");
    const hasDot   = s.includes(".");
    if (hasComma && hasDot) {
      const lastComma = s.lastIndexOf(",");
      const lastDot   = s.lastIndexOf(".");
      if (lastComma > lastDot) {
        s = s.replace(/\./g, "").replace(",", ".");
      } else {
        s = s.replace(/,/g, "");
      }
    } else if (hasDot) {
      const parts = s.split(".");
      if (parts.length > 2 || (parts.length === 2 && parts[1].length === 3)) {
        s = s.replace(/\./g, "");
      }
    } else if (hasComma) {
      const parts = s.split(",");
      if (parts.length > 2 || (parts.length === 2 && parts[1].length === 3)) {
        s = s.replace(/,/g, "");
      } else {
        s = s.replace(",", ".");
      }
    }
    const n = parseFloat(s);
    return isNaN(n) || n < 1000 ? 0 : n;
  }

  function sqftToM2(sqft) { return Math.round(sqft / 10.764); }

  function priceFromJsonLd() {
    const ld = extractJsonLd();
    if (!ld) return 0;
    const items = Array.isArray(ld) ? ld : [ld];
    for (const item of items) {
      if (item?.price) {
        const n = parsePrice(String(item.price));
        if (n >= 1000) return n;
      }
      const offerList = Array.isArray(item?.offers) ? item.offers : item?.offers ? [item.offers] : [];
      for (const offer of offerList) {
        if (offer?.price) {
          const n = parsePrice(String(offer.price));
          if (n >= 1000) return n;
        }
      }
    }
    return 0;
  }

  function extractJsonLd() {
    try {
      const el = document.querySelector('script[type="application/ld+json"]');
      return el ? JSON.parse(el.textContent) : null;
    } catch { return null; }
  }

  function coordsFromJsonLd() {
    const ld = extractJsonLd();
    if (ld?.geo?.latitude)
      return { lat: parseFloat(ld.geo.latitude), lng: parseFloat(ld.geo.longitude) };
    return null;
  }

  function coordsFromMeta() {
    const latMeta = document.querySelector('meta[property="place:location:latitude"]');
    const lngMeta = document.querySelector('meta[property="place:location:longitude"]');
    if (latMeta && lngMeta)
      return { lat: parseFloat(latMeta.content), lng: parseFloat(lngMeta.content) };
    return null;
  }

  function coordsFromDataAttrs(selector = "[data-latitude][data-longitude]") {
    const el = document.querySelector(selector);
    if (el) return { lat: parseFloat(el.dataset.latitude), lng: parseFloat(el.dataset.longitude) };
    const el2 = document.querySelector("[data-lat][data-lng]");
    if (el2) return { lat: parseFloat(el2.dataset.lat), lng: parseFloat(el2.dataset.lng) };
    return null;
  }

  function injectButton(onSend) {
    if (document.getElementById("porteos-send-btn")) return;
    const btn = document.createElement("button");
    btn.id          = "porteos-send-btn";
    btn.textContent = "[ SEND TO PORTEOS ]";
    Object.assign(btn.style, {
      position:      "fixed",
      bottom:        "24px",
      right:         "24px",
      zIndex:        "2147483647",
      background:    "#0F1115",
      color:         "#10B981",
      border:        "1px solid #2E333F",
      borderRadius:  "0",
      fontFamily:    "'JetBrains Mono', 'Courier New', Courier, monospace",
      fontSize:      "12px",
      fontWeight:    "700",
      padding:       "10px 16px",
      cursor:        "pointer",
      letterSpacing: "0.05em",
      boxShadow:     "0 0 0 1px #2E333F",
      transition:    "background 0.15s, color 0.15s",
      userSelect:    "none",
    });
    btn.addEventListener("mouseenter", () => { btn.style.background = "#1A1D24"; });
    btn.addEventListener("mouseleave", () => { btn.style.background = "#0F1115"; });
    btn.addEventListener("click", () => {
      btn.textContent = "[ SENDING... ]";
      btn.style.color = "#F59E0B";
      btn.disabled    = true;
      const payload = onSend();
      console.log("[Porteos Importer] Sending payload:", payload);
      fetch(SERVER_URL, {
        method:  "POST",
        headers: { "Content-Type": "application/json" },
        body:    JSON.stringify(payload),
      })
        .then((res) => {
          if (!res.ok) throw new Error("HTTP " + res.status);
          return res.json();
        })
        .then(() => {
          btn.textContent       = "[ SENT \u2713 ]";
          btn.style.color       = "#10B981";
          btn.style.borderColor = "#10B981";
          setTimeout(() => {
            btn.textContent       = "[ SEND TO PORTEOS ]";
            btn.style.color       = "#10B981";
            btn.style.borderColor = "#2E333F";
            btn.disabled          = false;
          }, 4000);
        })
        .catch((err) => {
          console.error("[Porteos Importer] Send failed:", err);
          btn.textContent       = "[ ERROR — PORTEOS OFFLINE? ]";
          btn.style.color       = "#EF4444";
          btn.style.borderColor = "#EF4444";
          setTimeout(() => {
            btn.textContent       = "[ SEND TO PORTEOS ]";
            btn.style.color       = "#10B981";
            btn.style.borderColor = "#2E333F";
            btn.disabled          = false;
          }, 5000);
        });
    });
    document.body.appendChild(btn);
  }

  // ── Site router ────────────────────────────────────────────────────────────

  const hostname = window.location.hostname;

  // USA
  if (hostname.includes("zillow.com"))              initZillow();
  else if (hostname.includes("realtor.com"))         initRealtor();
  else if (hostname.includes("redfin.com"))          initRedfin();
  else if (hostname.includes("trulia.com"))          initTrulia();
  // Portugal
  else if (hostname.includes("idealista.pt"))        initIdealistapt();
  else if (hostname.includes("casa.sapo.pt"))        initCasaSapo();
  else if (hostname.includes("remax.pt"))            initRemaxPt();
  else if (hostname.includes("imovirtual.com"))      initImovirtual();
  // Spain
  else if (hostname.includes("idealista.com"))       initIdealistaEs();
  else if (hostname.includes("fotocasa.es"))         initFotocasa();
  // Sweden
  else if (hostname.includes("hemnet.se"))           initHemnet();
  else if (hostname.includes("booli.se"))            initBooli();

  // ══════════════════════════════════════════════════════════════════════════
  //  USA
  // ══════════════════════════════════════════════════════════════════════════

  // ── Zillow ─────────────────────────────────────────────────────────────────

  function initZillow() {
    if (!/\/homedetails\//i.test(window.location.pathname)) return;

    function nextData() {
      const nd = document.getElementById("__NEXT_DATA__");
      if (!nd) return null;
      try {
        const data  = JSON.parse(nd.textContent);
        const props = data?.props?.pageProps;
        const cache = props?.initialReduxState?.gdpClientCache;
        if (cache) {
          const key = Object.keys(cache)[0];
          return cache[key]?.property || null;
        }
        return props?.componentProps || null;
      } catch { return null; }
    }

    function price() {
      const raw = trySelect(
        "[data-testid='price']",
        "span[data-testid='price-details']",
        ".ds-summary-row span[class*='Price']",
        "span[class*='zsg-photo-card-price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/([\d,]+)\s*(?:sq\.?\s*ft\.?|sqft)/i);
      return m ? sqftToM2(parseFloat(m[1].replace(/,/g, ""))) : 0;
    }

    function bedrooms() {
      const m = document.body.innerText.match(/(\d+)\s*bd\b/i)
             || document.body.innerText.match(/(\d+)\s*bed(?:room)?s?\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function bathrooms() {
      const m = document.body.innerText.match(/(\d+(?:\.\d+)?)\s*ba\b/i)
             || document.body.innerText.match(/(\d+(?:\.\d+)?)\s*bath(?:room)?s?\b/i);
      return m ? parseFloat(m[1]) : 0;
    }

    function city() {
      const chips = document.querySelectorAll(
        "[data-testid='home-details-chip-title'], .ds-address-container h1, h1"
      );
      for (const el of chips) {
        const parts = el.textContent.split(",");
        if (parts.length >= 2) return parts[1].trim().replace(/\s+\w{2}\s+\d{5}.*/, "").trim();
      }
      return trySelect("[data-testid='bdp-building-name']");
    }

    function address() {
      return trySelect("h1[data-testid='home-details-chip-title']", ".ds-address-container h1", "h1");
    }

    function coordinates() {
      const nd = document.getElementById("__NEXT_DATA__");
      if (nd) {
        try {
          const data  = JSON.parse(nd.textContent);
          const props = data?.props?.pageProps;
          const lat   = props?.componentProps?.latitude;
          const lng   = props?.componentProps?.longitude;
          if (lat && lng) return { lat: parseFloat(lat), lng: parseFloat(lng) };
        } catch { /* continue */ }
      }
      return coordsFromMeta() || coordsFromJsonLd();
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "zillow",
        url:                 window.location.href,
        propertyName:        address() || document.title.split("|")[0].trim(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "USA",
        currency:            "USD",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Zillow injected");
  }

  // ── Realtor.com ────────────────────────────────────────────────────────────

  function initRealtor() {
    // Match property detail pages (various URL schemes over the years)
    if (!/\/(realestateandhomes-detail|homedetails|property|listing)\//i.test(window.location.pathname)
        && !/\/\d{8,}$/.test(window.location.pathname)) return;

    function ndProperty() {
      const nd = document.getElementById("__NEXT_DATA__");
      if (!nd) return null;
      try {
        const data  = JSON.parse(nd.textContent);
        const props = data?.props?.pageProps;
        return props?.property || props?.listing || props?.initialProps?.property || null;
      } catch { return null; }
    }

    function price() {
      const nd = ndProperty();
      if (nd?.list_price) return parseFloat(nd.list_price);
      const raw = trySelect(
        "[data-testid='list-price']",
        "[class*='price-display']",
        ".price-display",
        "[class*='listing-price']",
        "span[class*='Price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const nd = ndProperty();
      const sqft = nd?.lot_sqft || nd?.sqft || nd?.building_size?.size;
      if (sqft) return sqftToM2(parseFloat(sqft));
      const m = document.body.innerText.match(/([\d,]+)\s*(?:sq\.?\s*ft\.?|sqft)/i);
      return m ? sqftToM2(parseFloat(m[1].replace(/,/g, ""))) : 0;
    }

    function bedrooms() {
      const nd = ndProperty();
      if (nd?.beds) return parseInt(nd.beds, 10);
      const raw = trySelect(
        "[data-testid='property-meta-beds']",
        "[class*='bed'][class*='count']"
      );
      if (raw) return parseInt(raw, 10) || 0;
      const m = document.body.innerText.match(/(\d+)\s*(?:bed(?:room)?s?|bd)\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function bathrooms() {
      const nd = ndProperty();
      if (nd?.baths_consolidated) return parseFloat(nd.baths_consolidated);
      if (nd?.baths) return parseFloat(nd.baths);
      const m = document.body.innerText.match(/(\d+(?:\.\d+)?)\s*(?:bath(?:room)?s?|ba)\b/i);
      return m ? parseFloat(m[1]) : 0;
    }

    function city() {
      const nd = ndProperty();
      if (nd?.location?.address?.city) return nd.location.address.city;
      const h1 = document.querySelector("h1");
      if (h1) {
        const parts = h1.textContent.split(",");
        if (parts.length >= 2) return parts[1].trim().replace(/\s+[A-Z]{2}\s+\d{5}.*/, "").trim();
      }
      return "";
    }

    function address() {
      const nd = ndProperty();
      if (nd?.location?.address?.line) return nd.location.address.line;
      return trySelect("[data-testid='address']", "h1", ".property-address") || "";
    }

    function coordinates() {
      const nd = ndProperty();
      if (nd?.location?.coordinate?.lat)
        return { lat: parseFloat(nd.location.coordinate.lat), lng: parseFloat(nd.location.coordinate.lon) };
      return coordsFromJsonLd() || coordsFromMeta();
    }

    function propertyType() {
      const nd = ndProperty();
      const type = (nd?.prop_type || "").toLowerCase();
      const map = {
        single_family: "House", condo: "Apartment", multi_family: "Multi-Dwelling",
        townhouse: "House", land: "Land", commercial: "Commercial",
        farm: "Farm/Rural", mobile: "Property", other: "Property",
      };
      return map[type] || "Property";
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "realtor_com",
        url:                 window.location.href,
        propertyName:        address() || document.title.split("|")[0].trim(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "USA",
        currency:            "USD",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        propertyType:        propertyType(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Realtor.com injected");
  }

  // ── Redfin ─────────────────────────────────────────────────────────────────

  function initRedfin() {
    // Redfin listing URLs always contain /home/ or /condo/
    if (!/\/(home|condo|townhouse|multi-family)\//i.test(window.location.pathname)) return;

    function price() {
      const raw = trySelect(
        "[data-rf-test-id='abp-price']",
        ".homeSalesPriceSection .price",
        "[class*='price-section'] span",
        ".statsValue[data-stat-group*='price']",
        ".price-container span"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      // Try the prominent $ amount in body text
      const m = document.body.innerText.match(/\$\s*([\d,]+)/);
      if (m) {
        const n = parsePrice(m[1]);
        if (n >= 10000) return n;
      }
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/([\d,]+)\s*Sq\.?\s*Ft\.?/i);
      return m ? sqftToM2(parseFloat(m[1].replace(/,/g, ""))) : 0;
    }

    function bedrooms() {
      const m = document.body.innerText.match(/(\d+)\s*(?:Beds?|Bedrooms?)\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function bathrooms() {
      const m = document.body.innerText.match(/(\d+(?:\.\d+)?)\s*(?:Baths?|Bathrooms?)\b/i);
      return m ? parseFloat(m[1]) : 0;
    }

    function title() {
      return trySelect(
        "[data-rf-test-id='abp-streetLine']",
        ".street-address",
        "h1[class*='address']",
        "h1"
      ) || document.title.split("|")[0].trim();
    }

    function city() {
      const el = document.querySelector(
        "[data-rf-test-id='abp-cityStateZip'], .cityStateZip"
      );
      if (el) return el.textContent.split(",")[0].trim();
      const h1 = document.querySelector("h1");
      if (h1) {
        const parts = h1.textContent.split(",");
        if (parts.length >= 2) return parts[1].trim().replace(/\s+[A-Z]{2}\s+\d{5}.*/, "").trim();
      }
      return "";
    }

    function coordinates() {
      return coordsFromJsonLd() || coordsFromMeta() || coordsFromDataAttrs();
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "redfin",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: title(),
        locationCity:        city(),
        locationCountry:     "USA",
        currency:            "USD",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Redfin injected");
  }

  // ── Trulia ─────────────────────────────────────────────────────────────────

  function initTrulia() {
    // Trulia listing URLs: /p/{address}/ or /building/{addr}/
    if (!/\/(p|building|property)\/[^/]+\/\d/i.test(window.location.pathname)
        && !window.location.pathname.startsWith("/p/")) return;

    function price() {
      const raw = trySelect(
        "[data-testid='home-sale-price']",
        "[class*='Price'][class*='display']",
        ".priceLockup span",
        "[class*='SalePrice']",
        "[class*='listing-price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/([\d,]+)\s*(?:sq\.?\s*ft\.?|sqft)/i);
      return m ? sqftToM2(parseFloat(m[1].replace(/,/g, ""))) : 0;
    }

    function bedrooms() {
      const m = document.body.innerText.match(/(\d+)\s*(?:bed(?:room)?s?|bd)\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function bathrooms() {
      const m = document.body.innerText.match(/(\d+(?:\.\d+)?)\s*(?:bath(?:room)?s?|ba)\b/i);
      return m ? parseFloat(m[1]) : 0;
    }

    function title() {
      return trySelect(
        "h1[class*='Address']",
        ".propertyAddress h1",
        "[data-testid='home-address']",
        "h1"
      ) || document.title.split("|")[0].trim();
    }

    function city() {
      const h1 = document.querySelector("h1");
      if (h1) {
        const parts = h1.textContent.split(",");
        if (parts.length >= 2) return parts[1].trim().replace(/\s+[A-Z]{2}\s+\d{5}.*/, "").trim();
      }
      return trySelect("[class*='cityState']");
    }

    function coordinates() {
      return coordsFromJsonLd() || coordsFromMeta();
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "trulia",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: title(),
        locationCity:        city(),
        locationCountry:     "USA",
        currency:            "USD",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Trulia injected");
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PORTUGAL
  // ══════════════════════════════════════════════════════════════════════════

  // ── Idealista Portugal ─────────────────────────────────────────────────────

  function initIdealistapt() {
    if (!/\/imovel\/\d+/i.test(window.location.pathname)) return;

    function price() {
      const raw = trySelect(
        ".info-data-price", "span.info-data-price",
        "[class*='price-box']", "span[class*='price']",
        "[data-testid='price']", ".price-container .price"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/(\d[\d.,]*)\s*m[²2]/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function bedrooms() {
      const t = document.body.innerText.match(/\bT(\d)\b/i);
      if (t) return parseInt(t[1], 10);
      const q = document.body.innerText.match(/(\d)\s+quarto/i);
      return q ? parseInt(q[1], 10) : 0;
    }

    function city() {
      return trySelect(
        ".main-info__location", "[class*='location']",
        ".breadcrumb li:last-child", ".detail-info-location"
      );
    }

    function address() {
      const ld = extractJsonLd();
      if (ld?.address?.streetAddress) return ld.address.streetAddress;
      return "";
    }

    function coordinates() {
      const iframes = document.querySelectorAll(
        'iframe[src*="google.com/maps"], iframe[src*="google.pt/maps"]'
      );
      for (const f of iframes) {
        const m = f.src.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
        if (m) return { lat: parseFloat(m[1]), lng: parseFloat(m[2]) };
        const q = f.src.match(/[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)/);
        if (q) return { lat: parseFloat(q[1]), lng: parseFloat(q[2]) };
      }
      return coordsFromJsonLd();
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "idealista_pt",
        url:                 window.location.href,
        propertyName:        trySelect("h1.main-info__title-main", "h1") || document.title.split(" - ")[0].trim(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "Portugal",
        currency:            "EUR",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           0,
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Idealista.pt injected");
  }

  // ── RE/MAX Portugal ────────────────────────────────────────────────────────

  function initRemaxPt() {
    const path = window.location.pathname;
    if (!path.includes("/imoveis/")) return;
    if (!path.includes("/venda-") && !path.includes("/arrendar-")) return;

    function slugParts() {
      const slug = path.split("/").find((p) => p.startsWith("venda-") || p.startsWith("arrendar-")) || "";
      return slug.split("-");
    }

    function typeFromSlug() {
      const parts = slugParts();
      const idx   = parts.findIndex((p) => p === "venda" || p === "arrendar");
      const type  = parts[idx + 1] || "";
      const map   = {
        apartamento: "Apartment", moradia: "House", vivenda: "House",
        escritorio: "Office", loja: "Retail", armazem: "Warehouse",
        terreno: "Land", quinta: "Farm/Rural", garagem: "Garage",
        hotel: "Hotel", predio: "Building", edificio: "Building",
        villa: "House", chalet: "House", townhouse: "House",
        comercial: "Commercial", industrial: "Industrial",
      };
      return map[type] || (type ? type.charAt(0).toUpperCase() + type.slice(1) : "Property");
    }

    function bedroomsFromSlug() {
      const tx = slugParts().find((p) => /^t\d+$/i.test(p));
      return tx ? parseInt(tx.slice(1), 10) : 0;
    }

    function cityFromSlug() {
      const parts = slugParts();
      const txIdx = parts.findIndex((p) => /^t\d+$/i.test(p));
      if (txIdx >= 0 && parts[txIdx + 1])
        return parts[txIdx + 1].charAt(0).toUpperCase() + parts[txIdx + 1].slice(1);
      return "";
    }

    function price() {
      const raw = trySelect(
        "h2 span", "[class*='listing-price']", "[class*='listingPrice']",
        "[class*='price']", "#listing-price", "strong[class*='price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      const fromLd = priceFromJsonLd();
      if (fromLd >= 1000) return fromLd;
      const euroMatch = document.body.innerText.match(/([\d][\d\s.]*\d)\s*€/);
      if (euroMatch) {
        const n = parsePrice(euroMatch[1]);
        if (n >= 1000) return n;
      }
      return 0;
    }

    function area() {
      const b = document.body.innerText;
      const brutaMatch = b.match(/[Áá]rea Bruta[^0-9]*(\d+)/i);
      if (brutaMatch) return parseFloat(brutaMatch[1]) || 0;
      const mMatch = b.match(/(\d+(?:[,.]\d+)?)\s*m[²2]/i);
      return mMatch ? parseFloat(mMatch[1].replace(",", ".")) || 0 : 0;
    }

    function bedrooms() {
      const fromSlug = bedroomsFromSlug();
      if (fromSlug > 0) return fromSlug;
      const b = document.body.innerText;
      const quartosMatch = b.match(/Quartos\s*(\d+)/i);
      if (quartosMatch) return parseInt(quartosMatch[1], 10);
      const tMatch = b.match(/\bT(\d)\b/);
      return tMatch ? parseInt(tMatch[1], 10) : 0;
    }

    function bathrooms() {
      const m = document.body.innerText.match(/(?:WC|casas? de banho|Wc\/Casas de banho)\s*[:/]?\s*(\d+)/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function city() {
      const fromSlug = cityFromSlug();
      if (fromSlug) return fromSlug;
      return trySelect(
        "h1 span", "[class*='location']", "[class*='address']",
        "h5.listing-address", ".breadcrumb li:last-child"
      );
    }

    function address() {
      const ld = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        const addr = item?.address;
        if (addr?.streetAddress) return addr.streetAddress;
        if (typeof addr === "string" && addr.length > 3) return addr;
      }
      const h1 = document.querySelector("h1");
      if (h1) {
        const emMatch = h1.textContent.match(/\bem\s+(.+)$/i);
        if (emMatch) return emMatch[1].trim();
      }
      return "";
    }

    function coordinates() {
      const ld = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        if (item?.geo?.latitude)
          return { lat: parseFloat(item.geo.latitude), lng: parseFloat(item.geo.longitude) };
      }
      const nd = document.getElementById("__NEXT_DATA__");
      if (nd) {
        try {
          const data    = JSON.parse(nd.textContent);
          const props   = data?.props?.pageProps;
          const listing = props?.listing || props?.property || props?.data;
          if (listing?.latitude && listing?.longitude)
            return { lat: parseFloat(listing.latitude), lng: parseFloat(listing.longitude) };
        } catch { /* continue */ }
      }
      return coordsFromDataAttrs("[data-lat][data-lng], [data-latitude][data-longitude]");
    }

    function title() {
      const h1 = trySelect("h1", "[class*='listing-title']", "#listing-title");
      if (h1 && h1.length > 3) return h1.replace(/\s+/g, " ").trim();
      const t = typeFromSlug();
      const c = city();
      return c ? `${t} in ${c}` : t || document.title.split("|")[0].trim();
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "remax_pt",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "Portugal",
        currency:            "EUR",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] RE/MAX Portugal injected");
  }

  // ── Casa SAPO Portugal ─────────────────────────────────────────────────────

  function initCasaSapo() {
    const path = window.location.pathname;
    const isListing = /\/(comprar|arrendar|imovel|venda)-/.test(path) || path.includes("/imovel/");
    if (!isListing) return;

    const bodyText = document.body.innerText;

    function propertyType() {
      const slug   = path.toLowerCase();
      const typeMap = [
        ["apartamento","Apartment"],["moradia","House"],["vivenda","House"],["villa","House"],
        ["quinta","Farm/Rural"],["herdade","Farm/Rural"],["terreno","Land"],["lote","Land"],
        ["predio","Building"],["edificio","Building"],["escritorio","Office"],["loja","Retail"],
        ["hotel","Hotel"],["hostel","Hotel"],["armazem","Warehouse"],["garagem","Garage"],
      ];
      for (const [pt, en] of typeMap) if (slug.includes(pt)) return en;
      const h1 = document.querySelector("h1");
      if (h1) {
        const t = h1.textContent.toLowerCase();
        for (const [pt, en] of typeMap) if (t.includes(pt)) return en;
      }
      return "Property";
    }

    function price() {
      const fromLd = priceFromJsonLd();
      if (fromLd >= 1000) return fromLd;
      const raw = trySelect(
        "[class*='price']","[id*='price']","[data-testid*='price']",
        ".property-price",".listing-price","h2 span"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      const euroMatch = bodyText.match(/(\d[\d.\s]*\d)\s*€/) || bodyText.match(/€\s*(\d[\d.\s]*\d)/);
      if (euroMatch) {
        const n = parsePrice(euroMatch[1]);
        if (n >= 1000) return n;
      }
      return 0;
    }

    function area() {
      const brutaMatch = bodyText.match(/[Áá]rea\s+[Bb]ruta[^0-9]{0,30}?(\d+(?:[.,]\d+)?)/i);
      if (brutaMatch) { const n = parseFloat(brutaMatch[1].replace(",", ".")); if (n > 0) return n; }
      const utilMatch = bodyText.match(/[Áá]rea\s+[ÚúUu]til[^0-9]{0,30}?(\d+(?:[.,]\d+)?)/i);
      if (utilMatch)  { const n = parseFloat(utilMatch[1].replace(",", "."));  if (n > 0) return n; }
      const mMatch = bodyText.match(/(\d+(?:[.,]\d+)?)\s*m[²2]/);
      return mMatch ? parseFloat(mMatch[1].replace(",", ".")) || 0 : 0;
    }

    function landArea() {
      const m = bodyText.match(/[Áá]rea\s+(?:de\s+)?[Tt]erreno[^0-9]{0,30}?(\d+(?:[.,]\d+)?)/i)
             || bodyText.match(/[Áá]rea\s+de\s+[Ii]mpla[nt]a[çc][ãa]o[^0-9]{0,30}?(\d+(?:[.,]\d+)?)/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function bedrooms() {
      const tMatch = bodyText.match(/\bT(\d)\b/);
      if (tMatch) return parseInt(tMatch[1], 10);
      const qMatch = bodyText.match(/[Qq]uartos?\s*[:\-]?\s*(\d+)/);
      return qMatch ? parseInt(qMatch[1], 10) : 0;
    }

    function bathrooms() {
      const m = bodyText.match(/(?:WC|[Cc]asas?\s+de\s+[Bb]anho)[^0-9]{0,20}?(\d+)/);
      return m ? parseInt(m[1], 10) : 0;
    }

    function city() {
      const h1 = document.querySelector("h1");
      if (h1) {
        const next = h1.nextElementSibling;
        if (next && next.textContent.includes(",")) {
          const parts = next.textContent.trim().split(",");
          if (parts.length >= 2) return parts[1].trim();
        }
        const emMatch = h1.textContent.match(/\bem\s+(.+)$/i);
        if (emMatch) return emMatch[1].trim();
      }
      const crumbs = document.querySelectorAll("nav[aria-label*='breadcrumb'] a, [class*='breadcrumb'] a");
      if (crumbs.length > 0) return crumbs[crumbs.length - 1].textContent.trim();
      const slugMatch = path.match(/(?:comprar|arrendar)-[a-z]+-(.+?)-[a-f0-9]{8}-/);
      if (slugMatch)
        return slugMatch[1].split("-").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
      return "";
    }

    function address() {
      const ld    = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        const addr = item?.address;
        if (addr?.streetAddress) return addr.streetAddress;
        if (typeof addr === "string" && addr.length > 3) return addr;
      }
      const streetMatch = bodyText.match(/(?:na|no|em)\s+(Rua|Av(?:enida)?|Largo|Praça|Travessa|Estrada)[^,.\n]{3,60}/i);
      return streetMatch ? streetMatch[0].replace(/^(?:na|no|em)\s+/i, "").trim() : "";
    }

    function coordinates() {
      const ld    = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        if (item?.geo?.latitude)
          return { lat: parseFloat(item.geo.latitude), lng: parseFloat(item.geo.longitude) };
      }
      const fromMeta = coordsFromMeta();
      if (fromMeta) return fromMeta;
      const scripts = document.querySelectorAll("script:not([src])");
      for (const s of scripts) {
        const src  = s.textContent;
        const latM = src.match(/["\s]lat(?:itude)?[":\s]+(-?\d{1,3}\.\d{4,})/i);
        const lngM = src.match(/["\s]l(?:on|ng)(?:gitude)?[":\s]+(-?\d{1,3}\.\d{4,})/i);
        if (latM && lngM) {
          const lat = parseFloat(latM[1]);
          const lng = parseFloat(lngM[1]);
          if (lat >= 36 && lat <= 43 && lng >= -10 && lng <= -6) return { lat, lng };
        }
      }
      return coordsFromDataAttrs("[data-lat][data-lng],[data-latitude][data-longitude]");
    }

    function title() {
      const h1 = document.querySelector("h1");
      if (h1 && h1.textContent.trim().length > 3) return h1.textContent.trim().replace(/\s+/g, " ");
      const metaTitle = document.querySelector("meta[property='og:title']")?.content;
      if (metaTitle) return metaTitle.split(" - ")[0].trim();
      return `${propertyType()} em ${city()}` || document.title.split(" - ")[0].trim();
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "casa_sapo",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "Portugal",
        currency:            "EUR",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        landArea:            landArea(),
        propertyType:        propertyType(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Casa SAPO injected");
  }

  // ── Imovirtual Portugal ────────────────────────────────────────────────────

  function initImovirtual() {
    if (!window.location.pathname.includes("/oferta/")
        && !window.location.pathname.includes("/anuncio/")) return;

    function ndAd() {
      const nd = document.getElementById("__NEXT_DATA__");
      if (!nd) return null;
      try {
        const data  = JSON.parse(nd.textContent);
        const props = data?.props?.pageProps;
        return props?.ad || props?.listing || props?.data || null;
      } catch { return null; }
    }

    function price() {
      const nd = ndAd();
      if (nd?.price?.value)      return parseFloat(nd.price.value);
      if (nd?.totalPrice?.value) return parseFloat(nd.totalPrice.value);
      const raw = trySelect(
        "[aria-label='Preço']", "[data-cy='adPageHeaderPrice']",
        "[class*='price']", ".priceBox"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const nd = ndAd();
      const sqm = nd?.areaInSquareMeters || nd?.totalArea?.value || nd?.floorArea;
      if (sqm) return parseFloat(sqm) || 0;
      const m = document.body.innerText.match(/(\d+(?:[.,]\d+)?)\s*m[²2]/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function bedrooms() {
      const nd = ndAd();
      if (nd?.roomsNumber !== undefined) return parseInt(nd.roomsNumber, 10);
      const tMatch = document.body.innerText.match(/\bT(\d)\b/);
      if (tMatch) return parseInt(tMatch[1], 10);
      const qMatch = document.body.innerText.match(/(\d+)\s*[Qq]uartos?\b/);
      return qMatch ? parseInt(qMatch[1], 10) : 0;
    }

    function bathrooms() {
      const nd = ndAd();
      if (nd?.bathroomsNumber) return parseInt(nd.bathroomsNumber, 10);
      const m = document.body.innerText.match(/(\d+)\s*(?:WC|casas?\s+de\s+banho|banheiro)\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function title() {
      const nd = ndAd();
      if (nd?.title) return nd.title;
      return trySelect("h1", "[data-cy='adPageAdTitle']") || document.title.split("|")[0].trim();
    }

    function city() {
      const nd = ndAd();
      if (nd?.location?.address?.city?.name) return nd.location.address.city.name;
      const loc = nd?.location?.reverseGeocoding?.locations;
      if (loc?.[0]?.fullName) return loc[0].fullName;
      return trySelect("[data-cy='adPageHeaderLocation']", "[class*='location']", ".breadcrumbs li:last-child");
    }

    function coordinates() {
      const nd = ndAd();
      if (nd?.location?.coordinates?.latitude)
        return { lat: parseFloat(nd.location.coordinates.latitude), lng: parseFloat(nd.location.coordinates.longitude) };
      return coordsFromJsonLd();
    }

    function propertyType() {
      const nd  = ndAd();
      const cat = (nd?.category?.name || nd?.categorySeoName || "").toLowerCase();
      const url = window.location.pathname.toLowerCase();
      const map = {
        "apartamento": "Apartment", "piso": "Apartment", "flat": "Apartment",
        "moradia": "House", "casa": "House", "villa": "House", "vivenda": "House",
        "terreno": "Land", "lote": "Land",
        "escritório": "Office", "escritorio": "Office", "loja": "Retail",
        "prédio": "Building", "predio": "Building", "edifício": "Building",
        "hotel": "Hotel", "quinta": "Farm/Rural",
      };
      for (const [key, val] of Object.entries(map)) {
        if (cat.includes(key) || url.includes(key)) return val;
      }
      return "Property";
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "imovirtual",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: title(),
        locationCity:        city(),
        locationCountry:     "Portugal",
        currency:            "EUR",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        propertyType:        propertyType(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Imovirtual injected");
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SPAIN
  // ══════════════════════════════════════════════════════════════════════════

  // ── Idealista Spain ────────────────────────────────────────────────────────
  // Selectors are nearly identical to idealista.pt; differences are bedroom
  // labels (habitaciones / dormitorios vs quartos) and currency detection.

  function initIdealistaEs() {
    // Spanish listings: /inmueble/{id}/ or /obra-nueva/…/
    if (!/\/(inmueble|obra-nueva|edificio)\//i.test(window.location.pathname)) return;

    function price() {
      const raw = trySelect(
        ".info-data-price", "span.info-data-price",
        "[class*='price-box']", "span[class*='price']",
        "[data-testid='price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/(\d[\d.,]*)\s*m[²2]/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function bedrooms() {
      // Spanish: "2 habitaciones" or "2 hab." or "2 dormitorios"
      const hab  = document.body.innerText.match(/(\d+)\s*hab(?:itaciones?)?\.?\b/i);
      if (hab) return parseInt(hab[1], 10);
      const dorm = document.body.innerText.match(/(\d+)\s*dormitorios?\b/i);
      if (dorm) return parseInt(dorm[1], 10);
      return 0;
    }

    function bathrooms() {
      const m = document.body.innerText.match(/(\d+)\s*ba(?:ño)?s?\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function city() {
      return trySelect(
        ".main-info__location", "[class*='location']",
        ".breadcrumb li:last-child", ".detail-info-location"
      );
    }

    function address() {
      const ld = extractJsonLd();
      if (ld?.address?.streetAddress) return ld.address.streetAddress;
      return "";
    }

    function coordinates() {
      const iframes = document.querySelectorAll(
        'iframe[src*="google.com/maps"], iframe[src*="google.es/maps"]'
      );
      for (const f of iframes) {
        const m = f.src.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
        if (m) return { lat: parseFloat(m[1]), lng: parseFloat(m[2]) };
      }
      return coordsFromJsonLd();
    }

    function propertyType() {
      const path = window.location.pathname.toLowerCase();
      const map  = [
        ["piso","Apartment"],["apartamento","Apartment"],["atico","Apartment"],
        ["chalet","House"],["casa","House"],["villa","House"],["bungalow","House"],
        ["terreno","Land"],["solar","Land"],
        ["oficina","Office"],["local","Retail"],["nave","Industrial"],
        ["edificio","Building"],["garaje","Garage"],
      ];
      for (const [es, en] of map) if (path.includes(es)) return en;
      return "Property";
    }

    // Detect country from page (Idealista.com serves ES, IT, PT via different sub-paths)
    function country() {
      const lang = document.documentElement.lang || "";
      if (lang.startsWith("it")) return "Italy";
      if (lang.startsWith("pt")) return "Portugal";
      return "Spain";
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "idealista_es",
        url:                 window.location.href,
        propertyName:        trySelect("h1.main-info__title-main", "h1") || document.title.split(" - ")[0].trim(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     country(),
        currency:            "EUR",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        propertyType:        propertyType(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Idealista.com injected");
  }

  // ── Fotocasa Spain ─────────────────────────────────────────────────────────

  function initFotocasa() {
    // Listing pages: /es/compra-viviendas/... or /en/sale/property/... or /es/alquiler/...
    const path = window.location.pathname;
    if (!/\/(compra-viviendas|alquiler-viviendas|sale\/property|sale\/flat|sale\/house|sale\/land|sale\/garage|sale\/office|sale\/commercial|for-sale)\//i.test(path)
        && !/\/\d{8}$/.test(path)) return;

    function price() {
      const raw = trySelect(
        "[data-testid='price']",
        ".re-DetailHeader-price",
        "[class*='re-DetailHeader'] [class*='price']",
        "[class*='Price'][class*='display']",
        "h2.price", "[class*='price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/(\d+(?:[.,]\d+)?)\s*m[²2]/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function bedrooms() {
      const m = document.body.innerText.match(/(\d+)\s*(?:hab(?:itaciones?)?|dormitorios?)\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function bathrooms() {
      const m = document.body.innerText.match(/(\d+)\s*ba(?:ño)?s?\b/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    function title() {
      return trySelect(
        "h1.re-DetailHeader-propertyTitle",
        ".re-DetailHeader h1",
        "h1[class*='title']",
        "h1"
      ) || document.title.split("|")[0].trim();
    }

    function city() {
      return trySelect(
        ".re-DetailHeader-location",
        "[class*='location']",
        ".re-DetailHeader h2",
        ".breadcrumbs li:last-child a"
      );
    }

    function coordinates() {
      return coordsFromJsonLd() || coordsFromDataAttrs();
    }

    function propertyType() {
      const p = path.toLowerCase();
      const map = [
        ["piso","Apartment"],["apartamento","Apartment"],["flat","Apartment"],["atico","Apartment"],
        ["chalet","House"],["casa","House"],["villa","House"],["house","House"],
        ["terreno","Land"],["solar","Land"],["land","Land"],
        ["oficina","Office"],["office","Office"],["local","Retail"],["commercial","Commercial"],
        ["garage","Garage"],["garaje","Garage"],
      ];
      for (const [k, v] of map) if (p.includes(k)) return v;
      return "Property";
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "fotocasa_es",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: title(),
        locationCity:        city(),
        locationCountry:     "Spain",
        currency:            "EUR",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            bedrooms(),
        bathrooms:           bathrooms(),
        propertyType:        propertyType(),
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Fotocasa.es injected");
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SWEDEN
  // ══════════════════════════════════════════════════════════════════════════

  // ── Hemnet ─────────────────────────────────────────────────────────────────

  function initHemnet() {
    if (!/\/bostad\//i.test(window.location.pathname)) return;

    function price() {
      const raw = trySelect(
        ".property-info__price", "[class*='asking-price']",
        ".qa-asking-price", "[data-testid='asking-price']",
        "[class*='property-price']"
      );
      const cleaned = (raw || "").replace(/\s/g, "").replace(/kr$/i, "");
      return parseNumber(cleaned);
    }

    function area() {
      const m = document.body.innerText.match(/([\d,]+)\s*(?:kvm|m²)/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function rooms() {
      const m = document.body.innerText.match(/(\d+(?:[,.]\d+)?)\s*rum\b/i);
      return m ? parseFloat(m[1].replace(",", ".")) : 0;
    }

    function city() {
      return trySelect(
        ".property-address__area", "[class*='municipality']",
        ".qa-property-municipality", ".breadcrumbs__item:last-child a",
        "[class*='region']"
      );
    }

    function address() {
      const street = trySelect(
        "h1.property-address__street-address", ".qa-property-address",
        ".object-heading", "h1"
      );
      return [street, city()].filter(Boolean).join(", ");
    }

    function coordinates() {
      const scripts = document.querySelectorAll('script[type="application/json"]');
      for (const s of scripts) {
        try {
          const data = JSON.parse(s.textContent);
          if (data?.latitude && data?.longitude)
            return { lat: parseFloat(data.latitude), lng: parseFloat(data.longitude) };
        } catch { /* next */ }
      }
      return coordsFromDataAttrs() || coordsFromJsonLd();
    }

    injectButton(() => {
      const coords    = coordinates();
      const roomCount = rooms();
      return {
        source:              "hemnet",
        url:                 window.location.href,
        propertyName:        trySelect("h1.property-address__street-address", "h1") || document.title.split("|")[0].trim(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "Sweden",
        currency:            "SEK",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            roomCount > 0 ? Math.max(Math.floor(roomCount) - 1, 1) : 0,
        bathrooms:           0,
        rooms:               roomCount,
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Hemnet injected");
  }

  // ── Booli Sweden ──────────────────────────────────────────────────────────

  function initBooli() {
    if (!window.location.pathname.includes("/bostad/")) return;

    function price() {
      const raw = trySelect(
        "[class*='askingPrice']", "[class*='AskingPrice']",
        "[class*='price']", ".hd-price", ".property-price"
      );
      if (raw) {
        const cleaned = raw.replace(/\s/g, "").replace(/kr$/i, "");
        const n = parseNumber(cleaned);
        if (n >= 1000) return n;
      }
      // Body text scan: "3 500 000 kr" (space-separated thousands)
      const m = document.body.innerText.match(/([\d\s]{5,})\s*kr\b/i);
      if (m) {
        const n = parseNumber(m[1].replace(/\s/g, ""));
        if (n >= 100000) return n;
      }
      return priceFromJsonLd();
    }

    function area() {
      const m = document.body.innerText.match(/(\d+(?:[.,]\d+)?)\s*(?:kvm|m²)/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function rooms() {
      const m = document.body.innerText.match(/(\d+(?:[,.]\d+)?)\s*rum\b/i);
      return m ? parseFloat(m[1].replace(",", ".")) : 0;
    }

    function title() {
      return trySelect(
        "h1[class*='Address']", "h1[class*='address']",
        ".property-address", "[class*='street-address']",
        "h1"
      ) || document.title.split("|")[0].trim();
    }

    function city() {
      return trySelect(
        "[class*='Municipality']", "[class*='municipality']",
        "[class*='location']", ".breadcrumb a:last-child"
      );
    }

    function coordinates() {
      const scripts = document.querySelectorAll('script[type="application/json"]');
      for (const s of scripts) {
        try {
          const data = JSON.parse(s.textContent);
          if (data?.latitude && data?.longitude)
            return { lat: parseFloat(data.latitude), lng: parseFloat(data.longitude) };
        } catch { /* next */ }
      }
      return coordsFromJsonLd() || coordsFromDataAttrs();
    }

    injectButton(() => {
      const coords    = coordinates();
      const roomCount = rooms();
      return {
        source:              "booli",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: title(),
        locationCity:        city(),
        locationCountry:     "Sweden",
        currency:            "SEK",
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            roomCount > 0 ? Math.max(Math.floor(roomCount) - 1, 1) : 0,
        bathrooms:           0,
        rooms:               roomCount,
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v5] Booli.se injected");
  }

})();
