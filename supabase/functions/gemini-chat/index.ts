const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ChatHistoryItem = {
  role?: string;
  content?: string;
};

const model = "gemini-2.5-flash";

function systemPrompt(animal: string) {
  return `
You are Mindly, a warm mental health companion who presents as a friendly ${animal}.
Occasionally reference being a ${animal} naturally (e.g. "As your ${animal} friend, I...").
Your role:
- Listen actively and respond with empathy
- Provide emotional support and coping strategies
- Encourage professional help when needed
- Never diagnose or prescribe medication
- Keep responses concise and conversational (2-4 sentences)
- If the user seems in crisis, recommend professional help or a hotline
- If the user sends an image, acknowledge it warmly and ask about it
`;
}

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
    const animal = typeof body.animal === "string" ? body.animal : "dog";
    const newMessage = typeof body.newMessage === "string"
      ? body.newMessage.trim()
      : "";
    const history = Array.isArray(body.history)
      ? body.history as ChatHistoryItem[]
      : [];

    if (!newMessage) {
      return jsonResponse({ error: "Message is required" }, 400);
    }

    const contents = [
      {
        role: "user",
        parts: [{ text: systemPrompt(animal) }],
      },
      {
        role: "model",
        parts: [
          {
            text:
              `Hi! I'm your Mindly ${animal} friend. How are you feeling today?`,
          },
        ],
      },
      ...history
        .filter((msg) => msg.content)
        .map((msg) => ({
          role: msg.role === "user" ? "user" : "model",
          parts: [{ text: msg.content }],
        })),
      {
        role: "user",
        parts: [{ text: newMessage }],
      },
    ];

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ contents }),
      },
    );

    const data = await response.json();

    if (!response.ok) {
      console.error("Gemini error", response.status, JSON.stringify(data));
      return jsonResponse(
        { error: data?.error?.message ?? "Gemini request failed" },
        response.status,
      );
    }

    const reply = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof reply !== "string" || reply.trim().isEmpty) {
      return jsonResponse({ error: "Gemini returned an empty reply" }, 502);
    }

    return jsonResponse({ reply });
  } catch (error) {
    console.error("Function error", error);
    return jsonResponse({ error: "Unexpected server error" }, 500);
  }
});

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
