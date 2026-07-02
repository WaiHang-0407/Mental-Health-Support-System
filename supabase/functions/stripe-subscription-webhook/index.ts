import { createClient } from "npm:@supabase/supabase-js";

type StripeCheckoutSession = {
  id: string;
  object: string;
  payment_status?: string;
  payment_intent?: string | null;
  subscription?: string | null;
  metadata?: {
    payment_id?: string;
  };
};

const encoder = new TextEncoder();

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const payload = await req.text();
  const signature = req.headers.get("Stripe-Signature");
  const webhookSecret = requiredEnv("STRIPE_WEBHOOK_SECRET");

  if (
    !signature ||
    !(await isValidStripeSignature(payload, signature, webhookSecret))
  ) {
    return jsonResponse({ error: "Invalid Stripe signature" }, 400);
  }

  const event = JSON.parse(payload);
  if (event.type !== "checkout.session.completed") {
    return jsonResponse({ received: true });
  }

  const session = event.data?.object as StripeCheckoutSession;
  const paymentId = session.metadata?.payment_id;
  if (!paymentId) {
    return jsonResponse({ error: "Missing payment_id metadata" }, 400);
  }

  if (session.payment_status !== "paid") {
    return jsonResponse({ received: true, status: session.payment_status });
  }

  const supabase = createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
  );

  const { data: payment, error: paymentError } = await supabase
    .from("subscription_payments")
    .select("patient_id")
    .eq("id", paymentId)
    .single();

  if (paymentError || !payment) {
    console.error("Payment lookup failed", paymentError);
    return jsonResponse({ error: "Payment record not found" }, 404);
  }

  const providerPaymentId = session.subscription ?? session.payment_intent ??
    session.id;

  const { error: updatePaymentError } = await supabase
    .from("subscription_payments")
    .update({
      status: "paid",
      provider_payment_id: providerPaymentId,
      paid_at: new Date().toISOString(),
    })
    .eq("id", paymentId);

  if (updatePaymentError) {
    console.error("Payment update failed", updatePaymentError);
    return jsonResponse({ error: "Unable to update payment" }, 500);
  }

  const expiresAt = new Date();
  expiresAt.setMonth(expiresAt.getMonth() + 1);

  const { error: entitlementError } = await supabase
    .from("subscriptions")
    .upsert({
      patient_id: payment.patient_id,
      is_active: true,
      expires_at: expiresAt.toISOString(),
      updated_at: new Date().toISOString(),
    });

  if (entitlementError) {
    console.error("Entitlement update failed", entitlementError);
    return jsonResponse({ error: "Unable to update entitlement" }, 500);
  }

  return jsonResponse({ received: true });
});

async function isValidStripeSignature(
  payload: string,
  signatureHeader: string,
  secret: string,
) {
  const parts = Object.fromEntries(
    signatureHeader.split(",").map((part) => {
      const [key, value] = part.split("=");
      return [key, value];
    }),
  );

  const timestamp = parts.t;
  const signature = parts.v1;
  if (!timestamp || !signature) return false;

  const signedPayload = `${timestamp}.${payload}`;
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(signedPayload),
  );

  return timingSafeEqual(toHex(digest), signature);
}

function toHex(buffer: ArrayBuffer) {
  return [...new Uint8Array(buffer)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqual(a: string, b: string) {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
