const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type AffirmationOption = {
  id: string;
  text: string;
};

type LocationContext = {
  latitude?: number;
  longitude?: number;
};

type WeatherContext = {
  code?: number;
  category?: string;
  temperature?: number;
};

const model = "gemini-2.5-flash";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "Missing GEMINI_API_KEY secret" }, 500);
  }

  try {
    const body = await req.json();
    const affirmations = parseAffirmations(body.affirmations);

    if (affirmations.length === 0) {
      return jsonResponse({ error: "Affirmations are required" }, 400);
    }

    const prompt = buildPrompt(
      affirmations,
      parseLocation(body.location),
      parseWeather(body.weather),
    );

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
        }),
      },
    );

    const data = await response.json();

    if (!response.ok) {
      console.error(
        "Gemini affirmation error",
        response.status,
        JSON.stringify(data),
      );
      return jsonResponse(
        { error: data?.error?.message ?? "Gemini request failed" },
        response.status,
      );
    }

    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string" || text.trim().length === 0) {
      return jsonResponse({ error: "Gemini returned an empty choice" }, 502);
    }

    const parsed = JSON.parse(extractJson(text));
    const affirmationId = typeof parsed.affirmationId === "string"
      ? parsed.affirmationId.trim()
      : "";
    const selected = affirmations.find((item) => item.id === affirmationId);

    if (!selected) {
      return jsonResponse(
        { error: "Gemini selected an invalid affirmation" },
        502,
      );
    }

    return jsonResponse({ affirmationId: selected.id });
  } catch (error) {
    console.error("Affirmation function error", error);
    return jsonResponse({ error: "Unexpected server error" }, 500);
  }
});

function parseAffirmations(value: unknown): AffirmationOption[] {
  if (!Array.isArray(value)) return [];

  return value
    .map((item) => {
      if (!item || typeof item !== "object") return null;

      const candidate = item as Record<string, unknown>;
      const id = typeof candidate.id === "string" ? candidate.id.trim() : "";
      const text = typeof candidate.text === "string"
        ? candidate.text.trim()
        : "";

      if (!id || !text) return null;
      return { id, text };
    })
    .filter((item): item is AffirmationOption => item !== null)
    .slice(0, 100);
}

function parseLocation(value: unknown): LocationContext | null {
  if (!value || typeof value !== "object") return null;

  const candidate = value as Record<string, unknown>;
  return {
    latitude: numberOrUndefined(candidate.latitude),
    longitude: numberOrUndefined(candidate.longitude),
  };
}

function parseWeather(value: unknown): WeatherContext | null {
  if (!value || typeof value !== "object") return null;

  const candidate = value as Record<string, unknown>;
  return {
    code: numberOrUndefined(candidate.code),
    category: typeof candidate.category === "string"
      ? candidate.category
      : undefined,
    temperature: numberOrUndefined(candidate.temperature),
  };
}

function numberOrUndefined(value: unknown) {
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

function buildPrompt(
  affirmations: AffirmationOption[],
  location: LocationContext | null,
  weather: WeatherContext | null,
) {
  const locationText = location
    ? `latitude ${location.latitude ?? "unknown"}, longitude ${
      location.longitude ?? "unknown"
    }`
    : "location unavailable";
  const weatherText = weather
    ? `category ${weather.category ?? "unknown"}, weather code ${
      weather.code ?? "unknown"
    }, temperature ${weather.temperature ?? "unknown"} Celsius`
    : "weather unavailable";
  const options = affirmations
    .map((item) => `- id: ${item.id}\n  text: ${JSON.stringify(item.text)}`)
    .join("\n");

  return `
You choose one affirmation for a mental health app home page.

Use the user's current location and weather context to choose the most suitable affirmation from the provided list.
Choose exactly one existing id. Do not rewrite or create an affirmation.
Prefer a calming, supportive choice for gloomy, rainy, stormy, or very hot weather.
Prefer an energizing or grateful choice for clear or pleasant weather.
If weather is unavailable, choose the most broadly supportive affirmation.

User context:
- Location: ${locationText}
- Weather: ${weatherText}

Affirmation options:
${options}

Return ONLY valid JSON in this exact shape:
{
  "affirmationId": "existing-id"
}
`;
}

function extractJson(text: string) {
  const cleaned = text.replaceAll("```json", "").replaceAll("```", "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");

  if (start === -1 || end === -1 || end <= start) {
    throw new Error("No JSON object found in Gemini response");
  }

  return cleaned.substring(start, end + 1);
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
