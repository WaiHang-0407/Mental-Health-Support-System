const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const model = "gemini-2.5-flash";
const allowedEmotions = new Set([
  "Happy",
  "Sad",
  "Anxious",
  "Angry",
  "Stressed",
  "Lonely",
  "Fearful",
  "Excited",
  "Calm",
  "Neutral",
]);

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
    const journalText = typeof body.journalText === "string"
      ? body.journalText.trim()
      : "";

    if (!journalText) {
      return jsonResponse({ error: "Journal text is required" }, 400);
    }

    const prompt = `
You are an emotion analysis assistant.

Analyze the following journal entry.

Return ONLY valid JSON.
Do not include markdown.
Do not include explanation.

The JSON format MUST be exactly:

{
  "emotion": "Happy"
}

Choose ONLY ONE emotion from this list:
Happy, Sad, Anxious, Angry, Stressed, Lonely, Fearful, Excited, Calm, Neutral

Journal Entry:
${journalText}
`;

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
        "Gemini emotion error",
        response.status,
        JSON.stringify(data),
      );
      return jsonResponse(
        { error: data?.error?.message ?? "Gemini request failed" },
        response.status,
      );
    }

    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string" || text.trim().isEmpty) {
      return jsonResponse({ emotion: "Unknown" });
    }

    const parsed = JSON.parse(extractJson(text));
    const emotion = typeof parsed.emotion === "string"
      ? parsed.emotion.trim()
      : "";

    return jsonResponse({
      emotion: allowedEmotions.has(emotion) ? emotion : "Unknown",
    });
  } catch (error) {
    console.error("Emotion function error", error);
    return jsonResponse({ emotion: "Unknown" });
  }
});

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
