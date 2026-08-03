/**
 * Porteos Importer — content.js (v4.2)
 * Supports Idealista (PT), Zillow (US), Hemnet (SE), RE/MAX Portugal, Casa SAPO (PT).
 * Each site has its own init function; shared utilities live at the top.
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

  function parseNumber(str) {
    return parsePrice(str);
  }

  /** Handles EU thousands (1.350.000 / 1 350 000), US (1,350,000), and decimals. */
  function parsePrice(raw) {
    if (!raw) return 0;
    let s = String(raw).replace(/[^\d.,\s]/g, "").trim();
    if (!s) return 0;

    s = s.replace(/\s/g, "");

    const hasComma = s.includes(",");
    const hasDot = s.includes(".");

    if (hasComma && hasDot) {
      const lastComma = s.lastIndexOf(",");
      const lastDot = s.lastIndexOf(".");
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

  function priceFromJsonLd() {
    const ld = extractJsonLd();
    if (!ld) return 0;
    const items = Array.isArray(ld) ? ld : [ld];
    for (const item of items) {
      if (item?.price) {
        const n = parsePrice(String(item.price));
        if (n >= 1000) return n;
      }
      const offers = item?.offers;
      const offerList = Array.isArray(offers) ? offers : offers ? [offers] : [];
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
        .then((data) => {
          console.log("[Porteos Importer] Success:", data);
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

  if (hostname.includes("idealista.pt")) {
    initIdealista();
  } else if (hostname.includes("zillow.com")) {
    initZillow();
  } else if (hostname.includes("hemnet.se")) {
    initHemnet();
  } else if (hostname.includes("remax.pt")) {
    initRemax();
  } else if (hostname.includes("casa.sapo.pt")) {
    initCasaSapo();
  }

  // ── TASK 1 / 2: Idealista ──────────────────────────────────────────────────

  function initIdealista() {
    if (!/\/imovel\/\d+/i.test(window.location.pathname)) return;

    function title() {
      return trySelect(
        "h1.main-info__title-main",
        "h1[class*='title']",
        ".detail-info-title",
        "h1"
      ) || document.title.split(" - ")[0].trim() || "Unnamed Property";
    }

    function price() {
      const raw = trySelect(
        ".info-data-price",
        "span.info-data-price",
        "[class*='price-box']",
        "[class*='price_box']",
        "span[class*='price']",
        "[data-testid='price']",
        ".price-container .price",
        ".main-info__title ~ .info-data .info-data-price"
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
        ".main-info__location",
        "[class*='location']",
        ".breadcrumb li:last-child",
        ".detail-info-location"
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
      const ld = extractJsonLd();
      if (ld?.geo?.latitude)
        return { lat: parseFloat(ld.geo.latitude), lng: parseFloat(ld.geo.longitude) };
      return null;
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "idealista",
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
        bathrooms:           0,
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v4] Idealista button injected");
  }

  // ── TASK 3: Zillow ─────────────────────────────────────────────────────────

  function initZillow() {
    if (!/\/homedetails\//i.test(window.location.pathname)) return;

    function title() {
      return trySelect(
        "h1[data-testid='home-details-chip-title']",
        "[data-testid='bdp-building-name']",
        "h1[class*='summary']",
        ".ds-address-container h1",
        "h1"
      ) || document.title.split("|")[0].trim();
    }

    function price() {
      const raw = trySelect(
        "[data-testid='price']",
        "span[data-testid='price-details']",
        ".ds-summary-row span[class*='Price']",
        "[class*='Text-c11n'][class*='price']",
        "span[class*='zsg-photo-card-price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;
      return priceFromJsonLd();
    }

    function area() {
      // Zillow displays sqft; divide by 10.764 to get m²
      const m = document.body.innerText.match(/([\d,]+)\s*(?:sq\.?\s*ft\.?|sqft)/i);
      if (m) {
        const sqft = parseFloat(m[1].replace(/,/g, ""));
        return Math.round(sqft / 10.764);
      }
      return 0;
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
      // Zillow address chip: "123 Main St, Portland, OR 97201"
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
      return trySelect(
        "h1[data-testid='home-details-chip-title']",
        ".ds-address-container h1",
        "h1"
      );
    }

    function coordinates() {
      // Zillow embeds data in __NEXT_DATA__
      const nd = document.getElementById("__NEXT_DATA__");
      if (nd) {
        try {
          const data = JSON.parse(nd.textContent);
          const props = data?.props?.pageProps;
          const lat = props?.componentProps?.latitude
                   || props?.initialReduxState?.gdpClientCache
                      ?.[Object.keys(props?.initialReduxState?.gdpClientCache || {})[0]]
                      ?.property?.latitude;
          const lng = props?.componentProps?.longitude
                   || props?.initialReduxState?.gdpClientCache
                      ?.[Object.keys(props?.initialReduxState?.gdpClientCache || {})[0]]
                      ?.property?.longitude;
          if (lat && lng) return { lat: parseFloat(lat), lng: parseFloat(lng) };
        } catch { /* continue */ }
      }
      const latMeta = document.querySelector('meta[property="place:location:latitude"]');
      const lngMeta = document.querySelector('meta[property="place:location:longitude"]');
      if (latMeta && lngMeta)
        return { lat: parseFloat(latMeta.content), lng: parseFloat(lngMeta.content) };
      return null;
    }

    injectButton(() => {
      const coords = coordinates();
      return {
        source:              "zillow",
        url:                 window.location.href,
        propertyName:        title(),
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

    console.log("[Porteos Importer v4] Zillow button injected");
  }

  // ── TASK 4: Hemnet ─────────────────────────────────────────────────────────

  function initHemnet() {
    if (!/\/bostad\//i.test(window.location.pathname)) return;

    function title() {
      return trySelect(
        "h1.property-address__street-address",
        "h1[class*='address']",
        ".object-heading",
        ".qa-property-address",
        "h1"
      ) || document.title.split("|")[0].trim();
    }

    function price() {
      // Hemnet: "5 500 000 kr" — spaces as thousands separator
      const raw = trySelect(
        ".property-info__price",
        "[class*='asking-price']",
        ".qa-asking-price",
        "[data-testid='asking-price']",
        "[class*='property-price']"
      );
      // Remove all whitespace and the "kr" suffix, then parse
      const cleaned = (raw || "").replace(/\s/g, "").replace(/kr$/i, "");
      return parseNumber(cleaned);
    }

    function area() {
      // Hemnet uses "kvm" or "m²"
      const m = document.body.innerText.match(/([\d,]+)\s*(?:kvm|m²)/i);
      return m ? parseFloat(m[1].replace(",", ".")) || 0 : 0;
    }

    function rooms() {
      // Swedish: "X rum" (total rooms, not bedrooms)
      const m = document.body.innerText.match(/(\d+(?:[,.]\d+)?)\s*rum\b/i);
      return m ? parseFloat(m[1].replace(",", ".")) : 0;
    }

    function city() {
      return trySelect(
        ".property-address__area",
        "[class*='municipality']",
        ".qa-property-municipality",
        ".breadcrumbs__item:last-child a",
        "[class*='region']"
      );
    }

    function address() {
      const street = trySelect(
        "h1.property-address__street-address",
        ".qa-property-address",
        ".object-heading",
        "h1"
      );
      const area = city();
      return [street, area].filter(Boolean).join(", ");
    }

    function coordinates() {
      // Hemnet often embeds coords in <script type="application/json"> blocks
      const scripts = document.querySelectorAll('script[type="application/json"]');
      for (const s of scripts) {
        try {
          const data = JSON.parse(s.textContent);
          if (data?.latitude && data?.longitude)
            return { lat: parseFloat(data.latitude), lng: parseFloat(data.longitude) };
        } catch { /* next */ }
      }
      // Fallback: map container data attributes
      const mapEl = document.querySelector("[data-latitude][data-longitude]");
      if (mapEl)
        return {
          lat: parseFloat(mapEl.dataset.latitude),
          lng: parseFloat(mapEl.dataset.longitude),
        };
      // Final fallback: JSON-LD geo
      const ld = extractJsonLd();
      if (ld?.geo?.latitude)
        return { lat: parseFloat(ld.geo.latitude), lng: parseFloat(ld.geo.longitude) };
      return null;
    }

    injectButton(() => {
      const coords      = coordinates();
      const roomCount   = rooms();
      return {
        source:              "hemnet",
        url:                 window.location.href,
        propertyName:        title(),
        locationFullAddress: address(),
        locationCity:        city(),
        locationCountry:     "Sweden",
        currency:            "SEK",    // raw — server can convert
        latitude:            coords?.lat || null,
        longitude:           coords?.lng || null,
        purchasePrice:       price(),
        totalArea:           area(),
        bedrooms:            roomCount > 0 ? Math.max(Math.floor(roomCount) - 1, 1) : 0,
        bathrooms:           0,
        rooms:               roomCount,  // pass raw room count separately
        description:         document.querySelector("meta[name='description']")?.content || "",
      };
    });

    console.log("[Porteos Importer v4] Hemnet button injected");
  }

  // ── RE/MAX Portugal ────────────────────────────────────────────────────────
  // URL pattern: /pt/imoveis/venda-{type}-t{n}-{city}-{area}/{id}
  // Price format: "385 000 €" (space thousands, dot decimals)

  function initRemax() {
    const path = window.location.pathname;
    // Only fire on individual listing pages (contain /imoveis/ and /venda- or /arrendar-)
    if (!path.includes("/imoveis/")) return;
    if (!path.includes("/venda-") && !path.includes("/arrendar-")) return;

    // ── URL slug helpers ──────────────────────────────────────────────────
    // Extract from slug like "venda-apartamento-t2-lisboa-estrela"
    function slugParts() {
      const slug = path.split("/").find((p) => p.startsWith("venda-") || p.startsWith("arrendar-")) || "";
      return slug.split("-");
    }

    function typeFromSlug() {
      const parts = slugParts();
      const idx = parts.findIndex((p) => p === "venda" || p === "arrendar");
      const type = parts[idx + 1] || "";
      const map = {
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
      // "t2", "t3" etc in the slug
      const parts = slugParts();
      const tx = parts.find((p) => /^t\d+$/i.test(p));
      return tx ? parseInt(tx.slice(1), 10) : 0;
    }

    function cityFromSlug() {
      // Slug: venda-apartamento-t2-{city}-{area} → word after the T-type
      const parts = slugParts();
      const txIdx = parts.findIndex((p) => /^t\d+$/i.test(p));
      if (txIdx >= 0 && parts[txIdx + 1]) {
        return parts[txIdx + 1].charAt(0).toUpperCase() + parts[txIdx + 1].slice(1);
      }
      return "";
    }

    // ── Price ────────────────────────────────────────────────────────────
    function price() {
      // Try DOM selectors (remax.pt uses various class names)
      const raw = trySelect(
        "h2 span",
        "[class*='listing-price']",
        "[class*='listingPrice']",
        "[class*='price']",
        "#listing-price",
        "strong[class*='price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;

      // Try JSON-LD
      const fromLd = priceFromJsonLd();
      if (fromLd >= 1000) return fromLd;

      // Regex on visible text: "385 000 €" or "1 298 000 €"
      const bodyText = document.body.innerText;
      // Match price with space-thousands and € symbol
      const euroMatch = bodyText.match(/([\d][\d\s.]*\d)\s*€/);
      if (euroMatch) {
        const n = parsePrice(euroMatch[1]);
        if (n >= 1000) return n;
      }
      return 0;
    }

    // ── Area ─────────────────────────────────────────────────────────────
    function area() {
      // "Área Bruta Privativa m² 98" or "98 m²" in page text
      const bodyText = document.body.innerText;
      // Prefer "Área Bruta Privativa" (legal gross area)
      const brutaMatch = bodyText.match(/[Áá]rea Bruta[^0-9]*(\d+)/i);
      if (brutaMatch) return parseFloat(brutaMatch[1]) || 0;
      // Fallback: first m² figure
      const mMatch = bodyText.match(/(\d+(?:[,.]\d+)?)\s*m[²2]/i);
      return mMatch ? parseFloat(mMatch[1].replace(",", ".")) || 0 : 0;
    }

    // ── Bedrooms ─────────────────────────────────────────────────────────
    function bedrooms() {
      // Primary: slug (most reliable on remax.pt)
      const fromSlug = bedroomsFromSlug();
      if (fromSlug > 0) return fromSlug;
      // Fallback: "Quartos 2" or "T2" in text
      const bodyText = document.body.innerText;
      const quartosMatch = bodyText.match(/Quartos\s*(\d+)/i);
      if (quartosMatch) return parseInt(quartosMatch[1], 10);
      const tMatch = bodyText.match(/\bT(\d)\b/);
      return tMatch ? parseInt(tMatch[1], 10) : 0;
    }

    // ── Bathrooms ────────────────────────────────────────────────────────
    function bathrooms() {
      const bodyText = document.body.innerText;
      const match = bodyText.match(/(?:WC|casas? de banho|Wc\/Casas de banho)\s*[:/]?\s*(\d+)/i);
      return match ? parseInt(match[1], 10) : 0;
    }

    // ── City / Address ───────────────────────────────────────────────────
    function city() {
      const fromSlug = cityFromSlug();
      if (fromSlug) return fromSlug;
      return trySelect(
        "h1 span",
        "[class*='location']",
        "[class*='address']",
        "h5.listing-address",
        ".breadcrumb li:last-child"
      );
    }

    function address() {
      // JSON-LD first
      const ld = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        const addr = item?.address;
        if (addr?.streetAddress) return addr.streetAddress;
        if (typeof addr === "string" && addr.length > 3) return addr;
      }
      // h1 often contains "Apartamento T2 à venda em Estrela, Lisboa"
      const h1 = document.querySelector("h1");
      if (h1) {
        const text = h1.textContent.trim();
        // Extract "em {location}" from h1
        const emMatch = text.match(/\bem\s+(.+)$/i);
        if (emMatch) return emMatch[1].trim();
      }
      return "";
    }

    // ── Coordinates ──────────────────────────────────────────────────────
    function coordinates() {
      // JSON-LD geo
      const ld = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        if (item?.geo?.latitude)
          return { lat: parseFloat(item.geo.latitude), lng: parseFloat(item.geo.longitude) };
      }
      // __NEXT_DATA__ (remax.pt uses Next.js)
      const nd = document.getElementById("__NEXT_DATA__");
      if (nd) {
        try {
          const data = JSON.parse(nd.textContent);
          // Walk known paths
          const props = data?.props?.pageProps;
          const listing = props?.listing || props?.property || props?.data;
          if (listing?.latitude && listing?.longitude)
            return { lat: parseFloat(listing.latitude), lng: parseFloat(listing.longitude) };
          if (listing?.coordinates?.latitude)
            return {
              lat: parseFloat(listing.coordinates.latitude),
              lng: parseFloat(listing.coordinates.longitude),
            };
        } catch { /* continue */ }
      }
      // data attributes on map container
      const mapEl = document.querySelector("[data-lat][data-lng], [data-latitude][data-longitude]");
      if (mapEl) {
        const lat = mapEl.dataset.lat || mapEl.dataset.latitude;
        const lng = mapEl.dataset.lng || mapEl.dataset.longitude;
        if (lat && lng) return { lat: parseFloat(lat), lng: parseFloat(lng) };
      }
      // Google Maps iframe
      const iframe = document.querySelector('iframe[src*="google.com/maps"], iframe[src*="google.pt/maps"]');
      if (iframe) {
        const m = iframe.src.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/);
        if (m) return { lat: parseFloat(m[1]), lng: parseFloat(m[2]) };
        const q = iframe.src.match(/[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)/);
        if (q) return { lat: parseFloat(q[1]), lng: parseFloat(q[2]) };
      }
      return null;
    }

    // ── Title ────────────────────────────────────────────────────────────
    function title() {
      const h1 = trySelect("h1", "[class*='listing-title']", "#listing-title");
      if (h1 && h1.length > 3) return h1.replace(/\s+/g, " ").trim();
      // Fallback: compose from type + city
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

    console.log("[Porteos Importer v4.1] RE/MAX Portugal button injected");
  }

  // ── Casa SAPO Portugal ─────────────────────────────────────────────────────
  // URL pattern: /imovel/{id}/ or /comprar|arrendar/{type}/{location}/{id}/
  // SAPO group Next.js app — coordinates and structured data in __NEXT_DATA__.

  function initCasaSapo() {
    const path = window.location.pathname;
    // Only fire on individual listing pages
    if (!path.includes("/imovel/") &&
        !path.includes("/comprar/") &&
        !path.includes("/arrendar/") &&
        !path.includes("/venda/")) return;
    // Skip index/search pages (no numeric/alpha ID segment at end)
    if (path.split("/").filter(Boolean).length < 2) return;

    // ── __NEXT_DATA__ extraction (most reliable on SAPO) ─────────────────
    function getNextData() {
      const el = document.getElementById("__NEXT_DATA__");
      if (!el) return null;
      try { return JSON.parse(el.textContent); } catch { return null; }
    }

    function getListing() {
      const nd = getNextData();
      if (!nd) return null;
      const props = nd?.props?.pageProps;
      // SAPO nests listing data under various keys depending on page type
      return props?.listing
          || props?.property
          || props?.data?.listing
          || props?.data?.property
          || props?.pageData?.listing
          || null;
    }

    // ── Price ─────────────────────────────────────────────────────────────
    function price() {
      const listing = getListing();
      if (listing?.price || listing?.Price) {
        const n = parsePrice(String(listing.price || listing.Price));
        if (n >= 1000) return n;
      }
      // DOM selectors — SAPO uses dynamic class names so cast a wide net
      const raw = trySelect(
        "[class*='listing-price']",
        "[class*='price-value']",
        "[class*='PropertyPrice']",
        "[data-testid='listing-price']",
        "[class*='asking-price']",
        "h2 span",
        "[class*='price']"
      );
      const fromDom = parsePrice(raw);
      if (fromDom >= 1000) return fromDom;

      // JSON-LD
      const fromLd = priceFromJsonLd();
      if (fromLd >= 1000) return fromLd;

      // Body text regex: "250 000 €" or "€ 250.000"
      const m = document.body.innerText.match(/([\d][\d\s.]*\d)\s*€/)
             || document.body.innerText.match(/€\s*([\d][\d\s.]*\d)/);
      return m ? parsePrice(m[1]) : 0;
    }

    // ── Area ──────────────────────────────────────────────────────────────
    function area() {
      const listing = getListing();
      const fromData = listing?.grossArea || listing?.usableArea || listing?.area
                    || listing?.GrossArea || listing?.UsableArea;
      if (fromData > 0) return parseFloat(fromData);

      // Prefer "Área Bruta" from page text
      const bodyText = document.body.innerText;
      const brutaMatch = bodyText.match(/[Áá]rea\s+[Bb]ruta[^0-9]*(\d+)/);
      if (brutaMatch) return parseFloat(brutaMatch[1]) || 0;
      const mMatch = bodyText.match(/(\d+(?:[,.]\d+)?)\s*m[²2]/);
      return mMatch ? parseFloat(mMatch[1].replace(",", ".")) || 0 : 0;
    }

    // ── Land area ─────────────────────────────────────────────────────────
    function landArea() {
      const listing = getListing();
      const fromData = listing?.landArea || listing?.plotArea || listing?.LandArea;
      if (fromData > 0) return parseFloat(fromData);
      const m = document.body.innerText.match(/[Áá]rea\s+(?:de\s+)?[Tt]erreno[^0-9]*(\d+)/);
      return m ? parseFloat(m[1]) || 0 : 0;
    }

    // ── Bedrooms ──────────────────────────────────────────────────────────
    function bedrooms() {
      const listing = getListing();
      const fromData = listing?.bedrooms || listing?.rooms || listing?.Bedrooms || listing?.Rooms;
      if (fromData > 0) return parseInt(fromData, 10);

      // Portuguese Tx convention
      const bodyText = document.body.innerText;
      const tMatch = bodyText.match(/\bT(\d)\b/);
      if (tMatch) return parseInt(tMatch[1], 10);
      const quartosMatch = bodyText.match(/[Qq]uartos?\s*[:\-]?\s*(\d+)/);
      return quartosMatch ? parseInt(quartosMatch[1], 10) : 0;
    }

    // ── Bathrooms ─────────────────────────────────────────────────────────
    function bathrooms() {
      const listing = getListing();
      const fromData = listing?.bathrooms || listing?.Bathrooms;
      if (fromData > 0) return parseInt(fromData, 10);
      const m = document.body.innerText.match(/(?:WC|casas?\s+de\s+banho)[^0-9]*(\d+)/i);
      return m ? parseInt(m[1], 10) : 0;
    }

    // ── Property type ─────────────────────────────────────────────────────
    function propertyType() {
      const listing = getListing();
      const raw = listing?.type || listing?.typology || listing?.Type || "";
      const map = {
        "Apartamento": "Apartment", "T0": "Studio", "T1": "Apartment",
        "T2": "Apartment", "T3": "Apartment", "T4": "Apartment",
        "Moradia": "House", "Vivenda": "House", "Villa": "House",
        "Quinta": "Farm/Rural", "Herdade": "Farm/Rural",
        "Terreno": "Land", "Lote": "Land",
        "Escritório": "Office", "Loja": "Retail",
        "Hotel": "Hotel", "Hostel": "Hotel",
        "Armazém": "Warehouse", "Indústria": "Industrial",
        "Prédio": "Building", "Edifício": "Building",
      };
      for (const [pt, en] of Object.entries(map)) {
        if (raw.includes(pt)) return en;
      }
      // Infer from URL path
      const pathParts = path.split("/").map((p) => p.toLowerCase());
      if (pathParts.some((p) => p.includes("moradia") || p.includes("vivenda"))) return "House";
      if (pathParts.some((p) => p.includes("quinta") || p.includes("herdade"))) return "Farm/Rural";
      if (pathParts.some((p) => p.includes("terreno"))) return "Land";
      if (pathParts.some((p) => p.includes("hotel"))) return "Hotel";
      if (pathParts.some((p) => p.includes("apartamento"))) return "Apartment";
      return raw || "Property";
    }

    // ── Location ──────────────────────────────────────────────────────────
    function city() {
      const listing = getListing();
      // SAPO often has district/county/parish hierarchy
      const fromData = listing?.county || listing?.location?.county
                    || listing?.district || listing?.location?.district
                    || listing?.parish || listing?.location?.parish;
      if (fromData) return fromData;

      return trySelect(
        "[class*='location']",
        "[class*='address']",
        ".breadcrumb li:last-child a",
        "[class*='breadcrumb'] li:last-child",
        "[data-testid='listing-location']"
      ) || "";
    }

    function address() {
      const ld = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        const addr = item?.address;
        if (addr?.streetAddress) return addr.streetAddress;
        if (typeof addr === "string" && addr.length > 3) return addr;
      }
      const listing = getListing();
      return listing?.address?.street || listing?.street || listing?.fullAddress || "";
    }

    // ── Coordinates ───────────────────────────────────────────────────────
    function coordinates() {
      // __NEXT_DATA__ (most reliable for SAPO)
      const listing = getListing();
      if (listing?.latitude && listing?.longitude)
        return { lat: parseFloat(listing.latitude), lng: parseFloat(listing.longitude) };
      if (listing?.location?.latitude && listing?.location?.longitude)
        return { lat: parseFloat(listing.location.latitude), lng: parseFloat(listing.location.longitude) };
      if (listing?.coordinates?.lat)
        return { lat: parseFloat(listing.coordinates.lat), lng: parseFloat(listing.coordinates.lng) };

      // JSON-LD geo
      const ld = extractJsonLd();
      const ldArr = Array.isArray(ld) ? ld : ld ? [ld] : [];
      for (const item of ldArr) {
        if (item?.geo?.latitude)
          return { lat: parseFloat(item.geo.latitude), lng: parseFloat(item.geo.longitude) };
      }

      // Meta tags
      const latMeta = document.querySelector('meta[property="place:location:latitude"]');
      const lngMeta = document.querySelector('meta[property="place:location:longitude"]');
      if (latMeta && lngMeta)
        return { lat: parseFloat(latMeta.content), lng: parseFloat(lngMeta.content) };

      // Map container data attributes
      const mapEl = document.querySelector("[data-lat][data-lng],[data-latitude][data-longitude]");
      if (mapEl) {
        const lat = mapEl.dataset.lat || mapEl.dataset.latitude;
        const lng = mapEl.dataset.lng || mapEl.dataset.longitude;
        if (lat && lng) return { lat: parseFloat(lat), lng: parseFloat(lng) };
      }

      return null;
    }

    // ── Title ─────────────────────────────────────────────────────────────
    function title() {
      const h1 = trySelect("h1", "[class*='listing-title']", "[class*='property-title']");
      if (h1 && h1.length > 3) return h1.replace(/\s+/g, " ").trim();
      const t = propertyType();
      const c = city();
      return c ? `${t} em ${c}` : t || document.title.split("|")[0].trim();
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

    console.log("[Porteos Importer v4.2] Casa SAPO button injected");
  }

})();
